import 'dart:convert';

import 'package:mime/mime.dart';
import 'package:service/feather.dart';

class S3Controller {
  final FileManagementService fileManagement;
  final BucketService bucketService;

  Route get routing {
    return Route.parent(
      path: '/',
      filterConfig: FilterConfig([
        S3BucketNameFilter(),
        JwtFilter(),
        S3SigV4Filter(),
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
          ]),
        ),
        Route.delete(
          key: 's3.delete-bucket',
          path: '/{bucket}',
          handler: deleteBucket,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.delete-bucket')),
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
            AuthFilter(
              rules:
                  hasPermission('s3.multi-delete-objects') |
                  hasPermission('s3.anonymous.multi-delete-objects'),
            ),
            ReservedBucketFilter(),
          ]),
        ),
      ],
    );
  }

  S3Controller() : fileManagement = di.find(), bucketService = BucketService();

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
    await fileManagement.uploadFile(
      bucketName: request.pathParams['bucket']!,
      key: request.pathParams['key']!,
      binary: request.read(),
    );

    return ResponseEntity.ok(body: 'File uploaded successfully.');
  }

  Future<ResponseEntity> listObjects(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    final prefix = request.queryParams['prefix'];
    final delimiter = request.queryParams['delimiter'];

    final result = await fileManagement.listFiles(
      bucketName: bucketName,
      prefix: prefix,
      delimiter: delimiter,
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

    return ResponseEntity.ok(
      body: file.openRead(),
      headers: {
        'content-type': contentType,
        'content-length': (await file.length()).toString(),
      },
    );
  }

  Future<ResponseEntity> deleteFile(RequestEntity request) async {
    await fileManagement.deleteFile(
      bucketName: request.pathParams['bucket']!,
      key: request.pathParams['key']!,
    );

    return ResponseEntity(204);
  }

  Future<ResponseEntity> multiDelete(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    if (!request.queryParams.containsKey('delete')) {
      throw BadRequestException(
        body: 'Multi-object delete requires ?delete parameter',
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
      throw BadRequestException(body: 'Invalid JSON for delete request: $e');
    }
  }

  bool _acceptsJson(RequestEntity request) =>
      request.headers['accept']?.contains('application/json') == true;

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
    buffer.writeln('  <IsTruncated>false</IsTruncated>');

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
