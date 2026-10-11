import 'package:service/feather.dart';

class AnonymousAccessService {
  final AccessRuleTableRepo accessRuleRepo;
  final BucketService buckets;

  AnonymousAccessService()
    : accessRuleRepo = AccessRuleTableRepo(di.find()),
      buckets = di.find();

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
    logger.info(
      'Anonymous access rule saved',
      fields: {
        'bucket': bucket,
        'prefix': model.prefix,
        'access': model.access.name,
      },
    );
  }

  Future<void> deleteRule({
    required String bucket,
    required String prefix,
  }) async {
    await _checkBucket(bucket);
    await accessRuleRepo.deleteRule(bucketName: bucket, prefix: prefix);
    logger.info(
      'Anonymous access rule deleted',
      fields: {'bucket': bucket, 'prefix': prefix},
    );
  }

  /// First rule of the bucket whose pattern matches [key], or null. See
  /// [matches] for the pattern semantics.
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

  /// Without `*` the rule is a prefix (`public/` covers everything that starts
  /// with it); with `*` the whole key must match (`photos/*.jpg` covers
  /// `photos/a.jpg` but not `photos/a.jpg.zip`). `*` stands for any characters,
  /// `/` included; everything else is compared literally.
  static bool matches(String pattern, String key) {
    // S3 keys don't start with '/', so we normalize the pattern
    final normalized = pattern.startsWith('/') ? pattern.substring(1) : pattern;
    final regexSource = normalized.split('*').map(RegExp.escape).join('.*');
    final anchor = normalized.contains('*') ? r'$' : '';
    return RegExp('^$regexSource$anchor').hasMatch(key);
  }

  Future<List<AnonymousRuleModel>> _rules(String bucket) async {
    final rules = await accessRuleRepo.getRulesByBucket(bucket: bucket);
    return rules.map((e) => AnonymousRuleModel(e.prefix, e.access)).toList();
  }

  Future<void> _checkBucket(String bucket) async {
    if (!await buckets.bucketExists(bucket)) {
      throw S3Exception.noSuchBucket(bucket);
    }
  }
}
