import 'package:feather_io/features/features.dart';
import 'package:mime/mime.dart';
import 'package:winter/winter.dart';

class S3Controller {
  final FileManagementService fileManagement;

  Route get routing => Route.parent(
    path: '/{bucket}',
    routes: [
      Route.put(
        path: '/{key|.*}',
        handler: uploadFile,
        filterConfig: AuthFilter(rules: hasRole('admin')).toFilterConfig(),
      ),
      Route.get(
        path: '/list',
        handler: listFiles,
        filterConfig: hasRole('admin').toFilterConfig(),
      ),
      Route.get(path: '/{key|.*}', key: 's3.get-file', handler: getFile),
      Route.delete(
        path: '/{key|.*}',
        handler: deleteFile,
        filterConfig: hasRole('admin').toFilterConfig(),
      ),
    ],
  );

  S3Controller({required this.fileManagement});

  Future<ResponseEntity> uploadFile(RequestEntity request) async {
    await fileManagement.uploadFile(
      bucketName: request.pathParams['bucket']!,
      key: request.pathParams['key']!,
      binary: request.read(),
    );

    return ResponseEntity.ok(body: 'File uploaded successfully.');
  }

  Future<ResponseEntity> listFiles(RequestEntity request) async {
    final filesList = await fileManagement.listFiles(
      bucketName: request.pathParams['bucket']!,
    );

    // Devolvemos la respuesta como JSON
    return ResponseEntity.ok(body: filesList);
  }

  Future<ResponseEntity> getFile(RequestEntity request) async {
    final file = await fileManagement.getFile(
      bucketName: request.pathParams['bucket']!,
      key: request.pathParams['key']!,
    );

    final contentType =
        lookupMimeType(file.path) ?? MediaType.applicationOctetStream;

    return ResponseEntity.ok(
      body: file.openRead(),
      headers: {
        HttpHeaders.contentType: contentType,
        HttpHeaders.contentLength: (await file.length()).toString(),
      },
    );
  }

  Future<ResponseEntity> deleteFile(RequestEntity request) async {
    await fileManagement.deleteFile(
      bucketName: request.pathParams['bucket']!,
      key: request.pathParams['key']!,
    );

    return ResponseEntity.ok(body: 'File deleted successfully.');
  }
}
