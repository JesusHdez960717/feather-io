/// Presigned URL to download an object without credentials until [expiresAt].
class PresignedUrlModel {
  final String url;
  final DateTime expiresAt;

  PresignedUrlModel({required this.url, required this.expiresAt});

  /// The example of the OpenAPI document.
  static final PresignedUrlModel example = PresignedUrlModel(
    url: 'https://s3.example.com/photos/beach.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=…',
    expiresAt: DateTime.utc(2026, 10, 9, 13),
  );

  Map<String, Object?> toJson() {
    return {'url': url, 'expires_at': expiresAt.toIso8601String()};
  }
}
