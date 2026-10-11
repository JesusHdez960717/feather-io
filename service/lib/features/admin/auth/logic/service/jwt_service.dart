import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:service/feather.dart';

class JwtService {
  String get _jwtSecret => env.jwtSecret;

  late final SecretKey _secretKey;

  JwtService() {
    _secretKey = SecretKey(_jwtSecret);
  }

  String generateToken(Map<String, dynamic> payload) {
    final jwt = JWT(payload);
    return jwt.sign(_secretKey);
  }

  /// The payload of [token] if its signature is valid and it hasn't expired.
  /// A token without `exp` is rejected: the issued tokens always expire.
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, _secretKey);
      final payload = jwt.payload as Map<String, dynamic>;
      return payload['exp'] is int ? payload : null;
    } catch (_) {
      return null;
    }
  }
}
