import 'package:service/feather.dart';

class AuthController {
  final JwtService jwtService;

  AuthController() : jwtService = di.find();

  Future<ResponseEntity> login(RequestEntity request) async {
    try {
      final loginReq = await request.body<LoginRequest>();

      if (loginReq.access != env.access || loginReq.secret != env.secret) {
        throw ForbiddenException(body: 'Invalid credentials');
      }

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
      throw BadRequestException(body: 'Invalid login request: $e');
    }
  }
}
