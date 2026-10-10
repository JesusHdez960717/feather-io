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
