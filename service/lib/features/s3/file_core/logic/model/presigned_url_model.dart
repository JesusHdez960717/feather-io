import 'package:service/feather.dart';

/// URL prefirmada para descargar un objeto sin credenciales hasta [expiresAt]
class PresignedUrlModel implements Serializable {
  final String url;
  final DateTime expiresAt;

  PresignedUrlModel({required this.url, required this.expiresAt});

  @override
  Object? toJson() {
    return {'url': url, 'expires_at': expiresAt.toIso8601String()};
  }
}
