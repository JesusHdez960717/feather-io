import 'dart:convert';

import 'package:service/feather.dart';

class AuthController {
  final JwtService jwtService;
  final LoginRateLimiter rateLimiter;

  AuthController() : jwtService = di.find(), rateLimiter = di.find();

  Future<ResponseEntity> login(RequestEntity request) async {
    //por IP; detras de proxies propios, ver TRUSTED_PROXIES
    final client =
        request.clientIp(trustedProxies: env.trustedProxies) ?? 'unknown';
    final locked = rateLimiter.lockedFor(client);
    if (locked != null) {
      return ResponseEntity.tooManyRequests(
        body: 'Too many failed login attempts',
        retryAfter: (locked.inMilliseconds / 1000).ceil(),
      );
    }

    try {
      final loginReq = await request.body<LoginRequest>();

      //las dos comparaciones siempre, y sin cortar en el primer caracter
      //distinto: el tiempo de respuesta no da pistas
      final validAccess = _sameText(loginReq.access, env.access);
      final validSecret = _sameText(loginReq.secret, env.secret);
      if (!validAccess || !validSecret) {
        await rateLimiter.failed(client);
        throw ForbiddenException(body: 'Invalid credentials');
      }
      rateLimiter.succeeded(client);

      final expiresAfter = Duration(hours: 12);
      final expireAt = DateTime.now().add(expiresAfter);

      final token = jwtService.generateToken({
        'sub': loginReq.access,
        'roles': ['admin'],
        'permissions': [
          //s3 stuff
          's3.list-buckets',
          's3.create-bucket',
          's3.delete-bucket',
          's3.list-objects',
          's3.put-object',
          's3.get-object',
          's3.delete-object',
          's3.multi-delete-objects',
          //admin stuff
          'admin.bucket.get',
          'admin.bucket.update',
          'admin.bucket.presign',
          'admin.bucket.empty',
          'admin.bucket.delete-folder',
          'admin.bucket.download',
          'admin.bucket.anonymous-access.get-rules',
          'admin.bucket.anonymous-access.write-rule',
          'admin.bucket.anonymous-access.delete-rule',
        ],
        'exp': expireAt.millisecondsSinceEpoch ~/ 1000,
      });

      return ResponseEntity.ok(
        body: LoginResponse(
          accessToken: token,
          expiresIn: expiresAfter.inMilliseconds,
          expireAt: expireAt,
        ),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw BadRequestException(body: 'Invalid login request');
    }
  }

  /// Compara sin cortar en la primera diferencia
  static bool _sameText(String given, String expected) {
    final a = utf8.encode(given);
    final b = utf8.encode(expected);
    var diff = a.length ^ b.length;
    for (var i = 0; i < b.length; i++) {
      diff |= (i < a.length ? a[i] : 0) ^ b[i];
    }
    return diff == 0;
  }
}
