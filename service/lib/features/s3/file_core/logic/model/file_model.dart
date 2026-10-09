import 'package:service/feather.dart';

class FileModel {
  final String key;
  final int size;
  final DateTime lastModified;

  /// md5 of the content (without quotes), or `md5-N` for a multipart upload.
  final String etag;

  FileModel({
    required this.key,
    required this.size,
    required this.lastModified,
    required this.etag,
  });

  Map<String, Object?> toJson() {
    return {
      'key': key,
      'size_bytes': size,
      'last_modified': lastModified.toIso8601String(),
      'etag': etag,
    };
  }
}

/// CopyObject: in JSON the copied object, in XML CopyObjectResult.
class CopyObjectResultModel implements XmlSerializable {
  final FileModel copied;

  CopyObjectResultModel(this.copied);

  Map<String, Object?> toJson() => copied.toJson();

  @override
  XmlElement toXml() => S3Xml.root('CopyObjectResult', [
    XmlElement.leaf('LastModified', S3Xml.date(copied.lastModified)),
    S3Xml.etag(copied.etag),
  ]);
}
