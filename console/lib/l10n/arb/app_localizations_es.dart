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

  @override
  String get navBuckets => 'Buckets';

  @override
  String bucketAdminCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buckets',
      one: '1 bucket',
    );
    return '$_temp0';
  }

  @override
  String bucketAdminStats(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objetos',
      one: '1 objeto',
    );
    return '$_temp0 · $size';
  }

  @override
  String get bucketAdminEmptyDescription =>
      'Crea un bucket para configurarlo aquí.';

  @override
  String get bucketAdminOpenInBrowser => 'Abrir en el explorador';

  @override
  String get bucketAdminTabGeneral => 'General';

  @override
  String get bucketAdminTabAccess => 'Acceso anónimo';

  @override
  String get bucketAdminTabDanger => 'Zona de peligro';

  @override
  String get bucketDetailObjects => 'Objetos';

  @override
  String get bucketDetailSize => 'Tamaño';

  @override
  String get bucketDetailCreated => 'Creado';

  @override
  String get bucketDetailLastModified => 'Última modificación';

  @override
  String get bucketDetailNeverModified => 'Sin objetos';

  @override
  String get bucketDetailName => 'Nombre';

  @override
  String get bucketDetailS3Path => 'Ruta S3';

  @override
  String get bucketDetailCopyPath => 'Copiar ruta';

  @override
  String get bucketDetailPathCopied => 'Ruta copiada';

  @override
  String get bucketDetailDescription => 'Descripción';

  @override
  String get bucketDetailNoDescription => 'Sin descripción';

  @override
  String get bucketDetailColor => 'Color';

  @override
  String get bucketEmptyTitle => 'Vaciar bucket';

  @override
  String get bucketEmptyAlreadyEmpty => 'El bucket no tiene objetos.';

  @override
  String bucketEmptyDescription(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sus $count objetos',
      one: 'su único objeto',
    );
    return 'Elimina $_temp0 ($size). El bucket, su configuración y sus reglas de acceso se mantienen. No se puede deshacer.';
  }

  @override
  String bucketEmptyConfirm(int count, String size, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'eliminarán $count objetos',
      one: 'eliminará 1 objeto',
    );
    return 'Se $_temp0 ($size) de $name. No se puede deshacer.';
  }

  @override
  String bucketEmptyTypeName(String name) {
    return 'Escribe $name para confirmar';
  }

  @override
  String get bucketEmptyTypeNameHelper =>
      'El botón se activa cuando el nombre coincide.';

  @override
  String get bucketDeleteDescription =>
      'Borra el bucket con su descripción, color y reglas de acceso. Como en S3, solo se puede eliminar si está vacío.';

  @override
  String bucketDeleteNotEmpty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objetos',
      one: '1 objeto',
    );
    return 'El bucket tiene $_temp0. Vacíalo primero.';
  }

  @override
  String get anonymousAccessDescription =>
      'Cada regla deja un prefijo accesible sin credenciales. Lo que no cubre ninguna regla sigue necesitando autenticación.';

  @override
  String get anonymousAccessPrivateTitle => 'Bucket privado';

  @override
  String get anonymousAccessPrivateDescription =>
      'Todas las peticiones necesitan credenciales. Añade una regla para servir un prefijo sin autenticación, por ejemplo las imágenes de una web.';

  @override
  String get anonymousAccessReadOnly => 'Solo lectura';

  @override
  String get anonymousAccessWriteOnly => 'Solo escritura';

  @override
  String get anonymousAccessReadWrite => 'Lectura y escritura';

  @override
  String get anonymousAccessReadOnlyOps => 'Listar y descargar objetos';

  @override
  String get anonymousAccessWriteOnlyOps => 'Subir y borrar objetos';

  @override
  String get anonymousAccessReadWriteOps => 'Listar, descargar, subir y borrar';

  @override
  String get anonymousAccessReadOnlyDescription =>
      'Cualquiera puede listar y descargar.';

  @override
  String get anonymousAccessWriteOnlyDescription =>
      'Cualquiera puede subir y borrar, pero no ver.';

  @override
  String get anonymousAccessReadWriteDescription =>
      'Acceso completo sin credenciales.';

  @override
  String get anonymousAccessReadOnlyUseCase =>
      'Webs, catálogos, descargas públicas.';

  @override
  String get anonymousAccessWriteOnlyUseCase =>
      'Buzones de subida, formularios.';

  @override
  String get anonymousAccessReadWriteUseCase =>
      'Úsalo solo en prefijos temporales.';

  @override
  String get anonymousRuleAdd => 'Añadir regla';

  @override
  String get anonymousRulePrefix => 'Prefijo';

  @override
  String get anonymousRuleAccess => 'Acceso';

  @override
  String get anonymousRuleOps => 'Operaciones sin credenciales';

  @override
  String get anonymousRuleHint =>
      'Los prefijos son relativos al bucket y admiten * como comodín. Si varias reglas coinciden, se aplica la primera.';

  @override
  String get anonymousRuleDeleteTitle => 'Eliminar regla';

  @override
  String anonymousRuleDeleteConfirm(String prefix) {
    return '¿Seguro que quieres eliminar la regla $prefix? Los objetos de ese prefijo volverán a necesitar credenciales.';
  }

  @override
  String get anonymousRuleFormTitle => 'Añadir regla de acceso';

  @override
  String anonymousRuleFormDescription(String bucket) {
    return 'Deja un prefijo de $bucket accesible sin credenciales.';
  }

  @override
  String get anonymousRuleFormSectionPrefix => '01 Prefijo';

  @override
  String get anonymousRuleFormSectionAccess => '02 Tipo de acceso';

  @override
  String get anonymousRulePrefixLabel => 'Prefijo o patrón';

  @override
  String get anonymousRulePrefixHint => 'public/';

  @override
  String get anonymousRulePrefixHelper =>
      'Termina en / para una carpeta, o usa * como comodín (por ejemplo, *.jpg).';

  @override
  String get anonymousRulePrefixRequired => 'El prefijo es obligatorio';

  @override
  String get anonymousRuleFormErrorTitle => 'No se pudo añadir la regla';

  @override
  String anonymousRuleCreatedSuccess(String prefix) {
    return 'Regla $prefix añadida';
  }

  @override
  String get bucketSettings => 'Configuración';

  @override
  String browserBucketNotFound(String name) {
    return 'El bucket «$name» no existe';
  }

  @override
  String get browserBucketNotFoundDescription =>
      'Puede que lo hayan borrado o que el enlace esté mal escrito.';

  @override
  String get browserBackToBuckets => 'Ver buckets';

  @override
  String browserFolderNotFound(String folder) {
    return 'La carpeta «$folder» no existe en este bucket';
  }

  @override
  String get browserFolderNotFoundDescription =>
      'Puede que la hayan borrado o que la ruta esté mal escrita. En S3 una carpeta solo existe mientras tiene objetos.';

  @override
  String get browserGoToBucketRoot => 'Ir a la raíz del bucket';

  @override
  String get objectsNewFolder => 'Nueva carpeta';

  @override
  String get objectsNewFolderCreate => 'Crear carpeta';

  @override
  String get objectsFolderNameLabel => 'Nombre de la carpeta';

  @override
  String get objectsFolderNameHint => 'facturas-2026';

  @override
  String objectsFolderPathHelper(String path) {
    return 'Se creará en $path';
  }

  @override
  String objectsFolderCreated(String name) {
    return 'Carpeta «$name» creada';
  }

  @override
  String get objectsFolderExists =>
      'Ya hay una carpeta u objeto con ese nombre aquí.';

  @override
  String get objectsRename => 'Renombrar';

  @override
  String get objectsRenameLabel => 'Nuevo nombre';

  @override
  String objectsRenamePathHelper(String path) {
    return 'Queda en $path';
  }

  @override
  String objectsRenamed(String name) {
    return 'Renombrado a «$name»';
  }

  @override
  String get objectsNameExists =>
      'Ya hay un objeto o carpeta con ese nombre en esta carpeta.';

  @override
  String get objectsNameRequired => 'El nombre es obligatorio';

  @override
  String get objectsNameInvalid => 'No uses / \\ ni ninguno de < > : \" | ? *';

  @override
  String get objectsNameUnchanged => 'Es el nombre actual';

  @override
  String get objectsActionErrorTitle => 'No se pudo completar la acción';

  @override
  String get objectsDetails => 'Detalles';

  @override
  String get objectsMove => 'Mover';

  @override
  String get objectsMoveSelection => 'Mover selección';

  @override
  String objectsMoveTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objetos',
      one: '1 objeto',
    );
    return 'Mover $_temp0';
  }

  @override
  String get objectsMoveBucket => 'Bucket de destino';

  @override
  String get objectsMoveFolder => 'Carpeta de destino';

  @override
  String get objectsMoveNoFolders => 'No hay subcarpetas';

  @override
  String get objectsMoveHere => 'Mover aquí';

  @override
  String objectsMoveHelper(String path) {
    return 'Se moverán a $path. Si ya hay objetos con esos nombres, se sustituyen.';
  }

  @override
  String get objectsMoveSameFolder => 'Ya están en esta carpeta. Elige otra.';

  @override
  String objectsMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objetos movidos',
      one: '1 objeto movido',
    );
    return '$_temp0';
  }

  @override
  String objectsMovePartial(int moved, int total) {
    return 'Solo se movieron $moved de $total objetos.';
  }

  @override
  String objectDetailsSubtitle(String type, String size) {
    return '$type · $size';
  }

  @override
  String get objectDetailsKey => 'Key';

  @override
  String get objectDetailsType => 'Tipo';

  @override
  String get objectDetailsSize => 'Tamaño';

  @override
  String objectDetailsSizeBytes(int bytes) {
    return '($bytes bytes)';
  }

  @override
  String get objectDetailsModified => 'Modificado';

  @override
  String get objectDetailsUrl => 'URL';

  @override
  String get objectDetailsCopyUrl => 'Copiar URL';

  @override
  String get objectDetailsUrlCopied => 'URL copiada';

  @override
  String get objectsPageSize => 'Filas por página:';

  @override
  String objectsPageOf(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get objectsPreviousPage => 'Página anterior';

  @override
  String get objectsNextPage => 'Página siguiente';

  @override
  String get objectsPagerHint =>
      'La búsqueda y los filtros solo se aplican a las páginas ya cargadas.';

  @override
  String objectsPagerHintPages(int loaded, int total) {
    return 'La búsqueda y los filtros solo se aplican a las páginas ya cargadas ($loaded de $total).';
  }
}
