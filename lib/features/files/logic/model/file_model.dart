import 'package:feather_io/feather.dart';

class FileModel implements Serializable {
  final String key;
  final int size;
  final DateTime lastModified;

  FileModel({
    required this.key,
    required this.size,
    required this.lastModified,
  });

  @override
  Object? toJson() {
    return {
      'key': key,
      'size_bytes': size,
      'last_modified': lastModified.toIso8601String(),
    };
  }
}
