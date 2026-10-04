import 'package:service/feather.dart';

class AccessKeyController {
  final AccessKeyService accessKeyService;

  AccessKeyController() : accessKeyService = AccessKeyService();

  Future<ResponseEntity> list(RequestEntity request) async {
    return ResponseEntity.ok(body: await accessKeyService.list());
  }

  Future<ResponseEntity> create(RequestEntity request) async {
    final body = await request.body<AccessKeyRequest>();
    body.validate().throwOnFailure();

    final key = await accessKeyService.create(body);
    return ResponseEntity(201, body: key);
  }

  Future<ResponseEntity> update(RequestEntity request) async {
    final body = await request.body<AccessKeyRequest>();
    body.validate().throwOnFailure();

    final key = await accessKeyService.update(request.pathParams['id']!, body);
    return ResponseEntity.ok(body: key);
  }

  Future<ResponseEntity> regenerateSecret(RequestEntity request) async {
    final key = await accessKeyService.regenerateSecret(
      request.pathParams['id']!,
    );
    return ResponseEntity.ok(body: key);
  }

  Future<ResponseEntity> delete(RequestEntity request) async {
    await accessKeyService.delete(request.pathParams['id']!);
    return ResponseEntity(204);
  }
}
