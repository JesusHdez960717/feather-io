import 'package:service/feather.dart';

class AnonymousAccessService {
  final AccessRuleTableRepo accessRuleRepo;

  AnonymousAccessService() : accessRuleRepo = AccessRuleTableRepo(di.find());

  Future<List<AnonymousRuleModel>> getRules({required String bucket}) async {
    final rules = await accessRuleRepo.getRulesByBucket(bucket: bucket);
    return rules.map((e) => AnonymousRuleModel(e.prefix, e.access)).toList();
  }
}
