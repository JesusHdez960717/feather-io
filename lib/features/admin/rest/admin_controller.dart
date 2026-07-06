import 'package:feather_io/features/features.dart';
import 'package:mime/mime.dart';
import 'package:winter/winter.dart';

class AdminController {
  final FileManagementService fileManagement;

  Route get routing => Route.parent(
    path: '/admin',
    routes: [
      Route.post(path: '/{key|.*}', handler: uploadFile),
    ],
  );

  AdminController({required this.fileManagement});

  Future<ResponseEntity> uploadFile(RequestEntity request) async {


    return ResponseEntity.ok(body: 'File uploaded successfully.');
  }

}
