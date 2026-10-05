///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'messages.g.dart';

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';

// Path: <root>
class ServiceMessagesEs
    with BaseTranslations<ServiceMessagesLocale, ServiceMessages>
    implements ServiceMessages {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [ServiceMessagesLocale.build] is preferred.
  ServiceMessagesEs({
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
             locale: ServiceMessagesLocale.es,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    _meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <es>.
  final TranslationMetadata<ServiceMessagesLocale, ServiceMessages> _meta;
  @override
  TranslationMetadata<ServiceMessagesLocale, ServiceMessages> get $meta =>
      _meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => _meta.getTranslation(key);

  late final ServiceMessagesEs _root = this; // ignore: unused_field

  @override
  ServiceMessagesEs $copyWith({
    TranslationMetadata<ServiceMessagesLocale, ServiceMessages>? meta,
  }) => ServiceMessagesEs(meta: meta ?? this.$meta);

  // Translations
  @override
  late final ServiceMessages$errors$es errors = ServiceMessages$errors$es._(
    _root,
  );
}

// Path: errors
class ServiceMessages$errors$es implements ServiceMessages$errors$en {
  ServiceMessages$errors$es._(this._root);

  final ServiceMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  late final ServiceMessages$errors$s3$es s3 = ServiceMessages$errors$s3$es._(
    _root,
  );
  @override
  late final ServiceMessages$errors$copy$es copy =
      ServiceMessages$errors$copy$es._(_root);
  @override
  late final ServiceMessages$errors$multiDelete$es multiDelete =
      ServiceMessages$errors$multiDelete$es._(_root);
  @override
  late final ServiceMessages$errors$multipart$es multipart =
      ServiceMessages$errors$multipart$es._(_root);
  @override
  late final ServiceMessages$errors$signature$es signature =
      ServiceMessages$errors$signature$es._(_root);
  @override
  late final ServiceMessages$errors$admin$es admin =
      ServiceMessages$errors$admin$es._(_root);
  @override
  late final ServiceMessages$errors$validations$es validations =
      ServiceMessages$errors$validations$es._(_root);
}

// Path: errors.s3
class ServiceMessages$errors$s3$es implements ServiceMessages$errors$s3$en {
  ServiceMessages$errors$s3$es._(this._root);

  final ServiceMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String invalidBucketName({required Object bucket}) =>
      'El nombre de bucket "${bucket}" no es válido.';
  @override
  String invalidBucketNameRules({required Object bucket}) =>
      'El nombre de bucket "${bucket}" no es válido. Debe tener entre 3 y 63 caracteres, usar solo minúsculas, dígitos, puntos o guiones, y empezar y terminar con una letra o un dígito.';
  @override
  String reservedBucket({required Object bucket}) =>
      'El nombre de bucket "${bucket}" está reservado.';
  @override
  String noSuchBucket({required Object bucket}) =>
      'El bucket "${bucket}" no existe.';
  @override
  String bucketAlreadyExists({required Object bucket}) =>
      'El bucket "${bucket}" ya existe.';
  @override
  String bucketNotEmpty({required Object bucket}) =>
      'El bucket "${bucket}" no está vacío y no se puede eliminar.';
  @override
  String invalidKey({required Object key}) =>
      'La key "${key}" no es válida o contiene caracteres no permitidos.';
  @override
  String noSuchKey({required Object key}) => 'La key "${key}" no existe.';
  @override
  String unsupportedSubresource({required Object subresource}) =>
      'El subrecurso "${subresource}" no está implementado.';
  @override
  String invalidStorageClass({required Object value}) =>
      'La clase de almacenamiento "${value}" no es válida.';
  @override
  String get maxKeysNotInteger => 'max-keys debe ser un número entero.';
  @override
  String get maxKeysNegative => 'max-keys no puede ser negativo.';
  @override
  String get continuationTokenInvalid => 'El continuation-token no es válido.';
  @override
  String rangeOutsideObject({required Object range, required Object size}) =>
      'El rango ${range} está fuera del objeto (${size} bytes).';
  @override
  String objectOverMaximum({required Object max}) =>
      'El objeto supera el máximo de ${max} bytes.';
  @override
  String objectSizeOverMaximum({required Object size, required Object max}) =>
      'El objeto tiene ${size} bytes y el máximo es ${max}.';
  @override
  String get objectInUse =>
      'El objeto está en uso y no se puede reemplazar; vuelve a intentarlo.';
  @override
  String get incompleteChunkedBody =>
      'El cuerpo aws-chunked está incompleto o mal formado.';
  @override
  String get nothingToDownload => 'No se encontraron objetos para descargar.';
  @override
  String get missingFolderPrefix => 'Falta la carpeta a eliminar (prefix).';
  @override
  String get slowDown => 'Reduce el ritmo de peticiones.';
  @override
  String get presignExpiration =>
      'La caducidad debe estar entre 1 segundo y 7 días.';
}

// Path: errors.copy
class ServiceMessages$errors$copy$es implements ServiceMessages$errors$copy$en {
  ServiceMessages$errors$copy$es._(this._root);

  final ServiceMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get needsReadPermission =>
      'Copiar un objeto requiere permiso de lectura sobre el origen.';
  @override
  String get sourceFormat =>
      'x-amz-copy-source debe tener la forma /bucket/key.';
  @override
  String get sourceRangeFormat =>
      'x-amz-copy-source-range debe tener la forma bytes=a-b.';
  @override
  String get conditionsFailed =>
      'El objeto de origen no cumple las condiciones de la copia.';
  @override
  String get ontoItself =>
      'Copiar un objeto sobre sí mismo requiere cambiar sus metadatos o su clase de almacenamiento.';
}

// Path: errors.multiDelete
class ServiceMessages$errors$multiDelete$es
    implements ServiceMessages$errors$multiDelete$en {
  ServiceMessages$errors$multiDelete$es._(this._root);

  final ServiceMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get needsDeleteParam =>
      'El borrado múltiple requiere el parámetro ?delete';
  @override
  String tooManyKeys({required Object max}) =>
      'Se pueden eliminar como mucho ${max} objetos por petición.';
  @override
  String get invalidJson => 'JSON no válido en la petición de borrado';
  @override
  String get invalidBody =>
      'El cuerpo debe ser un <Delete> con los objetos a eliminar.';
}

// Path: errors.multipart
class ServiceMessages$errors$multipart$es
    implements ServiceMessages$errors$multipart$en {
  ServiceMessages$errors$multipart$es._(this._root);

  final ServiceMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get postNotSupported =>
      'POST sobre un objeto solo admite ?uploads o ?uploadId.';
  @override
  String get needsUploadPermission =>
      'Las subidas multipart requieren permiso de subida.';
  @override
  String get missingPartNumber => 'Falta el número de parte (partNumber).';
  @override
  String partNumberRange({required Object max}) =>
      'El número de parte debe estar entre 1 y ${max}.';
  @override
  String get invalidPartList => 'La lista de partes no es válida.';
  @override
  String get noParts => 'Hay que indicar al menos una parte.';
  @override
  String get partsOrder => 'Las partes deben ir en orden ascendente.';
  @override
  String partNotUploaded({required Object number}) =>
      'La parte ${number} no se ha subido.';
  @override
  String partEtagMismatch({required Object number}) =>
      'El ETag de la parte ${number} no coincide.';
  @override
  String partTooSmall({
    required Object number,
    required Object size,
    required Object min,
  }) =>
      'La parte ${number} tiene ${size} bytes; todas las partes menos la última deben tener al menos ${min}.';
  @override
  String noSuchUpload({required Object uploadId}) =>
      'La subida "${uploadId}" no existe o ya terminó.';
}

// Path: errors.signature
class ServiceMessages$errors$signature$es
    implements ServiceMessages$errors$signature$en {
  ServiceMessages$errors$signature$es._(this._root);

  final ServiceMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get invalid => 'La firma de la petición no es válida.';
  @override
  String get invalidAuthorizationHeader =>
      'La cabecera Authorization no tiene un formato válido';
  @override
  String get invalidCredential => 'El Credential no tiene un formato válido';
  @override
  String get credentialDateMismatch =>
      'La fecha del credential no es la de la firma.';
  @override
  String clockSkew({required Object minutes}) =>
      'La fecha de la firma se aleja más de ${minutes} minutos de la hora del servidor.';
  @override
  String get mismatch => 'La firma no coincide';
  @override
  String get sha256Mismatch =>
      'El cuerpo no coincide con el x-amz-content-sha256 firmado.';
  @override
  String get accessKeyInactive =>
      'La clave de acceso no existe o no está activa.';
  @override
  String presignMissingParam({required Object name}) =>
      'Falta ${name} en la URL prefirmada';
  @override
  String get unsupportedAlgorithm => 'Algoritmo de firma no soportado';
  @override
  String get invalidDateOrExpires => 'X-Amz-Date o X-Amz-Expires no válidos';
  @override
  String get presignNotYetValid => 'La URL prefirmada todavía no es válida.';
  @override
  String get expired => 'La petición ha caducado';
}

// Path: errors.admin
class ServiceMessages$errors$admin$es
    implements ServiceMessages$errors$admin$en {
  ServiceMessages$errors$admin$es._(this._root);

  final ServiceMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get invalidCredentials => 'Credenciales no válidas';
  @override
  String get tooManyLoginAttempts =>
      'Demasiados intentos de inicio de sesión fallidos';
  @override
  String get invalidLoginRequest => 'Petición de inicio de sesión no válida';
  @override
  String get invalidRequest => 'Petición no válida';
  @override
  String get tooManyRequests => 'Demasiadas peticiones';
  @override
  String get accessKeyNotFound => 'No se encontró la clave de acceso';
}

// Path: errors.validations
class ServiceMessages$errors$validations$es
    implements ServiceMessages$errors$validations$en {
  ServiceMessages$errors$validations$es._(this._root);

  final ServiceMessagesEs _root; // ignore: unused_field

  // Translations
  @override
  String get bucketName => 'No es un nombre de bucket válido';
  @override
  String get isoDate => 'No es una fecha ISO 8601 válida';
  @override
  String get futureExpiry => 'La fecha de caducidad debe ser futura';
  @override
  String get accessKeyNoScope =>
      'Dale a la clave all_buckets o al menos un bucket';
  @override
  String get accessKeyBothScopes => 'Usa all_buckets o buckets, no los dos';
  @override
  String get accessKeyRepeatedBucket =>
      'Cada bucket solo puede aparecer una vez';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on ServiceMessagesEs {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'errors.s3.invalidBucketName' => ({
        required Object bucket,
      }) => 'El nombre de bucket "${bucket}" no es válido.',
      'errors.s3.invalidBucketNameRules' => ({
        required Object bucket,
      }) => 'El nombre de bucket "${bucket}" no es válido. Debe tener entre 3 y 63 caracteres, usar solo minúsculas, dígitos, puntos o guiones, y empezar y terminar con una letra o un dígito.',
      'errors.s3.reservedBucket' => ({
        required Object bucket,
      }) => 'El nombre de bucket "${bucket}" está reservado.',
      'errors.s3.noSuchBucket' => ({
        required Object bucket,
      }) => 'El bucket "${bucket}" no existe.',
      'errors.s3.bucketAlreadyExists' => ({
        required Object bucket,
      }) => 'El bucket "${bucket}" ya existe.',
      'errors.s3.bucketNotEmpty' => ({
        required Object bucket,
      }) => 'El bucket "${bucket}" no está vacío y no se puede eliminar.',
      'errors.s3.invalidKey' => ({
        required Object key,
      }) => 'La key "${key}" no es válida o contiene caracteres no permitidos.',
      'errors.s3.noSuchKey' => ({
        required Object key,
      }) => 'La key "${key}" no existe.',
      'errors.s3.unsupportedSubresource' => ({
        required Object subresource,
      }) => 'El subrecurso "${subresource}" no está implementado.',
      'errors.s3.invalidStorageClass' => ({
        required Object value,
      }) => 'La clase de almacenamiento "${value}" no es válida.',
      'errors.s3.maxKeysNotInteger' => 'max-keys debe ser un número entero.',
      'errors.s3.maxKeysNegative' => 'max-keys no puede ser negativo.',
      'errors.s3.continuationTokenInvalid' =>
        'El continuation-token no es válido.',
      'errors.s3.rangeOutsideObject' => ({
        required Object range,
        required Object size,
      }) => 'El rango ${range} está fuera del objeto (${size} bytes).',
      'errors.s3.objectOverMaximum' => ({
        required Object max,
      }) => 'El objeto supera el máximo de ${max} bytes.',
      'errors.s3.objectSizeOverMaximum' => ({
        required Object size,
        required Object max,
      }) => 'El objeto tiene ${size} bytes y el máximo es ${max}.',
      'errors.s3.objectInUse' =>
        'El objeto está en uso y no se puede reemplazar; vuelve a intentarlo.',
      'errors.s3.incompleteChunkedBody' =>
        'El cuerpo aws-chunked está incompleto o mal formado.',
      'errors.s3.nothingToDownload' =>
        'No se encontraron objetos para descargar.',
      'errors.s3.missingFolderPrefix' =>
        'Falta la carpeta a eliminar (prefix).',
      'errors.s3.slowDown' => 'Reduce el ritmo de peticiones.',
      'errors.s3.presignExpiration' =>
        'La caducidad debe estar entre 1 segundo y 7 días.',
      'errors.copy.needsReadPermission' =>
        'Copiar un objeto requiere permiso de lectura sobre el origen.',
      'errors.copy.sourceFormat' =>
        'x-amz-copy-source debe tener la forma /bucket/key.',
      'errors.copy.sourceRangeFormat' =>
        'x-amz-copy-source-range debe tener la forma bytes=a-b.',
      'errors.copy.conditionsFailed' =>
        'El objeto de origen no cumple las condiciones de la copia.',
      'errors.copy.ontoItself' => 'Copiar un objeto sobre sí mismo requiere cambiar sus metadatos o su clase de almacenamiento.',
      'errors.multiDelete.needsDeleteParam' =>
        'El borrado múltiple requiere el parámetro ?delete',
      'errors.multiDelete.tooManyKeys' => ({
        required Object max,
      }) => 'Se pueden eliminar como mucho ${max} objetos por petición.',
      'errors.multiDelete.invalidJson' =>
        'JSON no válido en la petición de borrado',
      'errors.multiDelete.invalidBody' =>
        'El cuerpo debe ser un <Delete> con los objetos a eliminar.',
      'errors.multipart.postNotSupported' =>
        'POST sobre un objeto solo admite ?uploads o ?uploadId.',
      'errors.multipart.needsUploadPermission' =>
        'Las subidas multipart requieren permiso de subida.',
      'errors.multipart.missingPartNumber' =>
        'Falta el número de parte (partNumber).',
      'errors.multipart.partNumberRange' => ({
        required Object max,
      }) => 'El número de parte debe estar entre 1 y ${max}.',
      'errors.multipart.invalidPartList' => 'La lista de partes no es válida.',
      'errors.multipart.noParts' => 'Hay que indicar al menos una parte.',
      'errors.multipart.partsOrder' =>
        'Las partes deben ir en orden ascendente.',
      'errors.multipart.partNotUploaded' => ({
        required Object number,
      }) => 'La parte ${number} no se ha subido.',
      'errors.multipart.partEtagMismatch' => ({
        required Object number,
      }) => 'El ETag de la parte ${number} no coincide.',
      'errors.multipart.partTooSmall' => ({
        required Object number,
        required Object size,
        required Object min,
      }) => 'La parte ${number} tiene ${size} bytes; todas las partes menos la última deben tener al menos ${min}.',
      'errors.multipart.noSuchUpload' => ({
        required Object uploadId,
      }) => 'La subida "${uploadId}" no existe o ya terminó.',
      'errors.signature.invalid' => 'La firma de la petición no es válida.',
      'errors.signature.invalidAuthorizationHeader' =>
        'La cabecera Authorization no tiene un formato válido',
      'errors.signature.invalidCredential' =>
        'El Credential no tiene un formato válido',
      'errors.signature.credentialDateMismatch' =>
        'La fecha del credential no es la de la firma.',
      'errors.signature.clockSkew' => ({
        required Object minutes,
      }) => 'La fecha de la firma se aleja más de ${minutes} minutos de la hora del servidor.',
      'errors.signature.mismatch' => 'La firma no coincide',
      'errors.signature.sha256Mismatch' =>
        'El cuerpo no coincide con el x-amz-content-sha256 firmado.',
      'errors.signature.accessKeyInactive' =>
        'La clave de acceso no existe o no está activa.',
      'errors.signature.presignMissingParam' => ({
        required Object name,
      }) => 'Falta ${name} en la URL prefirmada',
      'errors.signature.unsupportedAlgorithm' =>
        'Algoritmo de firma no soportado',
      'errors.signature.invalidDateOrExpires' =>
        'X-Amz-Date o X-Amz-Expires no válidos',
      'errors.signature.presignNotYetValid' =>
        'La URL prefirmada todavía no es válida.',
      'errors.signature.expired' => 'La petición ha caducado',
      'errors.admin.invalidCredentials' => 'Credenciales no válidas',
      'errors.admin.tooManyLoginAttempts' =>
        'Demasiados intentos de inicio de sesión fallidos',
      'errors.admin.invalidLoginRequest' =>
        'Petición de inicio de sesión no válida',
      'errors.admin.invalidRequest' => 'Petición no válida',
      'errors.admin.tooManyRequests' => 'Demasiadas peticiones',
      'errors.admin.accessKeyNotFound' => 'No se encontró la clave de acceso',
      'errors.validations.bucketName' => 'No es un nombre de bucket válido',
      'errors.validations.isoDate' => 'No es una fecha ISO 8601 válida',
      'errors.validations.futureExpiry' =>
        'La fecha de caducidad debe ser futura',
      'errors.validations.accessKeyNoScope' =>
        'Dale a la clave all_buckets o al menos un bucket',
      'errors.validations.accessKeyBothScopes' =>
        'Usa all_buckets o buckets, no los dos',
      'errors.validations.accessKeyRepeatedBucket' =>
        'Cada bucket solo puede aparecer una vez',
      _ => null,
    };
  }
}
