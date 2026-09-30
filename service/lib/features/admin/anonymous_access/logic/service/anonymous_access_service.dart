import 'package:service/feather.dart';

class AnonymousAccessService {
  final AccessRuleTableRepo accessRuleRepo;
  final FileManagementService fileManagement;

  AnonymousAccessService()
    : accessRuleRepo = AccessRuleTableRepo(di.find()),
      fileManagement = di.find();

  Future<List<AnonymousRuleModel>> getRules({required String bucket}) async {
    await _checkBucket(bucket);
    return _rules(bucket);
  }

  Future<void> createRule({
    required String bucket,
    required AnonymousRuleModel model,
  }) async {
    await _checkBucket(bucket);
    await accessRuleRepo.save(bucketName: bucket, model: model);
  }

  Future<void> deleteRule({
    required String bucket,
    required String prefix,
  }) async {
    await _checkBucket(bucket);
    await accessRuleRepo.deleteRule(bucketName: bucket, prefix: prefix);
  }

  /// Primera regla del bucket cuyo patron coincide con [key]; null si ninguna.
  /// El patron es un prefijo relativo al bucket donde `*` es un comodin
  Future<AnonymousRuleModel?> findMatchingRule({
    required String bucket,
    required String key,
  }) async {
    if (!S3Validator.isValidBucketName(bucket)) return null;
    for (final rule in await _rules(bucket)) {
      if (matches(rule.prefix, key)) return rule;
    }
    return null;
  }

  static bool matches(String pattern, String key) {
    // S3 keys don't start with '/', so we normalize the pattern
    final normalized = pattern.startsWith('/') ? pattern.substring(1) : pattern;
    final regexSource = normalized
        .split('*')
        .map(RegExp.escape)
        .join('.*');
    return RegExp('^$regexSource').hasMatch(key);
  }

  Future<List<AnonymousRuleModel>> _rules(String bucket) async {
    final rules = await accessRuleRepo.getRulesByBucket(bucket: bucket);
    return rules.map((e) => AnonymousRuleModel(e.prefix, e.access)).toList();
  }

  Future<void> _checkBucket(String bucket) async {
    if (!await fileManagement.bucketExists(bucket)) {
      throw S3Exception.noSuchBucket(bucket);
    }
  }
}
