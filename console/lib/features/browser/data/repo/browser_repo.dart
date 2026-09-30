import 'package:console/app_exporter.dart';

class BrowserRepo {
  final BrowserClient client;

  BrowserRepo(this.client);

  Future<ListObjectsModel> listObjects({
    required String bucket,
    String? token,
    String? prefix,
    String? delimiter,
    int? maxKeys,
    String? continuationToken,
  }) async {
    try {
      final response = await client.listObjects(
        token: token,
        bucket: bucket,
        prefix: prefix,
        delimiter: delimiter,
        maxKeys: maxKeys,
        continuationToken: continuationToken,
      );
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> deleteObjects({
    required String bucket,
    required List<String> keys,
    String? token,
  }) async {
    try {
      await client.deleteObjects(token: token, bucket: bucket, keys: keys);
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> uploadObject({
    required String bucket,
    required String key,
    required Stream<List<int>> data,
    required int length,
    String? token,
  }) async {
    try {
      await client.uploadObject(
        token: token,
        bucket: bucket,
        key: key,
        data: data,
        length: length,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> createFolder({
    required String bucket,
    required String key,
    String? token,
  }) async {
    try {
      await client.createFolder(bucket: bucket, key: key, token: token);
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> copyObject({
    required String sourceBucket,
    required String sourceKey,
    required String bucket,
    required String key,
    String? token,
  }) async {
    try {
      await client.copyObject(
        sourceBucket: sourceBucket,
        sourceKey: sourceKey,
        bucket: bucket,
        key: key,
        token: token,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<ObjectInfoModel> headObject({
    required String bucket,
    required String key,
    String? token,
  }) async {
    try {
      final response = await client.headObject(
        bucket: bucket,
        key: key,
        token: token,
      );
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<ObjectDataModel> getObject({
    required String bucket,
    required String key,
    String? token,
  }) async {
    try {
      final response = await client.getObject(
        token: token,
        bucket: bucket,
        key: key,
      );
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<SharedLinkModel> presign({
    required String bucket,
    required String key,
    required Duration expiresIn,
    String? token,
  }) async {
    try {
      final response = await client.presign(
        bucket: bucket,
        key: key,
        expiresIn: expiresIn,
        token: token,
      );
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<List<int>> download({
    required String bucket,
    required List<String> keys,
    String? token,
  }) async {
    try {
      return await client.download(token: token, bucket: bucket, keys: keys);
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }
}

extension ListObjectsResponseMapping on ListObjectsResponse {
  ListObjectsModel toModel() {
    return ListObjectsModel(
      bucketName: bucketName,
      prefix: prefix,
      delimiter: delimiter,
      objects: contents.map((e) => e.toModel()).toList(),
      commonPrefixes: commonPrefixes,
      isTruncated: isTruncated,
      nextContinuationToken: nextContinuationToken,
      totalKeys: totalKeys,
    );
  }
}

extension ObjectResponseMapping on ObjectResponse {
  BrowserObjectModel toModel() {
    return BrowserObjectModel(
      key: key,
      sizeBytes: sizeBytes,
      lastModified: lastModified,
    );
  }
}

extension PresignResponseMapping on PresignResponse {
  SharedLinkModel toModel() {
    return SharedLinkModel(url: url, expiresAt: expiresAt.toLocal());
  }
}

extension ObjectInfoResponseMapping on ObjectInfoResponse {
  ObjectInfoModel toModel() {
    return ObjectInfoModel(
      contentType: contentType,
      sizeBytes: sizeBytes,
      lastModified: lastModified,
    );
  }
}

extension ObjectDataResponseMapping on ObjectDataResponse {
  ObjectDataModel toModel() {
    return ObjectDataModel(bytes: bytes, contentType: contentType);
  }
}
