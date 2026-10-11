import 'dart:io';
import 'dart:math';

import 'package:mime/mime.dart';
import 'package:service/feather.dart';

/// The S3 operations on objects: PutObject, CopyObject, GetObject (and HEAD),
/// GetObjectTagging, DeleteObject and DeleteObjects.
class ObjectController {
  final ObjectService objectService;
  final AnonymousAccessService anonymousAccess;

  ObjectController()
    : objectService = di.find(),
      anonymousAccess = AnonymousAccessService();

  Future<ResponseEntity> putObject(RequestEntity request) async {
    final etag = await objectService.uploadFile(
      bucketName: request.bucketName,
      key: request.objectKey,
      binary: request.objectBody(),
      headers: request.objectHeaders(),
    );
    return ResponseEntity(200, headers: {'etag': '"$etag"'});
  }

  /// CopyObject: `PUT` with `x-amz-copy-source: /bucket/key`.
  Future<ResponseEntity> copyObject(RequestEntity request) async {
    final (sourceBucket, sourceKey) = await copySource(
      request,
      request.headers['x-amz-copy-source']!,
    );

    // As in S3: copies the source's headers unless REPLACE is requested
    final replace =
        request.headers['x-amz-metadata-directive']?.toUpperCase() == 'REPLACE';
    final copied = await objectService.copyFile(
      sourceBucket: sourceBucket,
      sourceKey: sourceKey,
      bucketName: request.bucketName,
      key: request.pathParams['key']!,
      headers: replace ? request.objectHeaders() : null,
      storageClass: request.storageClass(),
      conditions: request.copyConditions(),
    );
    return S3Response.ok(request, CopyObjectResultModel(copied));
  }

