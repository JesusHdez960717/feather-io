import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mime/mime.dart';
import 'package:service/feather.dart';

class S3Controller {
  final FileManagementService fileManagement;
  final BucketService bucketService;
  final MultipartService multipart;

  Route get routing {
    return Route.parent(
      path: '/',
      filterConfig: FilterConfig([
        S3BucketNameFilter(),
        UnsupportedSubresourceFilter(),
        JwtFilter(),
        S3SigV4Filter(),
        AnonymousAccessFilter(),
      ]),
      routes: [
        Route.get(
          key: 's3.list-buckets',
          path: '/',
          handler: listBuckets,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.list-buckets')),
          ]),
        ),
        Route.put(
          key: 's3.create-bucket',
          path: '/{bucket}',
          handler: createBucket,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.create-bucket')),
            ReservedBucketFilter(),
          ]),
        ),
        Route.delete(
          key: 's3.delete-bucket',
          path: '/{bucket}',
          handler: deleteBucket,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.delete-bucket')),
            ReservedBucketFilter(),
          ]),
        ),
        Route.get(
          key: 's3.list-objects',
          path: '/{bucket}',
          handler: listObjects,
          filterConfig: FilterConfig([
            AuthFilter(
              rules:
                  hasPermission('s3.list-objects') |
                  hasPermission('s3.anonymous.list-objects'),
              shouldFilter: (request) {
                //solo aplica este filtro si es esta misma ruta, asi no se hereda para los childs
                //asi el get-object no tiene que tener el permiso del list-objects
                return request.routingContext?.key == 's3.list-objects';
              },
            ),
            ReservedBucketFilter(),
          ]),
          routes: [
            Route.put(
              key: 's3.put-object',
              path: '/{key|.*}',
              handler: putObject,
              filterConfig: FilterConfig([
                AuthFilter(
                  rules:
                      hasPermission('s3.put-object') |
                      hasPermission('s3.anonymous.put-object'),
                ),
              ]),
            ),
            //CreateMultipartUpload (?uploads) y CompleteMultipartUpload (?uploadId)
            Route.post(
              key: 's3.post-object',
              path: '/{key|.*}',
              handler: postObject,
              filterConfig: FilterConfig([
                AuthFilter(rules: hasPermission('s3.put-object')),
              ]),
            ),
            Route.get(
              key: 's3.get-object',
              path: '/{key|.*}',
              handler: getFile,
              filterConfig: FilterConfig([
                AuthFilter(
                  rules:
                      hasPermission('s3.get-object') |
                      hasPermission('s3.anonymous.get-object'),
                ),
              ]),
            ),
            Route.delete(
              key: 's3.delete-object',
              path: '/{key|.*}',
              handler: deleteFile,
              filterConfig: FilterConfig([
                AuthFilter(
                  rules:
                      hasPermission('s3.delete-object') |
                      hasPermission('s3.anonymous.delete-object'),
                ),
              ]),
            ),
          ],
        ),
        Route.post(
          key: 's3.multi-delete-objects',
          path: '/{bucket}',
          handler: multiDelete,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.multi-delete-objects')),
            ReservedBucketFilter(),
          ]),
        ),
      ],
    );
  }

  S3Controller()
    : fileManagement = di.find(),
      bucketService = BucketService(),
      multipart = MultipartService();

  Future<ResponseEntity> listBuckets(RequestEntity request) async {
    final buckets = await bucketService.listBuckets();

    if (_acceptsJson(request)) {
      return ResponseEntity.ok(body: buckets);
    } else {
      final xmlBody = _mapBucketsToXml(buckets);
      return ResponseEntity.ok(
        body: xmlBody,
        headers: {'content-type': 'application/xml'},
      );
    }
  }

  Future<ResponseEntity> createBucket(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    CreateBucketRequest? createRequest;
    try {
      createRequest = await request.body<CreateBucketRequest>();
    } catch (_) {
      // Usamos defaults si el body no es válido o está vacío
      createRequest = null;
    }
    createRequest?.validate().throwOnFailure();

    await bucketService.createBucket(
      bucketName: bucketName,
      description: createRequest?.description,
      color: createRequest?.color,
    );

    //como S3: sin cuerpo y con la ruta del bucket en Location
    return ResponseEntity(200, headers: {'location': '/$bucketName'});
  }

  Future<ResponseEntity> deleteBucket(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    await bucketService.deleteBucket(bucketName: bucketName);

    return ResponseEntity(204);
  }

  Future<ResponseEntity> putObject(RequestEntity request) async {
    final uploadId = request.queryParams['uploadId'];
    if (uploadId != null) return _uploadPart(request, uploadId);

    final copySource = request.headers['x-amz-copy-source'];
    if (copySource != null) return _copyObject(request, copySource);

    final etag = await fileManagement.uploadFile(
      bucketName: request.pathParams['bucket']!,
      key: _objectKey(request),
      binary: _objectBody(request),
      headers: _objectHeaders(request),
    );

    return ResponseEntity(200, headers: {'etag': '"$etag"'});
  }

  /// El contenido de un objeto o de una parte, sin el formato `aws-chunked`
  /// si el cliente lo manda asi
  Stream<List<int>> _objectBody(RequestEntity request) =>
      AwsChunkedDecoder.appliesTo(request)
      ? AwsChunkedDecoder.decode(request.read())
      : request.read();

  /// Cabeceras de la peticion que se guardan con el objeto y se devuelven al
  /// leerlo, como en S3: las de contenido y los metadatos `x-amz-meta-*`.
  /// `aws-chunked` es el formato del envio, no del objeto: no se guarda
  Map<String, String> _objectHeaders(RequestEntity request) {
    final headers = {
      for (final MapEntry(:key, :value) in request.headers.entries)
        if (_storedHeaders.contains(key.toLowerCase()) ||
            key.toLowerCase().startsWith('x-amz-meta-'))
          key.toLowerCase(): value,
    };
    final encoding = headers['content-encoding']
        ?.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'aws-chunked')
        .join(', ');
    if (encoding == null || encoding.isEmpty) {
      headers.remove('content-encoding');
    } else {
      headers['content-encoding'] = encoding;
    }
    return {...headers, 'x-amz-storage-class': ?_storageClass(request)};
  }

  static const Set<String> _storedHeaders = {
    'cache-control',
    'content-disposition',
    'content-encoding',
    'content-language',
    'content-type',
    'expires',
  };

  //x-amz-storage-class no esta en [_storedHeaders]: se valida y se añade
  //aparte, y la normal (STANDARD) no se guarda

  /// La key del objeto. El parametro de ruta pierde la `/` final, que es la que
  /// distingue una carpeta (`fotos/`) de un objeto (`fotos`): se recupera de la URL
  String _objectKey(RequestEntity request) {
    final key = request.pathParams['key']!;
    return request.requestedUri.path.endsWith('/') && !key.endsWith('/')
        ? '$key/'
        : key;
  }

  /// CopyObject: `PUT` con `x-amz-copy-source: /bucket/key`. Leer el origen
  /// exige el permiso normal de descarga; una regla anonima no basta
  Future<ResponseEntity> _copyObject(
    RequestEntity request,
    String copySource,
  ) async {
    final bucketName = request.pathParams['bucket']!;
    final (sourceBucket, sourceKey) = _copySource(request, copySource);

    //como S3: copia las cabeceras del origen salvo que se pida REPLACE
    final replace =
        request.headers['x-amz-metadata-directive']?.toUpperCase() == 'REPLACE';
    final copied = await fileManagement.copyFile(
      sourceBucket: sourceBucket,
      sourceKey: sourceKey,
      bucketName: bucketName,
      key: request.pathParams['key']!,
      headers: replace ? _objectHeaders(request) : null,
      storageClass: _storageClass(request),
      conditions: _copyConditions(request),
    );

    if (_acceptsJson(request)) {
      return ResponseEntity.ok(body: copied);
    }
    return ResponseEntity.ok(
      body: _mapCopyResultToXml(copied),
      headers: {'content-type': 'application/xml'},
    );
  }

  /// El objeto de origen de una copia (`x-amz-copy-source`: `/bucket/key` o
  /// `bucket/key`, codificado como URL y quiza con `?versionId`). Leerlo exige
  /// el permiso normal de descarga; una regla anonima no basta
  (String, String) _copySource(RequestEntity request, String copySource) {
    final permissions =
        request.securityContext.authentication?.permissions ?? const {};
    if (!permissions.contains('s3.get-object')) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message:
            'Copiar un objeto requiere permiso de lectura sobre el origen.',
        resource: copySource,
      );
    }

    final source = Uri.decodeComponent(copySource.split('?').first);
    final path = source.startsWith('/') ? source.substring(1) : source;
    final slash = path.indexOf('/');
    if (slash <= 0 || slash == path.length - 1) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: 'x-amz-copy-source debe tener la forma /bucket/key.',
        resource: copySource,
      );
    }
    return (path.substring(0, slash), path.substring(slash + 1));
  }

  /// Las condiciones `x-amz-copy-source-if-*` de una copia. Una fecha que no
  /// se entiende se ignora, como en S3
  CopyConditions _copyConditions(RequestEntity request) {
    DateTime? date(String name) {
      final value = request.headers['x-amz-copy-source-if-$name'];
      if (value == null) return null;
      try {
        return HttpDate.parse(value);
      } catch (_) {
        return null;
      }
    }

    return CopyConditions(
      ifMatch: request.headers['x-amz-copy-source-if-match'],
      ifNoneMatch: request.headers['x-amz-copy-source-if-none-match'],
      ifModifiedSince: date('modified-since'),
      ifUnmodifiedSince: date('unmodified-since'),
    );
  }

  /// Clases de almacenamiento de S3. Todas se guardan igual: solo se recuerda
  /// la que pidio el cliente para devolverla
  static const Set<String> _storageClasses = {
    'STANDARD',
    'REDUCED_REDUNDANCY',
    'STANDARD_IA',
    'ONEZONE_IA',
    'INTELLIGENT_TIERING',
    'GLACIER',
    'GLACIER_IR',
    'DEEP_ARCHIVE',
    'OUTPOSTS',
    'EXPRESS_ONEZONE',
  };

  /// La clase de `x-amz-storage-class`, o null si no viene o es la normal
  /// (`STANDARD`, que S3 no devuelve)
  String? _storageClass(RequestEntity request) {
    final value = request.headers['x-amz-storage-class']?.trim().toUpperCase();
    if (value == null || value.isEmpty || value == 'STANDARD') return null;
    if (!_storageClasses.contains(value)) {
      throw S3Exception(
        S3ErrorCode.invalidStorageClass,
        message: 'La clase de almacenamiento "$value" no es válida.',
        resource: request.requestedUri.path,
      );
    }
    return value;
  }

  /// ListMultipartUploads (`GET /{bucket}?uploads`): las subidas en curso, sin
  /// paginar (como mucho 1000)
  Future<ResponseEntity> _listMultipartUploads(
    RequestEntity request,
    String bucketName,
  ) async {
    _requireUploadPermission(request, bucketName);
    final prefix = request.queryParams['prefix'];
    final uploads = (await multipart.list(
      bucketName: bucketName,
      prefix: prefix,
    )).take(FileManagementService.maxKeysLimit).toList();
    if (_acceptsJson(request)) return ResponseEntity.ok(body: uploads);
    return ResponseEntity.ok(
      body: _mapMultipartUploadsToXml(bucketName, prefix, uploads),
      headers: {'content-type': 'application/xml'},
    );
  }

  Future<ResponseEntity> listObjects(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    if (request.queryParams.containsKey('location')) {
      return _bucketLocation(bucketName);
    }
    if (request.queryParams.containsKey('uploads')) {
      return _listMultipartUploads(request, bucketName);
    }
    if (request.queryParams.containsKey('versioning')) {
      //GetBucketVersioning: el versionado nunca esta activado (sin Status)
      if (!await fileManagement.bucketExists(bucketName)) {
        throw S3Exception.noSuchBucket(bucketName);
      }
      return ResponseEntity.ok(
        body:
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"/>\n',
        headers: {'content-type': 'application/xml'},
      );
    }
    final prefix = request.queryParams['prefix'];
    final delimiter = request.queryParams['delimiter'];
    final maxKeysParam = request.queryParams['max-keys'];
    final maxKeys = maxKeysParam == null
        ? FileManagementService.maxKeysLimit
        : int.tryParse(maxKeysParam);
    if (maxKeys == null) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: 'max-keys debe ser un número entero.',
        resource: maxKeysParam,
      );
    }

    //ListObjectsV2 con list-type=2; si no, V1 (pagina con marker)
    final v2 = request.queryParams['list-type'] == '2';
    final result = await fileManagement.listFiles(
      bucketName: bucketName,
      prefix: prefix,
      delimiter: delimiter,
      maxKeys: maxKeys,
      continuationToken: request.queryParams['continuation-token'],
      startAfter: request.queryParams[v2 ? 'start-after' : 'marker'],
    );

    if (_acceptsJson(request)) {
      return ResponseEntity.ok(body: result);
    } else {
      final xmlBody = _mapListObjectsToXml(
        result,
        v2: v2,
        urlEncoded: request.queryParams['encoding-type'] == 'url',
      );
      return ResponseEntity.ok(
        body: xmlBody,
        headers: {'content-type': 'application/xml'},
      );
    }
  }

  /// GetBucketLocation (`?location`): siempre la region por defecto, que S3
  /// devuelve como un LocationConstraint vacio. Los clientes la piden para
  /// saber con que region firmar
  Future<ResponseEntity> _bucketLocation(String bucketName) async {
    if (!await fileManagement.bucketExists(bucketName)) {
      throw S3Exception.noSuchBucket(bucketName);
    }
    return ResponseEntity.ok(
      body:
          '<?xml version="1.0" encoding="UTF-8"?>\n'
          '<LocationConstraint xmlns="http://s3.amazonaws.com/doc/2006-03-01/"/>\n',
      headers: {'content-type': 'application/xml'},
    );
  }

  Future<ResponseEntity> getFile(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    final key = _objectKey(request);
    final uploadId = request.queryParams['uploadId'];
    if (uploadId != null) return _listParts(request, bucketName, key, uploadId);
    if (request.queryParams.containsKey('tagging')) {
      //GetObjectTagging: el servicio no guarda etiquetas, el objeto no tiene
      await fileManagement.getFile(bucketName: bucketName, key: key);
      return ResponseEntity.ok(
        body:
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<Tagging xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
            '<TagSet></TagSet></Tagging>\n',
        headers: {'content-type': 'application/xml'},
      );
    }

    final file = await fileManagement.getFile(bucketName: bucketName, key: key);
    final stat = await file.stat();
    final meta = await fileManagement.metaOf(
      bucketName: bucketName,
      key: key,
      file: file,
      stat: stat,
    );

    //un HEAD usa esta misma ruta: Winter manda las cabeceras sin el cuerpo.
    //Sin Content-Type guardado, el de la extension
    final headers = {
      'content-type':
          lookupMimeType(file.path) ??
          MediaType.applicationOctetStream.mimeType,
      ...meta.headers,
      'last-modified': HttpDate.format(stat.modified),
      'etag': '"${meta.etag}"',
      'accept-ranges': 'bytes',
    };

    //una peticion firmada puede cambiar las cabeceras de la respuesta con
    //?response-content-type=… (S3 no lo permite a las anonimas)
    final permissions =
        request.securityContext.authentication?.permissions ?? const {};
    if (permissions.contains('s3.get-object')) {
      for (final name in _overridableHeaders) {
        final value = request.queryParams['response-$name'];
        if (value != null) headers[name] = value;
      }
    }

    final range = _requestedRange(request, stat.size, key);
    if (range == null) {
      return ResponseEntity.ok(
        body: file.openRead(),
        headers: {...headers, 'content-length': stat.size.toString()},
      );
    }
    final (start, end) = range;
    return ResponseEntity(
      206,
      body: file.openRead(start, end + 1),
      headers: {
        ...headers,
        'content-length': '${end - start + 1}',
        'content-range': 'bytes $start-$end/${stat.size}',
      },
    );
  }

  static const List<String> _overridableHeaders = [
    'cache-control',
    'content-disposition',
    'content-encoding',
    'content-language',
    'content-type',
    'expires',
  ];

  /// El tramo que pide la cabecera `Range` (`bytes=a-b`, `bytes=a-` o
  /// `bytes=-n`, los ultimos n) como posiciones inclusivas. Null si no hay
  /// cabecera o no se entiende: entonces se sirve entero, como hace S3 (que
  /// tampoco admite varios tramos). Un tramo fuera del objeto es un 416
  (int, int)? _requestedRange(RequestEntity request, int size, String key) {
    final header = request.headers['range'];
    if (header == null) return null;
    final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(header.trim());
    if (match == null) return null;
    final first = int.tryParse(match.group(1)!);
    final last = int.tryParse(match.group(2)!);

    final int start;
    final int end;
    if (first == null) {
      if (last == null) return null;
      start = last == 0 ? size : max(0, size - last);
      end = size - 1;
    } else {
      if (last != null && last < first) return null;
      start = first;
      end = last == null ? size - 1 : min(last, size - 1);
    }
    if (start >= size) {
      throw S3Exception(
        S3ErrorCode.invalidRange,
        message: 'El rango "$header" está fuera del objeto ($size bytes).',
        resource: key,
      );
    }
    return (start, end);
  }

  Future<ResponseEntity> deleteFile(RequestEntity request) async {
    final uploadId = request.queryParams['uploadId'];
    if (uploadId != null) {
      _requireUploadPermission(request, _objectKey(request));
      await multipart.abort(
        bucketName: request.pathParams['bucket']!,
        key: _objectKey(request),
        uploadId: uploadId,
      );
      return ResponseEntity(204);
    }

    await fileManagement.deleteFile(
      bucketName: request.pathParams['bucket']!,
      key: _objectKey(request),
    );

    return ResponseEntity(204);
  }

  /// `POST` sobre un objeto: solo las operaciones de multipart
  Future<ResponseEntity> postObject(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    final key = _objectKey(request);

    if (request.queryParams.containsKey('uploads')) {
      final upload = await multipart.create(
        bucketName: bucketName,
        key: key,
        headers: _objectHeaders(request),
      );
      if (_acceptsJson(request)) return ResponseEntity.ok(body: upload);
      return ResponseEntity.ok(
        body: _mapInitiateMultipartToXml(upload),
        headers: {'content-type': 'application/xml'},
      );
    }

    final uploadId = request.queryParams['uploadId'];
    if (uploadId != null) {
      final parts = await _readCompletedParts(request, key);
      final completed = await multipart.complete(
        bucketName: bucketName,
        key: key,
        uploadId: uploadId,
        parts: parts,
      );
      if (_acceptsJson(request)) return ResponseEntity.ok(body: completed);
      return ResponseEntity.ok(
        body: _mapCompleteMultipartToXml(request, completed),
        headers: {'content-type': 'application/xml'},
      );
    }

    throw S3Exception(
      S3ErrorCode.invalidRequest,
      message: 'POST sobre un objeto solo admite ?uploads o ?uploadId.',
      resource: key,
    );
  }

  /// Multipart nunca es anonimo: exige el permiso de subida normal. Hace falta
  /// en las operaciones que van por rutas que aceptan reglas anonimas (UploadPart
  /// por PUT, AbortMultipartUpload por DELETE, ListParts y ListMultipartUploads
  /// por GET); Create y Complete van por POST, que ya lo exige en su ruta
  void _requireUploadPermission(RequestEntity request, String resource) {
    final permissions =
        request.securityContext.authentication?.permissions ?? const {};
    if (!permissions.contains('s3.put-object')) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: 'Las subidas multipart requieren permiso de subida.',
        resource: resource,
      );
    }
  }

  /// UploadPart: `PUT ?partNumber=N&uploadId=X`. El ETag va en la cabecera
  Future<ResponseEntity> _uploadPart(
    RequestEntity request,
    String uploadId,
  ) async {
    final key = _objectKey(request);
    _requireUploadPermission(request, key);
    final partNumber = int.tryParse(request.queryParams['partNumber'] ?? '');
    if (partNumber == null) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: 'Falta el número de parte (partNumber).',
        resource: key,
      );
    }
    final copySource = request.headers['x-amz-copy-source'];
    if (copySource != null) {
      return _uploadPartCopy(request, key, uploadId, partNumber, copySource);
    }
    final etag = await multipart.uploadPart(
      bucketName: request.pathParams['bucket']!,
      key: key,
      uploadId: uploadId,
      partNumber: partNumber,
      binary: _objectBody(request),
    );
    return ResponseEntity(200, headers: {'etag': '"$etag"'});
  }

  /// ListParts (`GET /{bucket}/{key}?uploadId=`): las partes ya subidas, para
  /// reanudar una subida. Va por la ruta de descarga, pero como el resto de
  /// multipart exige el permiso de subida
  Future<ResponseEntity> _listParts(
    RequestEntity request,
    String bucketName,
    String key,
    String uploadId,
  ) async {
    _requireUploadPermission(request, key);
    final marker =
        int.tryParse(request.queryParams['part-number-marker'] ?? '') ?? 0;
    final maxParts =
        (int.tryParse(request.queryParams['max-parts'] ?? '') ??
                FileManagementService.maxKeysLimit)
            .clamp(0, FileManagementService.maxKeysLimit);

    final pending = (await multipart.listParts(
      bucketName: bucketName,
      key: key,
      uploadId: uploadId,
    )).where((part) => part.partNumber > marker).toList();
    final parts = pending.take(maxParts).toList();
    final isTruncated = pending.length > parts.length;

    if (_acceptsJson(request)) return ResponseEntity.ok(body: parts);
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<ListPartsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    buffer.writeln('  <Bucket>${_escapeXml(bucketName)}</Bucket>');
    buffer.writeln('  <Key>${_escapeXml(key)}</Key>');
    buffer.writeln('  <UploadId>$uploadId</UploadId>');
    for (final role in ['Initiator', 'Owner']) {
      buffer.writeln(
        '  <$role><ID>$_ownerId</ID><DisplayName>$_ownerId</DisplayName></$role>',
      );
    }
    buffer.writeln('  <StorageClass>STANDARD</StorageClass>');
    buffer.writeln('  <PartNumberMarker>$marker</PartNumberMarker>');
    if (parts.isNotEmpty) {
      buffer.writeln(
        '  <NextPartNumberMarker>${parts.last.partNumber}</NextPartNumberMarker>',
      );
    }
    buffer.writeln('  <MaxParts>$maxParts</MaxParts>');
    buffer.writeln('  <IsTruncated>$isTruncated</IsTruncated>');
    for (final part in parts) {
      buffer.writeln('  <Part>');
      buffer.writeln('    <PartNumber>${part.partNumber}</PartNumber>');
      buffer.writeln(
        '    <LastModified>${_s3Date(part.lastModified)}</LastModified>',
      );
      buffer.writeln('    <ETag>&quot;${part.etag}&quot;</ETag>');
      buffer.writeln('    <Size>${part.size}</Size>');
      buffer.writeln('  </Part>');
    }
    buffer.writeln('</ListPartsResult>');
    return ResponseEntity.ok(
      body: buffer.toString(),
      headers: {'content-type': 'application/xml'},
    );
  }

  /// UploadPartCopy: la parte es otro objeto, entero o el tramo de
  /// `x-amz-copy-source-range: bytes=a-b`
  Future<ResponseEntity> _uploadPartCopy(
    RequestEntity request,
    String key,
    String uploadId,
    int partNumber,
    String copySource,
  ) async {
    final (sourceBucket, sourceKey) = _copySource(request, copySource);
    final rangeHeader = request.headers['x-amz-copy-source-range'];
    (int, int)? range;
    if (rangeHeader != null) {
      final match = RegExp(
        r'^bytes=(\d+)-(\d+)$',
      ).firstMatch(rangeHeader.trim());
      if (match == null) {
        throw S3Exception(
          S3ErrorCode.invalidArgument,
          message: 'x-amz-copy-source-range debe tener la forma bytes=a-b.',
          resource: rangeHeader,
        );
      }
      range = (int.parse(match.group(1)!), int.parse(match.group(2)!));
    }

    final source = await fileManagement.readForCopy(
      sourceBucket: sourceBucket,
      sourceKey: sourceKey,
      range: range,
      conditions: _copyConditions(request),
    );
    final etag = await multipart.uploadPart(
      bucketName: request.pathParams['bucket']!,
      key: key,
      uploadId: uploadId,
      partNumber: partNumber,
      binary: source,
    );
    final copied = CopiedPartModel(
      etag: etag,
      lastModified: DateTime.now().toUtc(),
    );

    if (_acceptsJson(request)) return ResponseEntity.ok(body: copied);
    return ResponseEntity.ok(
      body:
          '<?xml version="1.0" encoding="UTF-8"?>\n'
          '<CopyPartResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">\n'
          '  <LastModified>${_s3Date(copied.lastModified)}</LastModified>\n'
          '  <ETag>&quot;${copied.etag}&quot;</ETag>\n'
          '</CopyPartResult>\n',
      headers: {'content-type': 'application/xml'},
    );
  }

  /// Las partes de CompleteMultipartUpload: XML de S3 o JSON (la consola)
  Future<List<CompletedPart>> _readCompletedParts(
    RequestEntity request,
    String key,
  ) async {
    final malformed = S3Exception(
      S3ErrorCode.malformedXML,
      message: 'La lista de partes no es válida.',
      resource: key,
    );
    final body = await utf8.decodeStream(request.read());
    if (request.headers['content-type']?.contains('json') == true) {
      try {
        return CompleteMultipartRequest.fromJson(jsonDecode(body)).parts;
      } catch (_) {
        throw malformed;
      }
    }

    final parts = <CompletedPart>[];
    for (final xml in _xmlTags(body, 'Part')) {
      final number = int.tryParse(_xmlTag(xml, 'PartNumber')?.trim() ?? '');
      if (number == null) throw malformed;
      final etag = _xmlTag(xml, 'ETag')?.trim() ?? '';
      parts.add(CompletedPart(partNumber: number, etag: etag));
    }
    if (parts.isEmpty) throw malformed;
    return parts;
  }

  Future<ResponseEntity> multiDelete(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    if (!request.queryParams.containsKey('delete')) {
      throw S3Exception(
        S3ErrorCode.invalidRequest,
        message: 'Multi-object delete requires ?delete parameter',
        resource: bucketName,
      );
    }

    final body = await utf8.decodeStream(request.read());
    final isJson =
        request.headers['content-type']?.contains('json') == true ||
        body.trimLeft().startsWith('{');
    final deleteRequest = isJson
        ? _readDeleteJson(body, bucketName)
        : _readDeleteXml(body, bucketName);
    if (deleteRequest.keys.length > FileManagementService.maxKeysLimit) {
      throw S3Exception(
        S3ErrorCode.malformedXML,
        message:
            'Como mucho se pueden borrar '
            '${FileManagementService.maxKeysLimit} objetos por petición.',
        resource: bucketName,
      );
    }

    final result = await fileManagement.deleteObjects(
      bucketName: bucketName,
      request: deleteRequest,
    );

    if (_acceptsJson(request)) return ResponseEntity.ok(body: result);
    return ResponseEntity.ok(
      body: _mapDeleteResultToXml(result),
      headers: {'content-type': 'application/xml'},
    );
  }

  /// DeleteObjects en JSON (la consola)
  DeleteObjectsRequest _readDeleteJson(String body, String bucketName) {
    try {
      return DeleteObjectsRequest.fromJson(jsonDecode(body));
    } catch (e) {
      throw S3Exception(
        S3ErrorCode.invalidRequest,
        message: 'Invalid JSON for delete request: $e',
        resource: bucketName,
      );
    }
  }

  /// DeleteObjects en el XML de S3:
  /// `<Delete><Quiet>true</Quiet><Object><Key>k</Key></Object>…</Delete>`
  DeleteObjectsRequest _readDeleteXml(String body, String bucketName) {
    if (_xmlTag(body, 'Delete') == null) {
      throw S3Exception(
        S3ErrorCode.malformedXML,
        message: 'El cuerpo debe ser un <Delete> con los objetos a borrar.',
        resource: bucketName,
      );
    }
    final keys = [
      for (final object in _xmlTags(body, 'Object'))
        if (_xmlTag(object, 'Key') case final key? when key.isNotEmpty) key,
    ];
    return DeleteObjectsRequest(
      keys: keys,
      quiet: _xmlTag(body, 'Quiet')?.trim().toLowerCase() == 'true',
    );
  }

  /// Dueño de todos los buckets en las respuestas de S3
  static const String _ownerId = 'feather-io';

  bool _acceptsJson(RequestEntity request) =>
      request.headers['accept']?.contains('application/json') == true;

  String _mapInitiateMultipartToXml(MultipartUploadModel upload) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<InitiateMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    buffer.writeln('  <Bucket>${_escapeXml(upload.bucket)}</Bucket>');
    buffer.writeln('  <Key>${_escapeXml(upload.key)}</Key>');
    buffer.writeln('  <UploadId>${upload.uploadId}</UploadId>');
    buffer.writeln('</InitiateMultipartUploadResult>');
    return buffer.toString();
  }

  String _mapCompleteMultipartToXml(
    RequestEntity request,
    CompletedMultipartModel completed,
  ) {
    final uri = request.requestedUri;
    final location = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: uri.path,
    ).toString();
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<CompleteMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    buffer.writeln('  <Location>${_escapeXml(location)}</Location>');
    buffer.writeln('  <Bucket>${_escapeXml(completed.bucket)}</Bucket>');
    buffer.writeln('  <Key>${_escapeXml(completed.key)}</Key>');
    buffer.writeln('  <ETag>&quot;${completed.etag}&quot;</ETag>');
    buffer.writeln('</CompleteMultipartUploadResult>');
    return buffer.toString();
  }

  /// Fecha de S3 en el XML: UTC con milisegundos (`2026-10-02T14:22:35.000Z`)
  String _s3Date(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
      utc.millisecond,
    ).toIso8601String();
  }

  /// El contenido de la primera etiqueta [name] de [xml], con las entidades ya
  /// decodificadas, o null si no esta
  String? _xmlTag(String xml, String name) {
    final match = RegExp(
      '<$name(?:\\s[^>]*)?>(.*?)</$name>',
      dotAll: true,
    ).firstMatch(xml);
    return match == null ? null : _unescapeXml(match.group(1)!);
  }

  /// El contenido en bruto de cada etiqueta [name] de [xml]
  Iterable<String> _xmlTags(String xml, String name) => RegExp(
    '<$name(?:\\s[^>]*)?>(.*?)</$name>',
    dotAll: true,
  ).allMatches(xml).map((match) => match.group(1)!);

  /// Decodifica las entidades de XML (`&amp;`, `&quot;`, `&#34;`, `&#x22;`…)
  String _unescapeXml(String value) => value.replaceAllMapped(
    RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos);'),
    (match) {
      final entity = match.group(1)!;
      return switch (entity) {
        'amp' => '&',
        'lt' => '<',
        'gt' => '>',
        'quot' => '"',
        'apos' => "'",
        _ when entity.startsWith('#x') => String.fromCharCode(
          int.parse(entity.substring(2), radix: 16),
        ),
        _ => String.fromCharCode(int.parse(entity.substring(1))),
      };
    },
  );

  String _mapMultipartUploadsToXml(
    String bucketName,
    String? prefix,
    List<MultipartUploadModel> uploads,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<ListMultipartUploadsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    buffer.writeln('  <Bucket>${_escapeXml(bucketName)}</Bucket>');
    buffer.writeln('  <KeyMarker></KeyMarker>');
    buffer.writeln('  <UploadIdMarker></UploadIdMarker>');
    buffer.writeln('  <NextKeyMarker></NextKeyMarker>');
    buffer.writeln('  <NextUploadIdMarker></NextUploadIdMarker>');
    buffer.writeln('  <Prefix>${_escapeXml(prefix ?? '')}</Prefix>');
    buffer.writeln(
      '  <MaxUploads>${FileManagementService.maxKeysLimit}</MaxUploads>',
    );
    buffer.writeln('  <IsTruncated>false</IsTruncated>');
    for (final upload in uploads) {
      buffer.writeln('  <Upload>');
      buffer.writeln('    <Key>${_escapeXml(upload.key)}</Key>');
      buffer.writeln('    <UploadId>${upload.uploadId}</UploadId>');
      for (final role in ['Initiator', 'Owner']) {
        buffer.writeln(
          '    <$role><ID>$_ownerId</ID><DisplayName>$_ownerId</DisplayName></$role>',
        );
      }
      buffer.writeln('    <StorageClass>STANDARD</StorageClass>');
      buffer.writeln(
        '    <Initiated>${_s3Date(upload.initiated)}</Initiated>',
      );
      buffer.writeln('  </Upload>');
    }
    buffer.writeln('</ListMultipartUploadsResult>');
    return buffer.toString();
  }

  String _mapDeleteResultToXml(DeleteObjectsResponse result) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<DeleteResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    if (!result.quiet) {
      for (final key in result.deleted) {
        buffer.writeln('  <Deleted><Key>${_escapeXml(key)}</Key></Deleted>');
      }
    }
    for (final error in result.errors) {
      buffer.writeln('  <Error>');
      buffer.writeln('    <Key>${_escapeXml(error.key)}</Key>');
      buffer.writeln('    <Code>${error.code}</Code>');
      buffer.writeln('    <Message>${_escapeXml(error.message)}</Message>');
      buffer.writeln('  </Error>');
    }
    buffer.writeln('</DeleteResult>');
    return buffer.toString();
  }

  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _mapBucketsToXml(List<BucketModel> buckets) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    //hay un unico usuario; algunos clientes (minio-java) exigen el Owner
    buffer.writeln('  <Owner>');
    buffer.writeln('    <ID>$_ownerId</ID>');
    buffer.writeln('    <DisplayName>$_ownerId</DisplayName>');
    buffer.writeln('  </Owner>');
    buffer.writeln('  <Buckets>');
    for (final bucket in buckets) {
      buffer.writeln('    <Bucket>');
      buffer.writeln('      <Name>${bucket.name}</Name>');
      if (bucket.description != null) {
        buffer.writeln(
          '      <Description>${_escapeXml(bucket.description!)}</Description>',
        );
      }
      buffer.writeln('      <Color>${bucket.color}</Color>');
      buffer.writeln(
        '      <CreationDate>${_s3Date(bucket.creationDate)}</CreationDate>',
      );
      buffer.writeln('      <ObjectCount>${bucket.objectCount}</ObjectCount>');
      buffer.writeln('      <Size>${bucket.size}</Size>');
      buffer.writeln('    </Bucket>');
    }
    buffer.writeln('  </Buckets>');
    buffer.writeln('</ListAllMyBucketsResult>');
    return buffer.toString();
  }

  String _mapCopyResultToXml(FileModel copied) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<CopyObjectResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    buffer.writeln(
      '  <LastModified>${_s3Date(copied.lastModified)}</LastModified>',
    );
    buffer.writeln('  <ETag>&quot;${copied.etag}&quot;</ETag>');
    buffer.writeln('</CopyObjectResult>');
    return buffer.toString();
  }

  /// ListObjects en XML: V2 (`list-type=2`, pagina con continuation-token) o
  /// V1 (pagina con marker). Con `encoding-type=url` las keys y los prefijos
  /// van codificados como URL (salvo `/`), y el cliente los decodifica
  String _mapListObjectsToXml(
    ListObjectsResponse response, {
    required bool v2,
    required bool urlEncoded,
  }) {
    String text(String value) => urlEncoded
        ? value.split('/').map(SigV4Signer.uriEncode).join('/')
        : _escapeXml(value);

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    buffer.writeln('  <Name>${response.bucketName}</Name>');
    buffer.writeln('  <Prefix>${text(response.prefix ?? '')}</Prefix>');
    if (response.delimiter != null) {
      buffer.writeln('  <Delimiter>${text(response.delimiter!)}</Delimiter>');
    }
    if (urlEncoded) buffer.writeln('  <EncodingType>url</EncodingType>');
    buffer.writeln('  <MaxKeys>${response.maxKeys}</MaxKeys>');
    if (v2) {
      buffer.writeln('  <KeyCount>${response.keyCount}</KeyCount>');
      if (response.startAfter != null) {
        buffer.writeln(
          '  <StartAfter>${text(response.startAfter!)}</StartAfter>',
        );
      }
      if (response.continuationToken != null) {
        buffer.writeln(
          '  <ContinuationToken>${response.continuationToken}</ContinuationToken>',
        );
      }
      if (response.nextContinuationToken != null) {
        buffer.writeln(
          '  <NextContinuationToken>${response.nextContinuationToken}</NextContinuationToken>',
        );
      }
    } else {
      buffer.writeln('  <Marker>${text(response.startAfter ?? '')}</Marker>');
      if (response.nextMarker != null) {
        buffer.writeln(
          '  <NextMarker>${text(response.nextMarker!)}</NextMarker>',
        );
      }
    }
    buffer.writeln('  <IsTruncated>${response.isTruncated}</IsTruncated>');

    for (final file in response.contents) {
      buffer.writeln('  <Contents>');
      buffer.writeln('    <Key>${text(file.key)}</Key>');
      buffer.writeln(
        '    <LastModified>${_s3Date(file.lastModified)}</LastModified>',
      );
      buffer.writeln('    <ETag>&quot;${file.etag}&quot;</ETag>');
      buffer.writeln('    <Size>${file.size}</Size>');
      buffer.writeln('    <StorageClass>STANDARD</StorageClass>');
      buffer.writeln('  </Contents>');
    }

    for (final prefix in response.commonPrefixes) {
      buffer.writeln('  <CommonPrefixes>');
      buffer.writeln('    <Prefix>${text(prefix)}</Prefix>');
      buffer.writeln('  </CommonPrefixes>');
    }

    buffer.writeln('</ListBucketResult>');
    return buffer.toString();
  }
}
