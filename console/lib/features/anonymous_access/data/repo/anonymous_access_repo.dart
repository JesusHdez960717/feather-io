import 'package:console/app_exporter.dart';

class AnonymousAccessRepo {
  final AnonymousAccessClient _client;

  AnonymousAccessRepo(this._client);

  Future<List<AnonymousRuleModel>> getRules({
    required String bucket,
    String? token,
  }) async {
    try {
      final response = await _client.getRules(bucket: bucket, token: token);
      return response.map((e) => e.toModel()).toList();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> createRule({
    required String bucket,
    required AnonymousRuleModel rule,
    String? token,
  }) async {
    try {
      await _client.createRule(
        bucket: bucket,
        request: AnonymousRuleCreateRequest(
          prefix: rule.prefix,
          access: rule.access.name,
        ),
        token: token,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> deleteRule({
    required String bucket,
    required String prefix,
    String? token,
  }) async {
    try {
      await _client.deleteRule(
        bucket: bucket,
        request: AnonymousRuleDeleteRequest(prefix: prefix),
        token: token,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }
}

extension AnonymousRuleResponseMapping on AnonymousRuleResponse {
  AnonymousRuleModel toModel() {
    return AnonymousRuleModel(
      prefix: prefix,
      access: AnonymousAccessType.values.byName(access),
    );
  }
}
