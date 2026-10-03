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

  /// There are more items after this page
  final bool isTruncated;

  /// Token to request the next page
  final String? nextContinuationToken;

  /// Items of the folder across all pages
  final int totalKeys;

  ListObjectsModel({
    required this.bucketName,
    required this.objects,
    required this.commonPrefixes,
    this.prefix,
    this.delimiter,
    this.isTruncated = false,
    this.nextContinuationToken,
    this.totalKeys = 0,
  });
}

/// Headers of an object (`HEAD`), for its details panel
class ObjectInfoModel {
  final String? contentType;
  final int? sizeBytes;
  final DateTime? lastModified;

  ObjectInfoModel({this.contentType, this.sizeBytes, this.lastModified});
}

class ObjectDataModel {
  final List<int> bytes;
  final String? contentType;

  ObjectDataModel({required this.bytes, this.contentType});
}

/// Item (folder or object) as shown in the browser
class BrowserObjectWrapper {
  final String name;
  final bool isFolder;
  final int? size;
  final DateTime? lastModified;
  final String fullPath;

  BrowserObjectWrapper({
    required this.name,
    required this.isFolder,
    required this.fullPath,
    this.size,
    this.lastModified,
  });
}
