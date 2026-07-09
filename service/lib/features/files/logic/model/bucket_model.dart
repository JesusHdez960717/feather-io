import 'package:service/feather.dart';

class BucketModel implements Serializable {
  final String name;
  final int objectCount;
  final int size;
  final DateTime creationDate;

  BucketModel({
    required this.name,
    required this.objectCount,
    required this.size,
    required this.creationDate,
  });

  @override
  Object? toJson() {
    return {
      'name': name,
      'object_count': objectCount,
      'size_bytes': size,
      'creation_date': creationDate.toIso8601String(),
    };
  }
}
