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
    this.prefix,
    this.delimiter,
    required this.objects,
    required this.commonPrefixes,
  });
}
