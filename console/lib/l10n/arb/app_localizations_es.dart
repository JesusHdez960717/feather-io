// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Feather IO';

  @override
  String get appNeedMoreSpace => 'Se necesita más espacio';

  @override
  String get splashTitle => 'Administración';

  @override
  String get splashFooter => 'Con ♥ desde Maple';

  @override
  String get loading => 'Cargando';

  @override
  String get error => 'Error';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get noData => 'Sin datos';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get required => 'Requerido';

  @override
  String get preview => 'Vista previa';

  @override
  String get download => 'Descargar';

  @override
  String get upload => 'Subir';

  @override
  String get filter => 'Filtrar';

  @override
  String get name => 'Nombre';

  @override
  String get type => 'Tipo';

  @override
  String get size => 'Tamaño';

  @override
  String get objects => 'Objetos';

  @override
  String get createdAt => 'Fecha de creación';

  @override
  String get lastModified => 'Última modificación';

  @override
  String get errorRequestCancelled => 'La petición al servidor fue cancelada';

  @override
  String get errorConnectionTimeout =>
      'Tiempo de conexión agotado con el servidor. Revisa tu conexión a internet';

  @override
  String get errorNoConnection =>
      'No se pudo conectar con el servidor. Revisa tu conexión a internet';

  @override
  String get errorReceiveTimeout =>
      'Tiempo de espera agotado al recibir datos del servidor';

  @override
  String get errorSendTimeout =>
      'Tiempo de espera agotado al enviar datos al servidor';

  @override
  String get errorBadCertificate => 'Certificado inválido';

  @override
  String get errorConnection => 'Error de conexión';

  @override
  String get errorValidation => 'Error de validación';

  @override
  String get errorServer => 'Error del servidor';

  @override
  String get errorUnknown => 'Error desconocido';

  @override
  String get navBrowser => 'Explorador';

  @override
  String get loginAccessKey => 'Clave de acceso';

  @override
  String get loginAccessKeyHint => 'Introduce tu clave de acceso';

  @override
  String get loginSecretKey => 'Clave secreta';

  @override
  String get loginSecretKeyHint => 'Introduce tu clave secreta';

  @override
  String get loginButton => 'Iniciar sesión';

  @override
  String get bucketsTitle => 'Buckets';

  @override
  String get bucketsSubtitle =>
      'Gestiona tus buckets compatibles con S3 y tus recursos de almacenamiento.';

  @override
  String get bucketsCreate => 'Crear bucket';

  @override
  String get bucketsEdit => 'Editar bucket';

  @override
  String get bucketsTotalBuckets => 'Total de buckets';

  @override
  String get bucketsTotalObjects => 'Total de objetos';

  @override
  String get bucketsTotalStorage => 'Almacenamiento total';

  @override
  String get bucketsSearchHint => 'Buscar buckets...';

  @override
  String get bucketsEmpty => 'No se encontraron buckets';

  @override
  String bucketsNoMatch(String query) {
    return 'Ningún bucket coincide con \"$query\"';
  }

  @override
  String get bucketsDeleteTitle => 'Eliminar bucket';

  @override
  String bucketsDeleteConfirm(String name) {
    return '¿Seguro que quieres eliminar el bucket $name?';
  }

  @override
  String get bucketsReadWriteBadge => 'L/E';

  @override
  String get bucketsReadWriteTooltip =>
      'En este bucket tienes acceso de lectura y escritura';

  @override
  String bucketsCreatedAt(String date) {
    return 'Creado $date';
  }

  @override
  String get bucketCreateDescription =>
      'Configura los parámetros del almacenamiento de objetos de alto rendimiento, la redundancia y las políticas de protección.';

  @override
  String get bucketCreateSectionGeneral => '01 Configuración general';

  @override
  String get bucketCreateSectionAdditional => '02 Información adicional';

  @override
  String get bucketCreateNameLabel => 'Identificador del bucket';

  @override
  String get bucketCreateNameHint => 'mi-bucket';

  @override
  String get bucketCreateDescriptionLabel => 'Descripción (opcional)';

  @override
  String get bucketCreateDescriptionHint =>
      'Breve descripción del uso del bucket';

  @override
  String get bucketNameRequired => 'El nombre del bucket es obligatorio';

  @override
  String get bucketNameLength => 'Entre 3 y 63 caracteres';

  @override
  String get bucketNameChars => 'Solo minúsculas, números y guiones';

  @override
  String get bucketNameHyphenEdges => 'No puede empezar ni terminar con guion';

  @override
  String get bucketRuleChars => 'Solo minúsculas, números y guiones';

  @override
  String get bucketRuleHyphenEdges => 'Sin guion al inicio o al final';

  @override
  String get objectsSearchHint => 'Buscar objetos...';

  @override
  String get objectsEmpty => 'No se encontraron objetos';

  @override
  String get objectsNoMatchFilter => 'Ningún objeto coincide con los filtros';

  @override
  String get objectsFilterTitle => 'Filtros';

  @override
  String get objectsFilterClear => 'Limpiar';

  @override
  String get objectsFilterType => 'Tipo';

  @override
  String get objectsFilterTypeOther => 'Otros';

  @override
  String get objectsFilterSize => 'Tamaño';

  @override
  String get objectsFilterSizeSmall => 'Menos de 1 MB';

  @override
  String get objectsFilterSizeMedium => 'De 1 MB a 100 MB';

  @override
  String get objectsFilterSizeLarge => 'Más de 100 MB';

  @override
  String get objectsFilterModified => 'Modificado';

  @override
  String get objectsFilterDate24h => 'Últimas 24 horas';

  @override
  String get objectsFilterDate7d => 'Últimos 7 días';

  @override
  String get objectsFilterDate30d => 'Últimos 30 días';

  @override
  String get objectsFilterDateOlder => 'Hace más de 30 días';

  @override
  String get objectsFilterFoldersHidden =>
      'Las carpetas se ocultan mientras haya un filtro activo.';

  @override
  String objectsNoMatch(String query) {
    return 'Ningún objeto coincide con \"$query\"';
  }

  @override
  String get objectsDragHint => 'Arrastra ficheros aquí para subirlos';

  @override
  String get objectsDropHere => 'Suelta aquí para subir';

  @override
  String get objectsDeleteTitle => 'Eliminar objetos';

  @override
  String objectsDeleteConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Seguro que quieres eliminar $count objetos?',
      one: '¿Seguro que quieres eliminar 1 objeto?',
    );
    return '$_temp0';
  }

  @override
  String get objectsUploadFiles => 'Subir ficheros';

  @override
  String get objectsUploadDirectory => 'Subir carpeta';

  @override
  String get fileTypeFolder => 'Carpeta';

  @override
  String get fileTypeFile => 'Fichero';

  @override
  String get fileTypeImage => 'Imagen';

  @override
  String get fileTypeVideo => 'Vídeo';

  @override
  String get fileTypeAudio => 'Audio';

  @override
  String get fileTypeText => 'Texto';

  @override
  String get fileTypeDocument => 'Documento';

  @override
  String get fileTypeSpreadsheet => 'Hoja de cálculo';

  @override
  String get fileTypeArchive => 'Comprimido';

  @override
  String get colorNone => 'Sin color';

  @override
  String get colorCustom => 'Color personalizado';

  @override
  String get colorApply => 'Aplicar';

  @override
  String get colorSaturationBrightness => 'Saturación y brillo';

  @override
  String get colorHue => 'Tono';

  @override
  String colorContrast(String ratio) {
    return 'Contraste con el icono: $ratio:1';
  }

  @override
  String colorContrastLow(String ratio) {
    return 'Poco contraste con el icono ($ratio:1)';
  }

  @override
  String get colorHexInvalid =>
      'Escribe un color HEX de 6 dígitos, por ejemplo #0E7490';

  @override
  String get colorViolet => 'Violeta';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorTeal => 'Verde azulado';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorAmber => 'Ámbar';

  @override
  String get colorRed => 'Rojo';

  @override
  String get colorPink => 'Rosa';

  @override
  String get colorSlate => 'Pizarra';

  @override
  String get bucketCreateColorLabel => 'Color';

  @override
  String get bucketNameExists => 'Ya existe un bucket con ese nombre';

  @override
  String get bucketCreateErrorTitle => 'No se pudo crear el bucket';

  @override
  String bucketEditDescription(String name) {
    return 'Cambia la descripción y el color del bucket $name. El nombre no se puede cambiar.';
  }

  @override
  String get bucketEditSave => 'Guardar cambios';

  @override
  String get bucketEditErrorTitle => 'No se pudo guardar el bucket';

  @override
  String bucketUpdatedSuccess(String name) {
    return 'Bucket «$name» actualizado';
  }

  @override
  String bucketCreatedSuccess(String name) {
    return 'Bucket «$name» creado';
  }

  @override
  String bucketNamePathHint(String name) {
    return 'Se usará en las rutas S3: /$name';
  }
}
