import 'package:service/feather.dart';

/// The S3 operations on buckets: ListBuckets, CreateBucket, DeleteBucket and
/// what `GET /{bucket}` answers (ListObjects V1/V2, GetBucketLocation,
/// GetBucketVersioning).
class BucketController {
  final FileManagementService fileManagement;
  final BucketService bucketService;

  BucketController()
    : fileManagement = di.find(),
      bucketService = BucketService();

  Future<ResponseEntity> listBuckets(RequestEntity request) async {
    var buckets = await bucketService.listBuckets();
    // An access key only sees the buckets it can reach
    final principal = request.securityContext.authentication?.principal;
    if (principal is AccessKeyModel) {
      buckets = [
        for (final bucket in buckets)
          if (principal.levelOn(bucket.name) != null) bucket,
      ];
    }
    return S3Response.ok(request, BucketListModel(buckets));
  }

  Future<ResponseEntity> createBucket(RequestEntity request) async {
    final bucketName = request.bucketName;

    CreateBucketRequest? createRequest;
    try {
      // Validated below: a 422 must not fall into this catch
      createRequest = await request.body<CreateBucketRequest>(validate: false);
    } catch (_) {
      // Defaults when the body is empty or not JSON (the S3
      // CreateBucketConfiguration XML)
      createRequest = null;
    }
    createRequest?.validate().throwOnFailure();

    await bucketService.createBucket(
      bucketName: bucketName,
      description: createRequest?.description,
      color: createRequest?.color,
    );

    // As in S3: no body, and the bucket path in Location
    return ResponseEntity(200, headers: {'location': '/$bucketName'});
  }

  Future<ResponseEntity> deleteBucket(RequestEntity request) async {
    await bucketService.deleteBucket(bucketName: request.bucketName);
    return ResponseEntity.noContent();
  }

  Future<ResponseEntity> listObjects(RequestEntity request) async {
    final bucketName = request.bucketName;
    final prefix = request.queryParams['prefix'];
    final delimiter = request.queryParams['delimiter'];
    final maxKeysParam = request.queryParams['max-keys'];
    final maxKeys = maxKeysParam == null
        ? FileManagementService.maxKeysLimit
        : int.tryParse(maxKeysParam);
    if (maxKeys == null) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: intl.errors.s3.maxKeysNotInteger,
        resource: maxKeysParam,
      );
    }

    // ListObjectsV2 with list-type=2; otherwise V1 (pages with marker)
    final v2 = request.queryParams['list-type'] == '2';
    final result = await fileManagement.listFiles(
      bucketName: bucketName,
      prefix: prefix,
      delimiter: delimiter,
      maxKeys: maxKeys,
      continuationToken: request.queryParams['continuation-token'],
      startAfter: request.queryParams[v2 ? 'start-after' : 'marker'],
    );

    return S3Response.ok(
      request,
      result.asListing(
        v2: v2,
        urlEncoded: request.queryParams['encoding-type'] == 'url',
      ),
    );
  }

  /// GetBucketLocation (`?location`): always the default region, which S3
  /// returns as an empty LocationConstraint. Clients ask for it to know which
  /// region to sign with.
  Future<ResponseEntity> bucketLocation(RequestEntity request) async {
    await _checkExists(request.bucketName);
    return S3Response.xml(S3Xml.root('LocationConstraint', const []));
  }

  /// GetBucketVersioning (`?versioning`): versioning is never enabled, so
  /// there is no Status. rclone asks for it before a purge.
  Future<ResponseEntity> bucketVersioning(RequestEntity request) async {
    await _checkExists(request.bucketName);
    return S3Response.xml(S3Xml.root('VersioningConfiguration', const []));
  }

  Future<void> _checkExists(String bucketName) async {
    if (!await fileManagement.bucketExists(bucketName)) {
      throw S3Exception.noSuchBucket(bucketName);
    }
  }
}
