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
}
