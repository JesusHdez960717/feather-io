import 'package:service/feather.dart';

/// Presigned URL to download an object without credentials until [expiresAt].
class PresignedUrlModel implements Serializable {
  final String url;
  final DateTime expiresAt;

  PresignedUrlModel({required this.url, required this.expiresAt});

  @override
  Object? toJson() {
    return {'url': url, 'expires_at': expiresAt.toIso8601String()};
  }
}
