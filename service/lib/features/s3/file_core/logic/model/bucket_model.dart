import 'package:service/feather.dart';

class BucketModel implements Serializable {
  final String name;
  final int objectCount;
  final int size;
  final DateTime creationDate;

  /// Date of the most recently modified object; null if the bucket is empty.
  final DateTime? lastModified;
  final String? description;
  final int? color;

  BucketModel({
    required this.name,
    required this.objectCount,
    required this.size,
    required this.creationDate,
    this.lastModified,
    this.description,
    this.color,
  });

  @override
  Object? toJson() {
    return {
      'name': name,
      'object_count': objectCount,
      'size_bytes': size,
      'creation_date': creationDate.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'description': description,
      'color': color,
    };
  }
}
