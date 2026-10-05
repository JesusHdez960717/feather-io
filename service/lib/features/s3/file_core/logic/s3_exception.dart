import 'package:service/feather.dart';

/// AWS S3 error codes used by the service, with their HTTP status.
enum S3ErrorCode {
  accessDenied('AccessDenied', 403),
  bucketAlreadyOwnedByYou('BucketAlreadyOwnedByYou', 409),
  bucketNotEmpty('BucketNotEmpty', 409),
  entityTooLarge('EntityTooLarge', 400),
  entityTooSmall('EntityTooSmall', 400),
  incompleteBody('IncompleteBody', 400),
  internalError('InternalError', 500),
  invalidAccessKeyId('InvalidAccessKeyId', 403),
  invalidArgument('InvalidArgument', 400),
  // Admin API only (not AWS codes)
  invalidCredentials('InvalidCredentials', 403),
  noSuchAccessKey('NoSuchAccessKey', 404),
  invalidBucketName('InvalidBucketName', 400),
  invalidPart('InvalidPart', 400),
  invalidPartOrder('InvalidPartOrder', 400),
  invalidRange('InvalidRange', 416),
  invalidStorageClass('InvalidStorageClass', 400),
  invalidRequest('InvalidRequest', 400),
  malformedXML('MalformedXML', 400),
  noSuchBucket('NoSuchBucket', 404),
  noSuchKey('NoSuchKey', 404),
  noSuchUpload('NoSuchUpload', 404),
  notImplemented('NotImplemented', 501),
  preconditionFailed('PreconditionFailed', 412),
  requestTimeTooSkewed('RequestTimeTooSkewed', 403),
  serviceUnavailable('ServiceUnavailable', 503),
  signatureDoesNotMatch('SignatureDoesNotMatch', 403),
  slowDown('SlowDown', 503),
  xAmzContentSHA256Mismatch('XAmzContentSHA256Mismatch', 400);

  final String code;
  final int statusCode;

  const S3ErrorCode(this.code, this.statusCode);
}

/// Business error with an S3 code. `S3ExceptionHandler` renders it as XML or
/// JSON depending on `Accept`. The message is in the request's language
/// (`message: t.errors…`, from `Accept-Language`); the code never changes.
class S3Exception extends ApiException implements Serializable {
  final S3ErrorCode code;

  final String message;

  /// Bucket or key the operation failed on.
  final String? resource;

  S3Exception(this.code, {required this.message, this.resource})
    : super(statusCode: code.statusCode, body: message);

  S3Exception.invalidBucketName(String bucketName)
    : this(
        S3ErrorCode.invalidBucketName,
        message: intl.errors.s3.invalidBucketName(bucket: bucketName),
        resource: bucketName,
      );

  S3Exception.invalidKey(String key)
    : this(
        S3ErrorCode.invalidArgument,
        message: intl.errors.s3.invalidKey(key: key),
        resource: key,
      );

  S3Exception.noSuchBucket(String bucketName)
    : this(
        S3ErrorCode.noSuchBucket,
        message: intl.errors.s3.noSuchBucket(bucket: bucketName),
        resource: bucketName,
      );

  S3Exception.noSuchKey(String key)
    : this(
        S3ErrorCode.noSuchKey,
        message: intl.errors.s3.noSuchKey(key: key),
        resource: key,
      );

  @override
  Map<String, dynamic> toJson() {
    return {
      'code': code.code,
      'message': message,
      if (resource != null) 'resource': resource,
    };
  }

  @override
  String toString() {
    return 'S3Exception{code: ${code.code}, message: $message, resource: $resource}';
  }
}
