import 'package:service/feather.dart';

class AdminController {
  final FileManagementService fileManagement;
  final JwtService jwtService;
  final String adminPrefix = env.adminPrefix;

  Route get routing => Route.parent(
    path: '/$adminPrefix',
    filterConfig: [JwtFilter()].toFilterConfig(),
    routes: [
      Route.post(key: 'admin.login', path: '/login', handler: login),
      Route.post(
        key: 'admin.bucket.download',
        path: '/bucket/{bucket}/download',
        handler: downloadObjects,
        filterConfig: FilterConfig([
          AuthFilter(rules: hasPermission('admin.bucket.download')),
        ]),
      ),
    ],
  );

  AdminController({required this.fileManagement, required this.jwtService});

  Future<ResponseEntity> login(RequestEntity request) async {
    try {
      final loginReq = (await request.body<LoginRequest>())!;

      if (loginReq.access != env.access || loginReq.secret != env.secret) {
        throw ForbiddenException(body: 'Invalid credentials');
      }

      final expiresAfter = Duration(hours: 12);
      final expireAt = DateTime.now().add(expiresAfter);

      final token = jwtService.generateToken({
        'sub': loginReq.access,
        'roles': ['admin'],
        'permissions': [
          //admin stuff
          'admin.bucket.download',
          //s3 stuff
          's3.list-buckets',
          's3.list-objects',
          's3.put-object',
          's3.get-object',
          's3.delete-object',
          's3.multi-delete-objects',
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

  Future<ResponseEntity> downloadObjects(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    try {
      DownloadObjectsRequest downloadRequest = (await request
          .body<DownloadObjectsRequest>())!;

      final zipData = await fileManagement.zipObjects(
        bucketName: bucketName,
        keys: downloadRequest.keys,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'download_$timestamp.zip';

      return ResponseEntity.ok(
        body: Stream.fromIterable([zipData]),
        headers: {
          'content-type': 'application/zip',
          'content-disposition': 'attachment; filename="$fileName"',
          'content-length': zipData.length.toString(),
        },
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw BadRequestException(body: 'Invalid request: $e');
    }
  }
}
