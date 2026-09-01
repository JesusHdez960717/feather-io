import 'package:service/feather.dart';

class AnonymousAccessService {
  final AccessRuleTableRepo accessRuleRepo;

  AnonymousAccessService() : accessRuleRepo = AccessRuleTableRepo(di.find());

  Future<List<AnonymousRuleModel>> getRules({required String bucket}) async {
    final rules = await accessRuleRepo.getRulesByBucket(bucket: bucket);
    return rules.map((e) => AnonymousRuleModel(e.prefix, e.access)).toList();
  }

  Future<void> createRule({
    required String bucket,
    required AnonymousRuleModel model,
  }) async {
    await accessRuleRepo.save(bucketName: bucket, model: model);
  }

  Future<void> deleteRule({
    required String bucket,
    required String prefix,
  }) async {
    await accessRuleRepo.deleteRule(bucketName: bucket, prefix: prefix);
  }
}
