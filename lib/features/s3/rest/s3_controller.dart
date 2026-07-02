import 'package:feather_io/features/features.dart';
import 'package:mime/mime.dart';
import 'package:winter/winter.dart';

class S3Controller {
  final FileManagementService fileManagement;

  Route get routing => Route.parent(
    path: '/s3',
    routes: [
      Route.put(
        path: '/{key|.*}',
        handler: uploadFile,
        filterConfig: FilterConfig([AuthFilter(rules: hasRole('admin'))]),
      ),
      Route.get(path: '/list', handler: listFiles),
      Route.get(path: '/{key|.*}', key: 's3.get-file', handler: getFile),
      Route.delete(path: '/{key|.*}', handler: deleteFile),
    ],
  );

  S3Controller({required this.fileManagement});

  Future<ResponseEntity> uploadFile(RequestEntity request) async {
    await fileManagement.uploadFile(
      bucketName: 'bucket',
      key: request.pathParams['key']!,
      binary: request.read(),
    );

    return ResponseEntity.ok(body: 'Archivo subido correctamente.');
  }

  Future<ResponseEntity> listFiles(RequestEntity request) async {
    final filesList = await fileManagement.listFiles(bucketName: 'bucket');

    // Devolvemos la respuesta como JSON
    return ResponseEntity.ok(body: filesList);
  }

  Future<ResponseEntity> getFile(RequestEntity request) async {
    final key = request.pathParams['key']!;

    final file = await fileManagement.getFile(bucketName: 'bucket', key: key);

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
    final key = request.pathParams['key']!;

    await fileManagement.deleteFile(bucketName: 'bucket', key: key);

    return ResponseEntity.ok(body: 'Archivo "$key" eliminado correctamente.');
  }
}
