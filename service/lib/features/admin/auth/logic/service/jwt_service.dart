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

  /// El payload de [token] si su firma es buena y no ha caducado. Sin `exp`
  /// no vale: los tokens que se emiten siempre caducan
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
