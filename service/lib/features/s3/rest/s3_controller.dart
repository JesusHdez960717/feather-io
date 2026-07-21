import 'package:mime/mime.dart';
import 'package:service/features/features.dart';
import 'package:winter/winter.dart';

class S3Controller {
  final FileManagementService fileManagement;

  Route get routing => Route.parent(
    path: '/',
    routes: [
      Route.get(
        path: '/',
        handler: listBuckets,
        filterConfig: hasRole('admin').toFilterConfig(),
      ),
      Route.get(
        path: '/{bucket}',
        handler: listFiles,
        filterConfig: hasRole('admin').toFilterConfig(),
        routes: [
          Route.put(
            path: '/{key|.*}',
            handler: uploadFile,
            filterConfig: AuthFilter(rules: hasRole('admin')).toFilterConfig(),
          ),
          Route.get(path: '/{key|.*}', key: 's3.get-file', handler: getFile),
          Route.delete(
            path: '/{key|.*}',
            handler: deleteFile,
            filterConfig: hasRole('admin').toFilterConfig(),
          ),
        ],
      ),
    ],
  );

  S3Controller({required this.fileManagement});

  Future<ResponseEntity> listBuckets(RequestEntity request) async {
    final buckets = await fileManagement.listBuckets();

    if (request.headers['accept']?.contains('application/json') == true) {
      return ResponseEntity.ok(body: buckets);
    } else {
      final xmlBody = _mapBucketsToXml(buckets);
      return ResponseEntity.ok(
        body: xmlBody,
        headers: {'content-type': 'application/xml'},
      );
    }
  }

  Future<ResponseEntity> uploadFile(RequestEntity request) async {
    await fileManagement.uploadFile(
      bucketName: request.pathParams['bucket']!,
      key: request.pathParams['key']!,
      binary: request.read(),
    );

    return ResponseEntity.ok(body: 'File uploaded successfully.');
  }

  Future<ResponseEntity> listFiles(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    final prefix = request.queryParams['prefix'];
    final delimiter = request.queryParams['delimiter'];

    final result = await fileManagement.listFiles(
      bucketName: bucketName,
      prefix: prefix,
      delimiter: delimiter,
    );

    if (request.headers['accept']?.contains('application/json') == true) {
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
    final file = await fileManagement.getFile(
      bucketName: request.pathParams['bucket']!,
      key: request.pathParams['key']!,
    );

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

    return ResponseEntity.ok(body: 'File deleted successfully.');
  }

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
