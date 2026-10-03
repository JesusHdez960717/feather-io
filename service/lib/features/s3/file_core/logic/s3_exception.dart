import 'package:service/feather.dart';

/// Códigos de error de AWS S3 que usa el servicio, con su status HTTP.
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
  serviceUnavailable('ServiceUnavailable', 503),
  signatureDoesNotMatch('SignatureDoesNotMatch', 403);

  final String code;
  final int statusCode;

  const S3ErrorCode(this.code, this.statusCode);
}

/// Error de negocio con código S3. El controller lo serializa a XML o JSON
/// según el `Accept` (ver `S3ExceptionHandler`).
class S3Exception extends ApiException implements Serializable {
  final S3ErrorCode code;
  final String message;

  /// Bucket o key sobre el que falló la operación.
  final String? resource;

  S3Exception(this.code, {required this.message, this.resource})
    : super(statusCode: code.statusCode, body: message);

  S3Exception.invalidBucketName(String bucketName)
    : this(
        S3ErrorCode.invalidBucketName,
        message: 'El nombre del bucket "$bucketName" no es válido.',
        resource: bucketName,
      );

  S3Exception.invalidKey(String key)
    : this(
        S3ErrorCode.invalidArgument,
        message: 'El key "$key" no es válido o contiene caracteres prohibidos.',
        resource: key,
      );

  S3Exception.noSuchBucket(String bucketName)
    : this(
        S3ErrorCode.noSuchBucket,
        message: 'El bucket "$bucketName" no existe.',
        resource: bucketName,
      );

  S3Exception.noSuchKey(String key)
    : this(
        S3ErrorCode.noSuchKey,
        message: 'El archivo "$key" no existe.',
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
