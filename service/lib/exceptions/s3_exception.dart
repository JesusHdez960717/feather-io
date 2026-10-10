import 'package:service/feather.dart';

/// Business error with an S3 code. `S3ExceptionHandler` renders it as the S3
/// `<Error>` XML, or as a Problem Details (`detail` = [message], plus `code` and
/// `resource`) for the admin API and the clients that accept JSON. The message
/// is in the request's language (`message: intl.errors…`, from
/// `Accept-Language`); the code never changes.
class S3Exception extends ApiException implements XmlSerializable {
  final S3ErrorCode code;

  final String message;

  /// Bucket or key the operation failed on.
  final String? resource;

  S3Exception(this.code, {required this.message, this.resource, super.headers})
    : super(
        StatusCode.valueOf(code.statusCode),
        detail: message,
        extensions: {'code': code.code, 'resource': ?resource},
      );

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

  /// The S3 `<Error>` (without namespace, as S3), with the id of the request
  /// so it can be found in the logs.
  @override
  XmlElement toXml() => XmlElement(
    'Error',
    elements: [
      XmlElement.leaf('Code', code.code),
      XmlElement.leaf('Message', message),
      if (resource != null) XmlElement.leaf('Resource', resource),
      if (requestId != null) XmlElement.leaf('RequestId', requestId),
    ],
  );

  @override
  String toString() {
    return 'S3Exception{code: ${code.code}, message: $message, resource: $resource}';
  }
}
