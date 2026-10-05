///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'messages.g.dart';

// Path: <root>
typedef ServiceMessagesEn = ServiceMessages; // ignore: unused_element

class ServiceMessages
    with BaseTranslations<ServiceMessagesLocale, ServiceMessages> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [ServiceMessagesLocale.build] is preferred.
  ServiceMessages({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<ServiceMessagesLocale, ServiceMessages>? meta,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       _meta =
           meta ??
           TranslationMetadata(
             locale: ServiceMessagesLocale.en,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  final TranslationMetadata<ServiceMessagesLocale, ServiceMessages> _meta;
  @override
  TranslationMetadata<ServiceMessagesLocale, ServiceMessages> get $meta =>
      _meta;

  /// Access flat map
  dynamic operator [](String key) => _meta.getTranslation(key);

  late final ServiceMessages _root = this; // ignore: unused_field

  ServiceMessages $copyWith({
    TranslationMetadata<ServiceMessagesLocale, ServiceMessages>? meta,
  }) => ServiceMessages(meta: meta ?? this.$meta);

  // Translations
  late final ServiceMessages$errors$en errors = ServiceMessages$errors$en._(
    _root,
  );
}

// Path: errors
class ServiceMessages$errors$en {
  ServiceMessages$errors$en._(this._root);

  final ServiceMessages _root; // ignore: unused_field

  // Translations
  late final ServiceMessages$errors$s3$en s3 = ServiceMessages$errors$s3$en._(
    _root,
  );
  late final ServiceMessages$errors$copy$en copy =
      ServiceMessages$errors$copy$en._(_root);
  late final ServiceMessages$errors$multiDelete$en multiDelete =
      ServiceMessages$errors$multiDelete$en._(_root);
  late final ServiceMessages$errors$multipart$en multipart =
      ServiceMessages$errors$multipart$en._(_root);
  late final ServiceMessages$errors$signature$en signature =
      ServiceMessages$errors$signature$en._(_root);
  late final ServiceMessages$errors$admin$en admin =
      ServiceMessages$errors$admin$en._(_root);
  late final ServiceMessages$errors$validations$en validations =
      ServiceMessages$errors$validations$en._(_root);
}

// Path: errors.s3
class ServiceMessages$errors$s3$en {
  ServiceMessages$errors$s3$en._(this._root);

  final ServiceMessages _root; // ignore: unused_field

  // Translations

  /// en: 'The bucket name "{bucket: String}" is not valid.'
  String invalidBucketName({required String bucket}) =>
      'The bucket name "${bucket}" is not valid.';

  /// en: 'The bucket name "{bucket: String}" is not valid. It must be 3 to 63 characters long, use only lowercase letters, digits, dots or hyphens, and start and end with a letter or a digit.'
  String invalidBucketNameRules({required String bucket}) =>
      'The bucket name "${bucket}" is not valid. It must be 3 to 63 characters long, use only lowercase letters, digits, dots or hyphens, and start and end with a letter or a digit.';

  /// en: 'Bucket name "{bucket: String}" is reserved.'
  String reservedBucket({required String bucket}) =>
      'Bucket name "${bucket}" is reserved.';

  /// en: 'The bucket "{bucket: String}" does not exist.'
  String noSuchBucket({required String bucket}) =>
      'The bucket "${bucket}" does not exist.';

  /// en: 'The bucket "{bucket: String}" already exists.'
  String bucketAlreadyExists({required String bucket}) =>
      'The bucket "${bucket}" already exists.';

  /// en: 'The bucket "{bucket: String}" is not empty and cannot be deleted.'
  String bucketNotEmpty({required String bucket}) =>
      'The bucket "${bucket}" is not empty and cannot be deleted.';

  /// en: 'The key "{key: String}" is not valid or contains forbidden characters.'
  String invalidKey({required String key}) =>
      'The key "${key}" is not valid or contains forbidden characters.';

  /// en: 'The key "{key: String}" does not exist.'
  String noSuchKey({required String key}) => 'The key "${key}" does not exist.';

  /// en: 'The subresource "{subresource: String}" is not implemented.'
  String unsupportedSubresource({required String subresource}) =>
      'The subresource "${subresource}" is not implemented.';

  /// en: 'The storage class "{value: String}" is not valid.'
  String invalidStorageClass({required String value}) =>
      'The storage class "${value}" is not valid.';

  /// en: 'max-keys must be an integer.'
  String get maxKeysNotInteger => 'max-keys must be an integer.';

  /// en: 'max-keys cannot be negative.'
  String get maxKeysNegative => 'max-keys cannot be negative.';

  /// en: 'The continuation-token is not valid.'
  String get continuationTokenInvalid => 'The continuation-token is not valid.';

  /// en: 'The range {range: String} is outside the object ({size: int} bytes).'
  String rangeOutsideObject({required String range, required int size}) =>
      'The range ${range} is outside the object (${size} bytes).';

  /// en: 'The object is over the maximum of {max: int} bytes.'
  String objectOverMaximum({required int max}) =>
      'The object is over the maximum of ${max} bytes.';

  /// en: 'The object is {size: int} bytes and the maximum is {max: int}.'
  String objectSizeOverMaximum({required int size, required int max}) =>
      'The object is ${size} bytes and the maximum is ${max}.';

  /// en: 'The object is in use and cannot be replaced; please retry.'
  String get objectInUse =>
      'The object is in use and cannot be replaced; please retry.';

  /// en: 'The aws-chunked body is incomplete or malformed.'
  String get incompleteChunkedBody =>
      'The aws-chunked body is incomplete or malformed.';

  /// en: 'No objects found to download.'
  String get nothingToDownload => 'No objects found to download.';

  /// en: 'Missing the folder to delete (prefix).'
  String get missingFolderPrefix => 'Missing the folder to delete (prefix).';

  /// en: 'Please reduce your request rate.'
  String get slowDown => 'Please reduce your request rate.';

  /// en: 'The expiration must be between 1 second and 7 days.'
  String get presignExpiration =>
      'The expiration must be between 1 second and 7 days.';
}

// Path: errors.copy
class ServiceMessages$errors$copy$en {
  ServiceMessages$errors$copy$en._(this._root);

  final ServiceMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Copying an object requires read permission on the source.'
  String get needsReadPermission =>
      'Copying an object requires read permission on the source.';

  /// en: 'x-amz-copy-source must look like /bucket/key.'
  String get sourceFormat => 'x-amz-copy-source must look like /bucket/key.';

  /// en: 'x-amz-copy-source-range must look like bytes=a-b.'
  String get sourceRangeFormat =>
      'x-amz-copy-source-range must look like bytes=a-b.';

  /// en: 'The source object does not meet the copy conditions.'
  String get conditionsFailed =>
      'The source object does not meet the copy conditions.';

  /// en: 'Copying an object onto itself requires changing its metadata or its storage class.'
  String get ontoItself =>
      'Copying an object onto itself requires changing its metadata or its storage class.';
}

// Path: errors.multiDelete
class ServiceMessages$errors$multiDelete$en {
  ServiceMessages$errors$multiDelete$en._(this._root);

  final ServiceMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Multi-object delete requires ?delete parameter'
  String get needsDeleteParam =>
      'Multi-object delete requires ?delete parameter';

  /// en: 'At most {max: int} objects can be deleted per request.'
  String tooManyKeys({required int max}) =>
      'At most ${max} objects can be deleted per request.';

  /// en: 'Invalid JSON for delete request'
  String get invalidJson => 'Invalid JSON for delete request';

  /// en: 'The body must be a <Delete> with the objects to delete.'
  String get invalidBody =>
      'The body must be a <Delete> with the objects to delete.';
}

// Path: errors.multipart
class ServiceMessages$errors$multipart$en {
  ServiceMessages$errors$multipart$en._(this._root);

  final ServiceMessages _root; // ignore: unused_field

  // Translations

  /// en: 'POST on an object only supports ?uploads or ?uploadId.'
  String get postNotSupported =>
      'POST on an object only supports ?uploads or ?uploadId.';

  /// en: 'Multipart uploads require the upload permission.'
  String get needsUploadPermission =>
      'Multipart uploads require the upload permission.';

  /// en: 'Missing the part number (partNumber).'
  String get missingPartNumber => 'Missing the part number (partNumber).';

  /// en: 'The part number must be between 1 and {max: int}.'
  String partNumberRange({required int max}) =>
      'The part number must be between 1 and ${max}.';

  /// en: 'The part list is not valid.'
  String get invalidPartList => 'The part list is not valid.';

  /// en: 'At least one part must be specified.'
  String get noParts => 'At least one part must be specified.';

  /// en: 'The parts must be in ascending order.'
  String get partsOrder => 'The parts must be in ascending order.';

  /// en: 'Part {number: int} has not been uploaded.'
  String partNotUploaded({required int number}) =>
      'Part ${number} has not been uploaded.';

  /// en: 'The ETag of part {number: int} does not match.'
  String partEtagMismatch({required int number}) =>
      'The ETag of part ${number} does not match.';

  /// en: 'Part {number: int} is {size: int} bytes; every part but the last one must be at least {min: int}.'
  String partTooSmall({
    required int number,
    required int size,
    required int min,
  }) =>
      'Part ${number} is ${size} bytes; every part but the last one must be at least ${min}.';

  /// en: 'The upload "{uploadId: String}" does not exist or has already finished.'
  String noSuchUpload({required String uploadId}) =>
      'The upload "${uploadId}" does not exist or has already finished.';
}

// Path: errors.signature
class ServiceMessages$errors$signature$en {
  ServiceMessages$errors$signature$en._(this._root);

  final ServiceMessages _root; // ignore: unused_field

  // Translations

  /// en: 'The request signature is not valid.'
  String get invalid => 'The request signature is not valid.';

  /// en: 'Invalid Authorization header format'
  String get invalidAuthorizationHeader =>
      'Invalid Authorization header format';

  /// en: 'Invalid Credential format'
  String get invalidCredential => 'Invalid Credential format';

  /// en: 'The credential's date is not the signature's date.'
  String get credentialDateMismatch =>
      'The credential\'s date is not the signature\'s date.';

  /// en: 'The signature date is more than {minutes: int} minutes away from the server's time.'
  String clockSkew({required int minutes}) =>
      'The signature date is more than ${minutes} minutes away from the server\'s time.';

  /// en: 'Signature mismatch'
  String get mismatch => 'Signature mismatch';

  /// en: 'The body does not match the signed x-amz-content-sha256.'
  String get sha256Mismatch =>
      'The body does not match the signed x-amz-content-sha256.';

  /// en: 'The access key does not exist or is not active.'
  String get accessKeyInactive =>
      'The access key does not exist or is not active.';

  /// en: 'Missing {name: String} in the presigned URL'
  String presignMissingParam({required String name}) =>
      'Missing ${name} in the presigned URL';

  /// en: 'Unsupported signing algorithm'
  String get unsupportedAlgorithm => 'Unsupported signing algorithm';

  /// en: 'Invalid X-Amz-Date or X-Amz-Expires'
  String get invalidDateOrExpires => 'Invalid X-Amz-Date or X-Amz-Expires';

  /// en: 'The presigned URL is not valid yet.'
  String get presignNotYetValid => 'The presigned URL is not valid yet.';

  /// en: 'Request has expired'
  String get expired => 'Request has expired';
}

// Path: errors.admin
class ServiceMessages$errors$admin$en {
  ServiceMessages$errors$admin$en._(this._root);

  final ServiceMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Invalid credentials'
  String get invalidCredentials => 'Invalid credentials';

  /// en: 'Too many failed login attempts'
  String get tooManyLoginAttempts => 'Too many failed login attempts';

  /// en: 'Invalid login request'
  String get invalidLoginRequest => 'Invalid login request';

  /// en: 'Invalid request'
  String get invalidRequest => 'Invalid request';

  /// en: 'Too many requests'
  String get tooManyRequests => 'Too many requests';

  /// en: 'Access key not found'
  String get accessKeyNotFound => 'Access key not found';
}

// Path: errors.validations
class ServiceMessages$errors$validations$en {
  ServiceMessages$errors$validations$en._(this._root);

  final ServiceMessages _root; // ignore: unused_field

  // Translations

  /// en: 'Not a valid bucket name'
  String get bucketName => 'Not a valid bucket name';

  /// en: 'Not a valid ISO 8601 date'
  String get isoDate => 'Not a valid ISO 8601 date';

  /// en: 'The expiration date must be in the future'
  String get futureExpiry => 'The expiration date must be in the future';

  /// en: 'Give the key all_buckets or at least one bucket'
  String get accessKeyNoScope =>
      'Give the key all_buckets or at least one bucket';

  /// en: 'Use all_buckets or buckets, not both'
  String get accessKeyBothScopes => 'Use all_buckets or buckets, not both';

  /// en: 'Each bucket can only appear once'
  String get accessKeyRepeatedBucket => 'Each bucket can only appear once';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on ServiceMessages {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'errors.s3.invalidBucketName' => ({
        required String bucket,
      }) => 'The bucket name "${bucket}" is not valid.',
      'errors.s3.invalidBucketNameRules' => ({
        required String bucket,
      }) => 'The bucket name "${bucket}" is not valid. It must be 3 to 63 characters long, use only lowercase letters, digits, dots or hyphens, and start and end with a letter or a digit.',
      'errors.s3.reservedBucket' => ({
        required String bucket,
      }) => 'Bucket name "${bucket}" is reserved.',
      'errors.s3.noSuchBucket' => ({
        required String bucket,
      }) => 'The bucket "${bucket}" does not exist.',
      'errors.s3.bucketAlreadyExists' => ({
        required String bucket,
      }) => 'The bucket "${bucket}" already exists.',
      'errors.s3.bucketNotEmpty' => ({
        required String bucket,
      }) => 'The bucket "${bucket}" is not empty and cannot be deleted.',
      'errors.s3.invalidKey' => ({
        required String key,
      }) => 'The key "${key}" is not valid or contains forbidden characters.',
      'errors.s3.noSuchKey' => ({
        required String key,
      }) => 'The key "${key}" does not exist.',
      'errors.s3.unsupportedSubresource' => ({
        required String subresource,
      }) => 'The subresource "${subresource}" is not implemented.',
      'errors.s3.invalidStorageClass' => ({
        required String value,
      }) => 'The storage class "${value}" is not valid.',
      'errors.s3.maxKeysNotInteger' => 'max-keys must be an integer.',
      'errors.s3.maxKeysNegative' => 'max-keys cannot be negative.',
      'errors.s3.continuationTokenInvalid' =>
        'The continuation-token is not valid.',
      'errors.s3.rangeOutsideObject' => ({
        required String range,
        required int size,
      }) => 'The range ${range} is outside the object (${size} bytes).',
      'errors.s3.objectOverMaximum' => ({
        required int max,
      }) => 'The object is over the maximum of ${max} bytes.',
      'errors.s3.objectSizeOverMaximum' => ({
        required int size,
        required int max,
      }) => 'The object is ${size} bytes and the maximum is ${max}.',
      'errors.s3.objectInUse' =>
        'The object is in use and cannot be replaced; please retry.',
      'errors.s3.incompleteChunkedBody' =>
        'The aws-chunked body is incomplete or malformed.',
      'errors.s3.nothingToDownload' => 'No objects found to download.',
      'errors.s3.missingFolderPrefix' =>
        'Missing the folder to delete (prefix).',
      'errors.s3.slowDown' => 'Please reduce your request rate.',
      'errors.s3.presignExpiration' =>
        'The expiration must be between 1 second and 7 days.',
      'errors.copy.needsReadPermission' =>
        'Copying an object requires read permission on the source.',
      'errors.copy.sourceFormat' =>
        'x-amz-copy-source must look like /bucket/key.',
      'errors.copy.sourceRangeFormat' =>
        'x-amz-copy-source-range must look like bytes=a-b.',
      'errors.copy.conditionsFailed' =>
        'The source object does not meet the copy conditions.',
      'errors.copy.ontoItself' => 'Copying an object onto itself requires changing its metadata or its storage class.',
      'errors.multiDelete.needsDeleteParam' =>
        'Multi-object delete requires ?delete parameter',
      'errors.multiDelete.tooManyKeys' => ({
        required int max,
      }) => 'At most ${max} objects can be deleted per request.',
      'errors.multiDelete.invalidJson' => 'Invalid JSON for delete request',
      'errors.multiDelete.invalidBody' =>
        'The body must be a <Delete> with the objects to delete.',
      'errors.multipart.postNotSupported' =>
        'POST on an object only supports ?uploads or ?uploadId.',
      'errors.multipart.needsUploadPermission' =>
        'Multipart uploads require the upload permission.',
      'errors.multipart.missingPartNumber' =>
        'Missing the part number (partNumber).',
      'errors.multipart.partNumberRange' => ({
        required int max,
      }) => 'The part number must be between 1 and ${max}.',
      'errors.multipart.invalidPartList' => 'The part list is not valid.',
      'errors.multipart.noParts' => 'At least one part must be specified.',
      'errors.multipart.partsOrder' => 'The parts must be in ascending order.',
      'errors.multipart.partNotUploaded' => ({
        required int number,
      }) => 'Part ${number} has not been uploaded.',
      'errors.multipart.partEtagMismatch' => ({
        required int number,
      }) => 'The ETag of part ${number} does not match.',
      'errors.multipart.partTooSmall' => ({
        required int number,
        required int size,
        required int min,
      }) => 'Part ${number} is ${size} bytes; every part but the last one must be at least ${min}.',
      'errors.multipart.noSuchUpload' => ({
        required String uploadId,
      }) => 'The upload "${uploadId}" does not exist or has already finished.',
      'errors.signature.invalid' => 'The request signature is not valid.',
      'errors.signature.invalidAuthorizationHeader' =>
        'Invalid Authorization header format',
      'errors.signature.invalidCredential' => 'Invalid Credential format',
      'errors.signature.credentialDateMismatch' =>
        'The credential\'s date is not the signature\'s date.',
      'errors.signature.clockSkew' => ({
        required int minutes,
      }) => 'The signature date is more than ${minutes} minutes away from the server\'s time.',
      'errors.signature.mismatch' => 'Signature mismatch',
      'errors.signature.sha256Mismatch' =>
        'The body does not match the signed x-amz-content-sha256.',
      'errors.signature.accessKeyInactive' =>
        'The access key does not exist or is not active.',
      'errors.signature.presignMissingParam' => ({
        required String name,
      }) => 'Missing ${name} in the presigned URL',
      'errors.signature.unsupportedAlgorithm' =>
        'Unsupported signing algorithm',
      'errors.signature.invalidDateOrExpires' =>
        'Invalid X-Amz-Date or X-Amz-Expires',
      'errors.signature.presignNotYetValid' =>
        'The presigned URL is not valid yet.',
      'errors.signature.expired' => 'Request has expired',
      'errors.admin.invalidCredentials' => 'Invalid credentials',
      'errors.admin.tooManyLoginAttempts' => 'Too many failed login attempts',
      'errors.admin.invalidLoginRequest' => 'Invalid login request',
      'errors.admin.invalidRequest' => 'Invalid request',
      'errors.admin.tooManyRequests' => 'Too many requests',
      'errors.admin.accessKeyNotFound' => 'Access key not found',
      'errors.validations.bucketName' => 'Not a valid bucket name',
      'errors.validations.isoDate' => 'Not a valid ISO 8601 date',
      'errors.validations.futureExpiry' =>
        'The expiration date must be in the future',
      'errors.validations.accessKeyNoScope' =>
        'Give the key all_buckets or at least one bucket',
      'errors.validations.accessKeyBothScopes' =>
        'Use all_buckets or buckets, not both',
      'errors.validations.accessKeyRepeatedBucket' =>
        'Each bucket can only appear once',
      _ => null,
    };
  }
}
