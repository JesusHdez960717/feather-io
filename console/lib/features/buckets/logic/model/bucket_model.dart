import 'dart:ui';

class BucketModel {
  final String name;
  final String? description;
  final int? color;
  final int objectCount;
  final int sizeBytes;
  final DateTime creationDate;

  BucketModel({
    required this.name,
    required this.objectCount,
    required this.sizeBytes,
    required this.creationDate,
    this.description,
    this.color,
  });

  Color? get uiColor => color != null ? Color(color!) : null;
}
