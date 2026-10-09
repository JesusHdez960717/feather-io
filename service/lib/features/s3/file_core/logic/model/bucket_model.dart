class BucketModel {
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

  /// The example of the OpenAPI document.
  static final BucketModel example = BucketModel(
    name: 'photos',
    objectCount: 128,
    size: 734003200,
    creationDate: DateTime.utc(2026, 3, 14, 9, 30),
    lastModified: DateTime.utc(2026, 10, 2, 14, 22, 35),
    description: 'Photos of the 2026 trip',
    color: 0xFF2196F3,
  );

  Map<String, Object?> toJson() {
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
