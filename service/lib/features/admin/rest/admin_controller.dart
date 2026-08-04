import 'dart:convert';
import 'package:service/features/features.dart';
import 'package:service/feather.dart';

class AdminController {
  final FileManagementService fileManagement;
  final String adminPrefix = env.adminPrefix;

  Route get routing => Route.parent(
    path: '/$adminPrefix',
    routes: [
      Route.post(
        path: '/bucket/{bucket}/download',
        handler: downloadObjects,
        filterConfig: hasRole('admin').toFilterConfig(),
      ),
    ],
  );

  AdminController({required this.fileManagement});

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
