/// Metadata of an object: its ETag and the headers it was uploaded with.
class ObjectMetaModel {
  /// md5 of the content (without quotes), or `md5-N` for a multipart upload.
  final String etag;

  /// `Content-Type`, `x-amz-meta-*`… lowercased, as they were stored.
  final Map<String, String> headers;

  const ObjectMetaModel({required this.etag, this.headers = const {}});
}
