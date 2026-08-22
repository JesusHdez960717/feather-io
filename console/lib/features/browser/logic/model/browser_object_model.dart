class BrowserObjectModel {
  final String key;
  final int sizeBytes;
  final DateTime lastModified;

  BrowserObjectModel({
    required this.key,
    required this.sizeBytes,
    required this.lastModified,
  });
}

class ListObjectsModel {
  final String bucketName;
  final String? prefix;
  final String? delimiter;
  final List<BrowserObjectModel> objects;
  final List<String> commonPrefixes;

  ListObjectsModel({
    required this.bucketName,
    required this.objects, required this.commonPrefixes, this.prefix,
    this.delimiter,
  });
}

class ObjectDataModel {
  final List<int> bytes;
  final String? contentType;

  ObjectDataModel({
    required this.bytes,
    this.contentType,
  });
}
