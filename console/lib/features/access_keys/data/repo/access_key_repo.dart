import 'package:console/app_exporter.dart';

class AccessKeyRepo {
  final AccessKeyClient _client;

  AccessKeyRepo(this._client);

  Future<AccessKeyListModel> listKeys({String? token}) async {
    try {
      final response = await _client.listKeys(token: token);
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  /// The result carries the secret, which is never shown again
  Future<AccessKeyModel> createKey({
    required AccessKeyDraft draft,
    String? token,
  }) async {
    try {
      final response = await _client.createKey(
        request: draft.toRequest(),
        token: token,
      );
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<AccessKeyModel> updateKey({
    required String id,
    required AccessKeyDraft draft,
    String? token,
  }) async {
    try {
      final response = await _client.updateKey(
        id: id,
        request: draft.toRequest(),
        token: token,
      );
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  /// The result carries the new secret; the old one stops working
  Future<AccessKeyModel> regenerateSecret({
    required String id,
    String? token,
  }) async {
    try {
      final response = await _client.regenerateSecret(id: id, token: token);
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> deleteKey({required String id, String? token}) async {
    try {
      await _client.deleteKey(id: id, token: token);
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }
}

extension AccessKeyResponseMapping on AccessKeyResponse {
  AccessKeyModel toModel() {
    return AccessKeyModel(
      id: accessKeyId,
      name: name,
      enabled: enabled,
      expired: expired,
      allBuckets: allBuckets == null
          ? null
          : AccessKeyLevel.values.byName(allBuckets!),
      grants: buckets
          .map(
            (e) => AccessKeyGrantModel(
              bucket: e.bucket,
              access: AccessKeyLevel.values.byName(e.access),
            ),
          )
          .toList(),
      expiresAt: expiresAt,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
      secret: secretAccessKey,
    );
  }
}

extension AccessKeyListResponseMapping on AccessKeyListResponse {
  AccessKeyListModel toModel() {
    return AccessKeyListModel(
      rootAccessKeyId: rootAccessKeyId,
      keys: keys.map((e) => e.toModel()).toList(),
    );
  }
}

extension AccessKeyDraftMapping on AccessKeyDraft {
  AccessKeyRequest toRequest() {
    return AccessKeyRequest(
      name: name,
      enabled: enabled,
      allBuckets: allBuckets?.name,
      buckets: grants
          .map(
            (e) => AccessKeyGrantDto(bucket: e.bucket, access: e.access.name),
          )
          .toList(),
      expiresAt: expiresAt,
    );
  }
}
