import 'dart:ui';

class BucketModel {
  final String name;
  final String? description;
  final int? color;
  final int objectCount;
  final int sizeBytes;
  final DateTime creationDate;

  /// Date of the most recently modified object; null if it is empty
  final DateTime? lastModified;

  BucketModel({
    required this.name,
    required this.objectCount,
    required this.sizeBytes,
    required this.creationDate,
    this.lastModified,
    this.description,
    this.color,
  });

  Color? get uiColor => color != null ? Color(color!) : null;
}
