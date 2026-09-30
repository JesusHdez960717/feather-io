import 'package:console/app_exporter.dart';
import 'package:mime/mime.dart';

///Categoria de un objeto segun su tipo MIME (deducido del nombre)
enum ObjectTypeFilter {
  image,
  video,
  audio,
  document,
  archive,
  other;

  static const _documentMimes = {
    'application/pdf',
    'application/json',
    'application/xml',
    'application/rtf',
    'application/msword',
    'application/vnd.ms-excel',
    'application/vnd.ms-powerpoint',
  };

  static ObjectTypeFilter of(String fileName) {
    final mime = lookupMimeType(fileName);
    if (mime == null) return other;
    if (mime.startsWith('image/')) return image;
    if (mime.startsWith('video/')) return video;
    if (mime.startsWith('audio/')) return audio;
    if (mime.startsWith('text/') ||
        _documentMimes.contains(mime) ||
        mime.startsWith('application/vnd.openxmlformats-officedocument.') ||
        mime.startsWith('application/vnd.oasis.opendocument.')) {
      return document;
    }
    if (mime.contains('zip') ||
        mime.contains('compressed') ||
        mime == 'application/x-tar' ||
        mime == 'application/gzip') {
      return archive;
    }
    return other;
  }
}

///Rango de tamaño: menos de 1 MB, de 1 a 100 MB, mas de 100 MB
enum ObjectSizeFilter {
  small,
  medium,
  large;

  static const int _mb = 1024 * 1024;

  bool matches(int bytes) => switch (this) {
    small => bytes < _mb,
    medium => bytes >= _mb && bytes <= 100 * _mb,
    large => bytes > 100 * _mb,
  };
}

///Antigüedad de la ultima modificacion
enum ObjectDateFilter {
  last24Hours,
  last7Days,
  last30Days,
  older;

  bool matches(DateTime lastModified, DateTime now) {
    final age = now.difference(lastModified);
    return switch (this) {
      last24Hours => age <= const Duration(hours: 24),
      last7Days => age <= const Duration(days: 7),
      last30Days => age <= const Duration(days: 30),
      older => age > const Duration(days: 30),
    };
  }
}

///Filtro de objetos del explorador. Dentro de un grupo basta con cumplir una
///opcion; entre grupos hay que cumplirlos todos. Las carpetas no tienen tipo,
///tamaño ni fecha, asi que se ocultan mientras haya algun filtro activo
class ObjectFilter {
  final Set<ObjectTypeFilter> types;
  final Set<ObjectSizeFilter> sizes;
  final Set<ObjectDateFilter> dates;

  const ObjectFilter({
    this.types = const {},
    this.sizes = const {},
    this.dates = const {},
  });

  static const ObjectFilter none = ObjectFilter();

  ///Opciones marcadas, para el badge del boton
  int get activeCount => types.length + sizes.length + dates.length;

  bool get isActive => activeCount > 0;

  bool matches(BrowserObjectWrapper wrapper, {DateTime? now}) {
    if (!isActive) return true;
    if (wrapper.isFolder) return false;

    if (types.isNotEmpty && !types.contains(ObjectTypeFilter.of(wrapper.name))) {
      return false;
    }
    final size = wrapper.size;
    if (sizes.isNotEmpty &&
        (size == null || !sizes.any((s) => s.matches(size)))) {
      return false;
    }
    final lastModified = wrapper.lastModified;
    final reference = now ?? DateTime.now();
    if (dates.isNotEmpty &&
        (lastModified == null ||
            !dates.any((d) => d.matches(lastModified, reference)))) {
      return false;
    }
    return true;
  }

  ObjectFilter copyWith({
    Set<ObjectTypeFilter>? types,
    Set<ObjectSizeFilter>? sizes,
    Set<ObjectDateFilter>? dates,
  }) {
    return ObjectFilter(
      types: types ?? this.types,
      sizes: sizes ?? this.sizes,
      dates: dates ?? this.dates,
    );
  }
}
