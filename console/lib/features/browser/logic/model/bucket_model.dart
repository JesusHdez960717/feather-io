class BucketModel {
  final String name;
  final int objectCount;
  final int sizeBytes;
  final DateTime creationDate;

  BucketModel({
    required this.name,
    required this.objectCount,
    required this.sizeBytes,
    required this.creationDate,
  });
}
