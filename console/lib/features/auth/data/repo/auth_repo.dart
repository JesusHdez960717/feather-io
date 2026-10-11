import 'package:console/app_exporter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepo {
  static const String _tokenKey = 'auth.access_token';
  static const String _expireAtKey = 'auth.expire_at';

  final AuthClient client;
  final FlutterSecureStorage storage;

  AuthRepo(this.client, {required this.storage});

  Future<AuthModel> login({
    required String access,
    required String secret,
  }) async {
    try {
      final response = await client.login(
        LoginRequest(access: access, secret: secret),
      );
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  /// Keeps the session so a reload or a new tab doesn't ask to log in again
  Future<void> save(AuthModel auth) async {
    await storage.write(key: _tokenKey, value: auth.accessToken);
    await storage.write(
      key: _expireAtKey,
      value: auth.expireAt.toUtc().toIso8601String(),
    );
  }

  /// The saved session, or null if there is none or it already expired (then
  /// it is deleted)
  Future<AuthModel?> restore() async {
    try {
      final token = await storage.read(key: _tokenKey);
      final expireAt = DateTime.tryParse(
        await storage.read(key: _expireAtKey) ?? '',
      );
      if (token == null || expireAt == null) return null;
      final auth = AuthModel(accessToken: token, expireAt: expireAt.toLocal());
      if (auth.isExpired) {
        await clear();
        return null;
      }
      return auth;
    } catch (_) {
      // Unreadable storage (another browser profile key, cleared site data):
      // log in again
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await storage.delete(key: _tokenKey);
      await storage.delete(key: _expireAtKey);
    } catch (_) {}
  }
}

extension LoginResponseMapping on LoginResponse {
  AuthModel toModel() {
    return AuthModel(accessToken: accessToken, expireAt: expireAt);
  }
}
