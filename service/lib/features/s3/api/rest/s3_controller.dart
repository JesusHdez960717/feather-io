import 'dart:convert';
import 'dart:io';

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

    return ResponseEntity.ok(body: 'Bucket created successfully.');
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

    await fileManagement.uploadFile(
      bucketName: request.pathParams['bucket']!,
      key: _objectKey(request),
      binary: request.read(),
    );

    return ResponseEntity.ok(body: 'File uploaded successfully.');
  }

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

    // "/bucket/key" o "bucket/key", codificado como URL y quiza con ?versionId
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

    final copied = await fileManagement.copyFile(
      sourceBucket: path.substring(0, slash),
      sourceKey: path.substring(slash + 1),
      bucketName: bucketName,
      key: request.pathParams['key']!,
    );

    if (_acceptsJson(request)) {
      return ResponseEntity.ok(body: copied);
    }
    return ResponseEntity.ok(
      body: _mapCopyResultToXml(copied),
      headers: {'content-type': 'application/xml'},
    );
  }

  Future<ResponseEntity> listObjects(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
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

    final result = await fileManagement.listFiles(
      bucketName: bucketName,
      prefix: prefix,
      delimiter: delimiter,
      maxKeys: maxKeys,
      continuationToken: request.queryParams['continuation-token'],
    );

    if (_acceptsJson(request)) {
      return ResponseEntity.ok(body: result);
    } else {
      final xmlBody = _mapListObjectsToXml(result);
      return ResponseEntity.ok(
        body: xmlBody,
        headers: {'content-type': 'application/xml'},
      );
    }
  }

  Future<ResponseEntity> getFile(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    final key = request.pathParams['key']!;

    final file = await fileManagement.getFile(bucketName: bucketName, key: key);

    final contentType =
        lookupMimeType(file.path) ?? MediaType.applicationOctetStream;

    //un HEAD usa esta misma ruta: Winter manda las cabeceras sin el cuerpo
    final stat = await file.stat();
    return ResponseEntity.ok(
      body: file.openRead(),
      headers: {
        'content-type': contentType,
        'content-length': stat.size.toString(),
        'last-modified': HttpDate.format(stat.modified),
      },
    );
  }

  Future<ResponseEntity> deleteFile(RequestEntity request) async {
    final uploadId = request.queryParams['uploadId'];
    if (uploadId != null) {
      await multipart.abort(
        bucketName: request.pathParams['bucket']!,
        key: _objectKey(request),
        uploadId: uploadId,
      );
      return ResponseEntity(204);
    }

    await fileManagement.deleteFile(
      bucketName: request.pathParams['bucket']!,
      key: request.pathParams['key']!,
    );

    return ResponseEntity(204);
  }

  /// `POST` sobre un objeto: solo las operaciones de multipart
  Future<ResponseEntity> postObject(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    final key = _objectKey(request);

    if (request.queryParams.containsKey('uploads')) {
      final upload = await multipart.create(bucketName: bucketName, key: key);
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

  /// UploadPart: `PUT ?partNumber=N&uploadId=X`. El ETag va en la cabecera
  Future<ResponseEntity> _uploadPart(
    RequestEntity request,
    String uploadId,
  ) async {
    final key = _objectKey(request);
    final partNumber = int.tryParse(request.queryParams['partNumber'] ?? '');
    if (partNumber == null) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: 'Falta el número de parte (partNumber).',
        resource: key,
      );
    }
    final etag = await multipart.uploadPart(
      bucketName: request.pathParams['bucket']!,
      key: key,
      uploadId: uploadId,
      partNumber: partNumber,
      binary: request.read(),
    );
    return ResponseEntity(200, headers: {'etag': '"$etag"'});
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

    String? tag(String xml, String name) => RegExp(
      '<$name>\\s*(.*?)\\s*</$name>',
      dotAll: true,
    ).firstMatch(xml)?.group(1);

    final parts = <CompletedPart>[];
    final partPattern = RegExp(r'<Part>(.*?)</Part>', dotAll: true);
    for (final match in partPattern.allMatches(body)) {
      final xml = match.group(1)!;
      final number = int.tryParse(tag(xml, 'PartNumber') ?? '');
      if (number == null) throw malformed;
      final etag = (tag(xml, 'ETag') ?? '')
          .replaceAll('&quot;', '"')
          .replaceAll('&#34;', '"')
          .replaceAll('&amp;', '&');
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

    try {
      final bodyString = await utf8.decodeStream(request.read());
      final Map<String, dynamic> body = jsonDecode(bodyString);
      final deleteRequest = DeleteObjectsRequest.fromJson(body);

      final result = await fileManagement.deleteObjects(
        bucketName: bucketName,
        request: deleteRequest,
      );

      return ResponseEntity.ok(body: result);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw S3Exception(
        S3ErrorCode.invalidRequest,
        message: 'Invalid JSON for delete request: $e',
        resource: bucketName,
      );
    }
  }

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
    buffer.writeln('  <Buckets>');
    for (final bucket in buckets) {
      buffer.writeln('    <Bucket>');
      buffer.writeln('      <Name>${bucket.name}</Name>');
      if (bucket.description != null) {
        buffer.writeln(
          '      <Description>${bucket.description}</Description>',
        );
      }
      buffer.writeln('      <Color>${bucket.color}</Color>');
      buffer.writeln(
        '      <CreationDate>${bucket.creationDate.toIso8601String()}</CreationDate>',
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
      '  <LastModified>${copied.lastModified.toUtc().toIso8601String()}</LastModified>',
    );
    buffer.writeln('</CopyObjectResult>');
    return buffer.toString();
  }

  String _mapListObjectsToXml(ListObjectsResponse response) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">',
    );
    buffer.writeln('  <Name>${response.bucketName}</Name>');
    if (response.prefix != null) {
      buffer.writeln('  <Prefix>${response.prefix}</Prefix>');
    }
    if (response.delimiter != null) {
      buffer.writeln('  <Delimiter>${response.delimiter}</Delimiter>');
    }
    buffer.writeln('  <MaxKeys>${response.maxKeys}</MaxKeys>');
    buffer.writeln('  <KeyCount>${response.keyCount}</KeyCount>');
    if (response.continuationToken != null) {
      buffer.writeln(
        '  <ContinuationToken>${response.continuationToken}</ContinuationToken>',
      );
    }
    buffer.writeln('  <IsTruncated>${response.isTruncated}</IsTruncated>');
    if (response.nextContinuationToken != null) {
      buffer.writeln(
        '  <NextContinuationToken>${response.nextContinuationToken}</NextContinuationToken>',
      );
    }

    for (final file in response.contents) {
      buffer.writeln('  <Contents>');
      buffer.writeln('    <Key>${file.key}</Key>');
      buffer.writeln(
        '    <LastModified>${file.lastModified.toIso8601String()}</LastModified>',
      );
      buffer.writeln(
        '    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>',
      );
      buffer.writeln('    <Size>${file.size}</Size>');
      buffer.writeln('    <StorageClass>STANDARD</StorageClass>');
      buffer.writeln('  </Contents>');
    }

    for (final prefix in response.commonPrefixes) {
      buffer.writeln('  <CommonPrefixes>');
      buffer.writeln('    <Prefix>$prefix</Prefix>');
      buffer.writeln('  </CommonPrefixes>');
    }

    buffer.writeln('</ListBucketResult>');
    return buffer.toString();
  }
}
