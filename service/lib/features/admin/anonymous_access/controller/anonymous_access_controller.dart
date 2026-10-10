import 'dart:async';

import 'package:service/feather.dart';

class AnonymousAccessController {
  final AnonymousAccessService anonymousAccessService;

  AnonymousAccessController()
    : anonymousAccessService = AnonymousAccessService();

  Future<ResponseEntity> getRules(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    List<AnonymousRuleModel> rules = await anonymousAccessService.getRules(
      bucket: bucketName,
    );

    return ResponseEntity.ok(body: rules);
  }

  Future<ResponseEntity> createRule(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    final requestBody = await request.body<CreateRuleRequest>();
    AnonymousRuleModel model = requestBody.toModel();

    await anonymousAccessService.createRule(bucket: bucketName, model: model);

    return ResponseEntity.ok(body: model);
  }

  Future<ResponseEntity> deleteRule(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    final body = await request.body<DeleteRuleRequest>();

    await anonymousAccessService.deleteRule(
      bucket: bucketName,
      prefix: body.prefix!,
    );

    return ResponseEntity.ok();
  }
}
