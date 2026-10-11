import 'package:service/feather.dart';

/// The S3 multipart upload: CreateMultipartUpload, UploadPart,
/// UploadPartCopy, CompleteMultipartUpload, AbortMultipartUpload, ListParts
/// and ListMultipartUploads. None of them is anonymous: those that go through
/// a route accepting anonymous rules check the upload permission themselves.
class MultipartController {
  final MultipartService multipart;
  final ObjectService objectService;

  /// Resolves the source of UploadPartCopy, with the same rules as CopyObject.
  final ObjectController objects;

  MultipartController(this.objects)
    : multipart = MultipartService(),
      objectService = di.find();

  /// CreateMultipartUpload: `POST /{bucket}/{key}?uploads`.
  Future<ResponseEntity> create(RequestEntity request) async {
    final upload = await multipart.create(
      bucketName: request.bucketName,
      key: request.objectKey,
      headers: request.objectHeaders(),
    );
    return S3Response.ok(request, upload);
  }

  /// CompleteMultipartUpload: `POST /{bucket}/{key}?uploadId=`, with the
  /// parts in the S3 XML or the console's JSON.
  Future<ResponseEntity> complete(RequestEntity request) async {
    final key = request.objectKey;
    final completed = await multipart.complete(
      bucketName: request.bucketName,
      key: key,
      uploadId: request.queryParams['uploadId']!,
      parts: await _completedParts(request, key),
    );
    final uri = request.requestedUri;
    final location = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: uri.path,
    ).toString();
    return S3Response.ok(request, completed.at(location));
  }

  /// The parts of CompleteMultipartUpload: S3 XML or JSON (the console).
  Future<List<CompletedPart>> _completedParts(
    RequestEntity request,
    String key,
  ) async {
    final body = await request.readAsString();
    final json = request.headers['content-type']?.contains('json') == true;
    try {
      final parts = json
          ? CompleteMultipartRequest.fromJson(
              om.decode<Map<String, dynamic>>(body),
            ).parts
          : CompleteMultipartRequest.fromXml(XmlElement.parse(body)).parts;
      if (json || parts.isNotEmpty) return parts;
    } catch (_) {
      // Malformed: answered below
    }
    throw S3Exception(
      S3ErrorCode.malformedXML,
      message: intl.errors.multipart.invalidPartList,
      resource: key,
    );
  }

  /// UploadPart: `PUT ?partNumber=N&uploadId=X`, the ETag in the header; with
  /// `x-amz-copy-source` it is UploadPartCopy.
  Future<ResponseEntity> uploadPart(RequestEntity request) async {
    final key = request.objectKey;
    request.requireUploadPermission(key);
    final partNumber = int.tryParse(request.queryParams['partNumber'] ?? '');
    if (partNumber == null) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: intl.errors.multipart.missingPartNumber,
        resource: key,
      );
    }
    final uploadId = request.queryParams['uploadId']!;
    final copySource = request.headers['x-amz-copy-source'];
    if (copySource != null) {
      return _uploadPartCopy(request, key, uploadId, partNumber, copySource);
    }
    final etag = await multipart.uploadPart(
      bucketName: request.bucketName,
      key: key,
      uploadId: uploadId,
      partNumber: partNumber,
      binary: request.objectBody(),
    );
    return ResponseEntity(200, headers: {'etag': '"$etag"'});
  }

  /// UploadPartCopy: the part is another object, whole or the range in
  /// `x-amz-copy-source-range: bytes=a-b`.
  Future<ResponseEntity> _uploadPartCopy(
    RequestEntity request,
    String key,
    String uploadId,
    int partNumber,
    String copySource,
  ) async {
    final (sourceBucket, sourceKey) = await objects.copySource(
      request,
      copySource,
    );
    final rangeHeader = request.headers['x-amz-copy-source-range'];
    (int, int)? range;
    if (rangeHeader != null) {
      final match = RegExp(r'^bytes=(\d+)-(\d+)$')
          .firstMatch(rangeHeader.trim());
      if (match == null) {
        throw S3Exception(
          S3ErrorCode.invalidArgument,
          message: intl.errors.copy.sourceRangeFormat,
          resource: rangeHeader,
        );
      }
      range = (int.parse(match.group(1)!), int.parse(match.group(2)!));
    }

    final source = await objectService.readForCopy(
      sourceBucket: sourceBucket,
      sourceKey: sourceKey,
      range: range,
      conditions: request.copyConditions(),
    );
    final etag = await multipart.uploadPart(
      bucketName: request.bucketName,
      key: key,
      uploadId: uploadId,
      partNumber: partNumber,
      binary: source,
    );
    return S3Response.ok(
      request,
      CopiedPartModel(etag: etag, lastModified: DateTime.now().toUtc()),
    );
  }

  /// AbortMultipartUpload: `DELETE /{bucket}/{key}?uploadId=`.
  Future<ResponseEntity> abort(RequestEntity request) async {
    final key = request.objectKey;
    request.requireUploadPermission(key);
    await multipart.abort(
      bucketName: request.bucketName,
      key: key,
      uploadId: request.queryParams['uploadId']!,
    );
    return ResponseEntity.noContent();
  }

  /// ListParts (`GET /{bucket}/{key}?uploadId=`): the parts already uploaded,
  /// to resume an upload, by pages (`part-number-marker`, `max-parts`).
  Future<ResponseEntity> listParts(RequestEntity request) async {
    final key = request.objectKey;
    request.requireUploadPermission(key);
    final uploadId = request.queryParams['uploadId']!;
    final marker =
        int.tryParse(request.queryParams['part-number-marker'] ?? '') ?? 0;
    final maxParts =
        (int.tryParse(request.queryParams['max-parts'] ?? '') ??
                ObjectService.maxKeysLimit)
            .clamp(0, ObjectService.maxKeysLimit);

    final pending = (await multipart.listParts(
      bucketName: request.bucketName,
      key: key,
      uploadId: uploadId,
    )).where((part) => part.partNumber > marker).toList();
    final parts = pending.take(maxParts).toList();

    return S3Response.ok(
      request,
      PartListModel(
        bucket: request.bucketName,
        key: key,
        uploadId: uploadId,
        marker: marker,
        maxParts: maxParts,
        isTruncated: pending.length > parts.length,
        parts: parts,
      ),
    );
  }

  /// ListMultipartUploads (`GET /{bucket}?uploads`): the pending uploads,
  /// without paging (at most 1000).
  Future<ResponseEntity> listUploads(RequestEntity request) async {
    final bucketName = request.bucketName;
    request.requireUploadPermission(bucketName);
    final prefix = request.queryParams['prefix'];
    final uploads = (await multipart.list(
      bucketName: bucketName,
      prefix: prefix,
    )).take(ObjectService.maxKeysLimit).toList();
    return S3Response.ok(
      request,
      MultipartUploadListModel(
        bucket: bucketName,
        prefix: prefix,
        uploads: uploads,
      ),
    );
  }
}
