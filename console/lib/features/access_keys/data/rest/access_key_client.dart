import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class AccessKeyClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  AccessKeyClient(super.dio);

  String get _keysUrl => '$baseUrl/${Environment.adminPrefix}/access-keys';

  Future<AccessKeyListResponse> listKeys({String? token}) async {
    Response rawResponse = await dio.get(
      _keysUrl,
      options: options(token: token),
    );
    return AccessKeyListResponse.fromJson(rawResponse.data);
  }

  Future<AccessKeyResponse> createKey({
    required AccessKeyRequest request,
    String? token,
  }) async {
    Response rawResponse = await dio.post(
      _keysUrl,
      data: request.toJson(),
      options: options(token: token),
    );
    return AccessKeyResponse.fromJson(rawResponse.data);
  }

  Future<AccessKeyResponse> updateKey({
    required String id,
    required AccessKeyRequest request,
    String? token,
  }) async {
    Response rawResponse = await dio.put(
      '$_keysUrl/$id',
      data: request.toJson(),
      options: options(token: token),
    );
    return AccessKeyResponse.fromJson(rawResponse.data);
  }

  Future<AccessKeyResponse> regenerateSecret({
    required String id,
    String? token,
  }) async {
    Response rawResponse = await dio.post(
      '$_keysUrl/$id/secret',
      options: options(token: token),
    );
    return AccessKeyResponse.fromJson(rawResponse.data);
  }

  Future<void> deleteKey({required String id, String? token}) async {
    await dio.delete('$_keysUrl/$id', options: options(token: token));
  }
}

//---------- ACCESS KEY REQUEST ----------
class AccessKeyRequest {
  final String name;
  final bool enabled;

  /// Level on every bucket; null when the key only reaches [buckets]
  final String? allBuckets;
  final List<AccessKeyGrantDto> buckets;
  final DateTime? expiresAt;

  AccessKeyRequest({
    required this.name,
    required this.enabled,
    required this.allBuckets,
    required this.buckets,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'enabled': enabled,
      'all_buckets': allBuckets,
      'buckets': buckets.map((e) => e.toJson()).toList(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
    };
  }
}

//---------- ACCESS KEY GRANT REQUEST/RESPONSE ----------
class AccessKeyGrantDto {
  final String bucket;
  final String access;

  AccessKeyGrantDto({required this.bucket, required this.access});

  factory AccessKeyGrantDto.fromJson(Map<String, dynamic> json) {
    return AccessKeyGrantDto(bucket: json['bucket'], access: json['access']);
  }

  Map<String, dynamic> toJson() => {'bucket': bucket, 'access': access};
}

//---------- ACCESS KEY RESPONSE ----------
class AccessKeyResponse {
  final String accessKeyId;
  final String name;
  final bool enabled;
  final bool expired;
  final String? allBuckets;
  final List<AccessKeyGrantDto> buckets;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  /// Only right after creating the key or regenerating its secret
  final String? secretAccessKey;

  AccessKeyResponse({
    required this.accessKeyId,
    required this.name,
    required this.enabled,
    required this.expired,
    required this.allBuckets,
    required this.buckets,
    required this.expiresAt,
    required this.createdAt,
    required this.lastUsedAt,
    required this.secretAccessKey,
  });

  factory AccessKeyResponse.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.parse(json[key]).toLocal();
    return AccessKeyResponse(
      accessKeyId: json['access_key_id'],
      name: json['name'],
      enabled: json['enabled'],
      expired: json['expired'],
      allBuckets: json['all_buckets'],
      buckets: (json['buckets'] as List)
          .map((e) => AccessKeyGrantDto.fromJson(e))
          .toList(),
      expiresAt: date('expires_at'),
      createdAt: date('created_at')!,
      lastUsedAt: date('last_used_at'),
      secretAccessKey: json['secret_access_key'],
    );
  }
}

//---------- ACCESS KEY LIST RESPONSE ----------
class AccessKeyListResponse {
  final String rootAccessKeyId;
  final List<AccessKeyResponse> keys;

  AccessKeyListResponse({required this.rootAccessKeyId, required this.keys});

  factory AccessKeyListResponse.fromJson(Map<String, dynamic> json) {
    return AccessKeyListResponse(
      rootAccessKeyId: json['root_access_key_id'],
      keys: (json['keys'] as List)
          .map((e) => AccessKeyResponse.fromJson(e))
          .toList(),
    );
  }
}
