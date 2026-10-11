import 'package:service/feather.dart';

/// The routes of the S3 API. S3 multiplexes several operations on one method
/// and path, told apart by the query and the headers (`PUT /{bucket}/{key}` is
/// PutObject, CopyObject, UploadPart or UploadPartCopy): each route sends the
/// request to the operation of [BucketController], [ObjectController] or
/// [MultipartController] it is.
class S3Controller {
  final BucketController buckets;
  final ObjectController objects;
  final MultipartController multipart;

  S3Controller._(this.buckets, this.objects, this.multipart);

  factory S3Controller() {
    final objects = ObjectController();
    return S3Controller._(
      BucketController(),
      objects,
      MultipartController(objects),
    );
  }

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
          handler: buckets.listBuckets,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.list-buckets')),
          ]),
        ),
        Route.put(
          key: 's3.create-bucket',
          path: '/{bucket}',
          handler: buckets.createBucket,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.create-bucket')),
            ReservedBucketFilter(),
          ]),
        ),
        Route.delete(
          key: 's3.delete-bucket',
          path: '/{bucket}',
          handler: buckets.deleteBucket,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.delete-bucket')),
            ReservedBucketFilter(),
          ]),
        ),
        Route.get(
          key: 's3.list-objects',
          path: '/{bucket}',
          handler: _getBucket,
          filterConfig: FilterConfig([
            AuthFilter(
              rules:
                  hasPermission('s3.list-objects') |
                  hasPermission('s3.anonymous.list-objects'),
              shouldFilter: (request) {
                // Only for this very route, so the child routes don't inherit
                // it: get-object must not need the list-objects permission
                return request.route?.key == 's3.list-objects';
              },
            ),
            ReservedBucketFilter(),
          ]),
          routes: [
            Route.put(
              key: 's3.put-object',
              path: '/{key|.*}',
              handler: _putObject,
              filterConfig: FilterConfig([
                AuthFilter(
                  rules:
                      hasPermission('s3.put-object') |
                      hasPermission('s3.anonymous.put-object'),
                ),
              ]),
            ),
            // CreateMultipartUpload (?uploads) and CompleteMultipartUpload (?uploadId)
            Route.post(
              key: 's3.post-object',
              path: '/{key|.*}',
              handler: _postObject,
              filterConfig: FilterConfig([
                AuthFilter(rules: hasPermission('s3.put-object')),
              ]),
            ),
            Route.get(
              key: 's3.get-object',
              path: '/{key|.*}',
              handler: _getObject,
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
              handler: _deleteObject,
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
          handler: objects.deleteObjects,
          filterConfig: FilterConfig([
            AuthFilter(rules: hasPermission('s3.multi-delete-objects')),
            ReservedBucketFilter(),
          ]),
        ),
      ],
    );
  }

  /// `GET /{bucket}`: GetBucketLocation, ListMultipartUploads,
  /// GetBucketVersioning or ListObjects.
  Future<ResponseEntity> _getBucket(RequestEntity request) {
    final query = request.queryParams;
    if (query.containsKey('location')) return buckets.bucketLocation(request);
    if (query.containsKey('uploads')) return multipart.listUploads(request);
    if (query.containsKey('versioning')) {
      return buckets.bucketVersioning(request);
    }
    return buckets.listObjects(request);
  }

  /// `PUT /{bucket}/{key}`: UploadPart (and UploadPartCopy), CopyObject or
  /// PutObject.
  Future<ResponseEntity> _putObject(RequestEntity request) {
    if (request.queryParams.containsKey('uploadId')) {
      return multipart.uploadPart(request);
    }
    if (request.headers['x-amz-copy-source'] != null) {
      return objects.copyObject(request);
    }
    return objects.putObject(request);
  }

  /// `POST /{bucket}/{key}`: only the multipart operations.
  Future<ResponseEntity> _postObject(RequestEntity request) async {
    if (request.queryParams.containsKey('uploads')) {
      return multipart.create(request);
    }
    if (request.queryParams.containsKey('uploadId')) {
      return multipart.complete(request);
    }
    throw S3Exception(
      S3ErrorCode.invalidRequest,
      message: intl.errors.multipart.postNotSupported,
      resource: request.objectKey,
    );
  }

  /// `GET /{bucket}/{key}` (and HEAD): ListParts, GetObjectTagging or
  /// GetObject.
  Future<ResponseEntity> _getObject(RequestEntity request) {
    if (request.queryParams.containsKey('uploadId')) {
      return multipart.listParts(request);
    }
    if (request.queryParams.containsKey('tagging')) {
      return objects.objectTagging(request);
    }
    return objects.getObject(request);
  }

  /// `DELETE /{bucket}/{key}`: AbortMultipartUpload or DeleteObject.
  Future<ResponseEntity> _deleteObject(RequestEntity request) {
    if (request.queryParams.containsKey('uploadId')) {
      return multipart.abort(request);
    }
    return objects.deleteObject(request);
  }
}