  /// The source object of a copy (`x-amz-copy-source`: `/bucket/key` or
  /// `bucket/key`, URL-encoded and maybe with `?versionId`), also for
  /// UploadPartCopy. Reading it requires the regular download permission (an
  /// anonymous request can't copy). An access key needs read access to the
  /// source: its own on that bucket or, as in AWS, an anonymous read rule
  /// covering the source key.
  Future<(String, String)> copySource(
    RequestEntity request,
    String copySource,
  ) async {
    final (bucket, key) = _parseCopySource(copySource);
    final authentication = request.securityContext.authentication;
    final principal = authentication?.principal;
    final canRead = principal is AccessKeyModel
        ? principal.canRead(bucket) || await _publiclyReadable(bucket, key)
        : (authentication?.permissions ?? const {}).contains('s3.get-object');
    if (!canRead) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.copy.needsReadPermission,
        resource: copySource,
      );
    }
    return (bucket, key);
  }

  /// Whether an anonymous rule lets anyone download [key] of [bucket].
  Future<bool> _publiclyReadable(String bucket, String key) async {
    final rule = await anonymousAccess.findMatchingRule(
      bucket: bucket,
      key: key,
    );
    return rule != null && rule.access != AnonymousAccessType.writeOnly;
  }

  (String, String) _parseCopySource(String copySource) {
    final source = Uri.decodeComponent(copySource.split('?').first);
    final path = source.startsWith('/') ? source.substring(1) : source;
    final slash = path.indexOf('/');
    if (slash <= 0 || slash == path.length - 1) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: intl.errors.copy.sourceFormat,
        resource: copySource,
      );
    }
    return (path.substring(0, slash), path.substring(slash + 1));
  }

  /// GetObject, and HEAD through the same route (Winter sends the headers
  /// only).
  Future<ResponseEntity> getObject(RequestEntity request) async {
    final bucketName = request.bucketName;
    final key = request.objectKey;
    final file = await objectService.getFile(bucketName: bucketName, key: key);
    final stat = await file.stat();
    final meta = await objectService.metaOf(
      bucketName: bucketName,
      key: key,
      file: file,
      stat: stat,
    );

    // Without a stored Content-Type, the extension's
    final headers = {
      'content-type':
          lookupMimeType(file.path) ??
          MediaType.applicationOctetStream.mimeType,
      ...meta.headers,
      'last-modified': HttpDate.format(stat.modified),
      'etag': '"${meta.etag}"',
      'accept-ranges': 'bytes',
    };

    // A signed request may override the response headers with
    // ?response-content-type=… (S3 doesn't allow it to anonymous ones; an
    // access key may, even when an anonymous rule is what lets it read)
    final authentication = request.securityContext.authentication;
    if ((authentication?.permissions ?? const {}).contains('s3.get-object') ||
        authentication?.principal is AccessKeyModel) {
      for (final name in _overridableHeaders) {
        final value = request.queryParams['response-$name'];
        if (value != null) headers[name] = value;
      }
    }

    final range = _requestedRange(request, stat.size, key);
    if (range == null) {
      return ResponseEntity<Stream<List<int>>>(
        200,
        body: file.openRead(),
        headers: {...headers, 'content-length': stat.size.toString()},
      );
    }
    final (start, end) = range;
    return ResponseEntity<Stream<List<int>>>(
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

  /// The range requested by the `Range` header (`bytes=a-b`, `bytes=a-` or
  /// `bytes=-n`, the last n) as inclusive positions. Null without the header or
  /// when it can't be parsed: the whole object is served then, as S3 does (it
  /// doesn't support multiple ranges either). A range outside the object is a
  /// 416.
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
        message: intl.errors.s3.rangeOutsideObject(
          range: '"$header"',
          size: size,
        ),
        resource: key,
      );
    }
    return (start, end);
  }

  /// GetObjectTagging (`?tagging`): the service doesn't store tags, so there
  /// are none. The AWS CLI asks for them before a multipart copy.
  Future<ResponseEntity> objectTagging(RequestEntity request) async {
    await objectService.getFile(
      bucketName: request.bucketName,
      key: request.objectKey,
    );
    return S3Response.xml(
      S3Xml.root('Tagging', [XmlElement.leaf('TagSet', null)]),
    );
  }

  Future<ResponseEntity> deleteObject(RequestEntity request) async {
    await objectService.deleteFile(
      bucketName: request.bucketName,
      key: request.objectKey,
    );
    return ResponseEntity.noContent();
  }

  /// DeleteObjects (`POST /{bucket}?delete`): the S3 `<Delete>` XML or, with a
  /// JSON `Content-Type` or body, the console's JSON; at most 1000 keys.
  Future<ResponseEntity> deleteObjects(RequestEntity request) async {
    final bucketName = request.bucketName;

    if (!request.queryParams.containsKey('delete')) {
      throw S3Exception(
        S3ErrorCode.invalidRequest,
        message: intl.errors.multiDelete.needsDeleteParam,
        resource: bucketName,
      );
    }

    final body = await request.readAsString();
    final isJson =
        request.headers['content-type']?.contains('json') == true ||
        body.trimLeft().startsWith('{');
    final deleteRequest = isJson
        ? _readDeleteJson(body, bucketName)
        : _readDeleteXml(body, bucketName);
    if (deleteRequest.keys.length > ObjectService.maxKeysLimit) {
      throw S3Exception(
        S3ErrorCode.malformedXML,
        message: intl.errors.multiDelete.tooManyKeys(
          max: ObjectService.maxKeysLimit,
        ),
        resource: bucketName,
      );
    }

    final result = await objectService.deleteObjects(
      bucketName: bucketName,
      request: deleteRequest,
    );
    return S3Response.ok(request, result);
  }

  DeleteObjectsRequest _readDeleteJson(String body, String bucketName) {
    final Map<String, dynamic> json;
    try {
      json = om.decode<Map<String, dynamic>>(body);
    } catch (_) {
      throw S3Exception(
        S3ErrorCode.invalidRequest,
        message: intl.errors.multiDelete.invalidJson,
        resource: bucketName,
      );
    }
    // Outside the try: a body with the wrong shape is a 400 naming the field
    return DeleteObjectsRequest.fromJson(json);
  }

  DeleteObjectsRequest _readDeleteXml(String body, String bucketName) {
    try {
      return DeleteObjectsRequest.fromXml(XmlElement.parse(body));
    } catch (_) {
      // Not well-formed, or not a <Delete>
      throw S3Exception(
        S3ErrorCode.malformedXML,
        message: intl.errors.multiDelete.invalidBody,
        resource: bucketName,
      );
    }
  }
}
