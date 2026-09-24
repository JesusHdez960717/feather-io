import 'package:service/feather.dart';

class AdminController {
  final String adminPrefix = env.adminPrefix;

  final AuthController authController;
  final AnonymousAccessController anonymousAccessController;

  Route get routing =>
      Route.parent(
        path: '/$adminPrefix',
        filterConfig: [S3BucketNameFilter(), JwtFilter()].toFilterConfig(),
        routes: [
          Route.post(
            key: 'admin.auth.login',
            path: '/login',
            handler: authController.login,
          ),
          Route.get(
            key: 'admin.bucket.anonymous-access.get-rules',
            path: '/bucket/{bucket}/anonymous-access',
            handler: anonymousAccessController.getRules,
            filterConfig: FilterConfig([
              AuthFilter(
                rules: hasPermission('admin.bucket.anonymous-access.get-rules'),
              ),
            ]),
          ),
          Route.post(
            key: 'admin.bucket.anonymous-access.write-rule',
            path: '/bucket/{bucket}/anonymous-access',
            handler: anonymousAccessController.createRule,
            filterConfig: FilterConfig([
              AuthFilter(
                rules: hasPermission(
                    'admin.bucket.anonymous-access.write-rule'),
              ),
            ]),
          ),
          Route.delete(
            key: 'admin.bucket.anonymous-access.delete-rule',
            path: '/bucket/{bucket}/anonymous-access',
            handler: anonymousAccessController.deleteRule,
            filterConfig: FilterConfig([
              AuthFilter(
                rules: hasPermission(
                    'admin.bucket.anonymous-access.delete-rule'),
              ),
            ]),
          ),
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

  AdminController()
      : fileManagement = di.find(),
        authController = AuthController(),
        anonymousAccessController = AnonymousAccessController();

  final FileManagementService fileManagement;

  Future<ResponseEntity> downloadObjects(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    try {
      DownloadObjectsRequest downloadRequest = (await request
          .body<DownloadObjectsRequest>());

      final zipFile = await fileManagement.zipObjects(
        bucketName: bucketName,
        keys: downloadRequest.keys,
      );

      final timestamp = DateTime
          .now()
          .millisecondsSinceEpoch;
      final fileName = 'download_$timestamp.zip';

      return ResponseEntity.ok(
        body: fileManagement.openAndDeleteTemp(zipFile),
        headers: {
          'content-type': 'application/zip',
          'content-disposition': 'attachment; filename="$fileName"',
          'content-length': (await zipFile.length()).toString(),
        },
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw BadRequestException(body: 'Invalid request: $e');
    }
  }
}
