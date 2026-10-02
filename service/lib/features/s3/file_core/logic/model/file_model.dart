import 'package:service/feather.dart';

class FileModel implements Serializable {
  final String key;
  final int size;
  final DateTime lastModified;

  /// md5 del contenido (sin comillas), o `md5-N` si se subio por partes
  final String etag;

  FileModel({
    required this.key,
    required this.size,
    required this.lastModified,
    required this.etag,
  });

  @override
  Object? toJson() {
    return {
      'key': key,
      'size_bytes': size,
      'last_modified': lastModified.toIso8601String(),
      'etag': etag,
    };
  }
}
