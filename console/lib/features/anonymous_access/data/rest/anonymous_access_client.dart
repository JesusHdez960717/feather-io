import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class AnonymousAccessClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  AnonymousAccessClient(super.dio);

  String _rulesUrl(String bucket) =>
      '$baseUrl/${Environment.adminPrefix}/bucket/$bucket/anonymous-access';

  Future<List<AnonymousRuleResponse>> getRules({
    required String bucket,
    String? token,
  }) async {
    Response rawResponse = await dio.get(
      _rulesUrl(bucket),
      options: options(token: token),
    );

    return (rawResponse.data as List)
        .map((e) => AnonymousRuleResponse.fromJson(e))
        .toList();
  }

  Future<void> createRule({
    required String bucket,
    required AnonymousRuleCreateRequest request,
    String? token,
  }) async {
    await dio.post(
      _rulesUrl(bucket),
      data: request.toJson(),
      options: options(token: token),
    );
  }

  Future<void> deleteRule({
    required String bucket,
    required AnonymousRuleDeleteRequest request,
    String? token,
  }) async {
    await dio.delete(
      _rulesUrl(bucket),
      data: request.toJson(),
      options: options(token: token),
    );
  }
}

//---------- ANONYMOUS RULE CREATE REQUEST ----------
class AnonymousRuleCreateRequest {
  final String prefix;
  final String access;

  AnonymousRuleCreateRequest({required this.prefix, required this.access});

  Map<String, dynamic> toJson() {
    return {'prefix': prefix, 'access': access};
  }
}

//---------- ANONYMOUS RULE DELETE REQUEST ----------
class AnonymousRuleDeleteRequest {
  final String prefix;

  AnonymousRuleDeleteRequest({required this.prefix});

  Map<String, dynamic> toJson() {
    return {'prefix': prefix};
  }
}

//---------- ANONYMOUS RULE RESPONSE ----------
class AnonymousRuleResponse {
  final String prefix;
  final String access;

  AnonymousRuleResponse({required this.prefix, required this.access});

  factory AnonymousRuleResponse.fromJson(Map<String, dynamic> json) {
    return AnonymousRuleResponse(
      prefix: json['prefix'],
      access: json['access'],
    );
  }
}
