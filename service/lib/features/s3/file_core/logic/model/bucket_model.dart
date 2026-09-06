import 'package:service/feather.dart';

class BucketModel implements Serializable {
  final String name;
  final String? description;
  final int color;
  final int objectCount;
  final int size;
  final DateTime creationDate;

  BucketModel({
    required this.name,
    this.description,
    this.color = 0,
    required this.objectCount,
    required this.size,
    required this.creationDate,
  });

  @override
  Object? toJson() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'object_count': objectCount,
      'size_bytes': size,
      'creation_date': creationDate.toIso8601String(),
    };
  }
}
