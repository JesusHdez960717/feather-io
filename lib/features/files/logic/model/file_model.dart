import 'package:feather_io/feather.dart';

class FileModel implements Serializable {
  final String name;
  final int size;
  final DateTime lastModified;

  FileModel({
    required this.name,
    required this.size,
    required this.lastModified,
  });

  @override
  Object? toJson() {
    return {
      'name': name,
      'size_bytes': size,
      'last_modified': lastModified.toIso8601String(),
    };
  }
}
