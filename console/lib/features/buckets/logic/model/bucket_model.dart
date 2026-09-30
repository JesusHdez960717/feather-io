import 'dart:ui';

class BucketModel {
  final String name;
  final String? description;
  final int? color;
  final int objectCount;
  final int sizeBytes;
  final DateTime creationDate;

  ///Fecha del objeto modificado mas recientemente; null si esta vacio
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
