import 'package:service/feather.dart';

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

  /// A `<Bucket>` of ListAllMyBucketsResult. Besides S3's name and creation
  /// date, the metadata of the service (ignored by S3 clients).
  XmlElement toXml() => XmlElement(
    'Bucket',
    elements: [
      XmlElement.leaf('Name', name),
      if (description != null) XmlElement.leaf('Description', description),
      if (color != null) XmlElement.leaf('Color', color),
      XmlElement.leaf('CreationDate', S3Xml.date(creationDate)),
      XmlElement.leaf('ObjectCount', objectCount),
      XmlElement.leaf('Size', size),
    ],
  );
}

/// ListBuckets: in JSON the list itself, in XML ListAllMyBucketsResult.
class BucketListModel implements XmlSerializable {
  final List<BucketModel> buckets;

  BucketListModel(this.buckets);

  List<BucketModel> toJson() => buckets;

  @override
  XmlElement toXml() => S3Xml.root('ListAllMyBucketsResult', [
    S3Xml.owner(),
    XmlElement('Buckets', elements: [for (final b in buckets) b.toXml()]),
  ]);
}
