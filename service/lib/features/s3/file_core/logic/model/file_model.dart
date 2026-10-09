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
