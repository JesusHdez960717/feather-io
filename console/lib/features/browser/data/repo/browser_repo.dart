import 'package:console/app_exporter.dart';

class BrowserRepo {
  final BrowserClient client;

  BrowserRepo(this.client);

  Future<List<BucketModel>> listBuckets({
    String? token,
  }) async {
    try {
      final response = await client.listBuckets(
        token: token,
      );
      return response.map((e) => e.toModel()).toList();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<ListObjectsModel> listObjects({
    required String bucket, String? token,
    String? prefix,
    String? delimiter,
  }) async {
    try {
      final response = await client.listObjects(
        token: token,
        bucket: bucket,
        prefix: prefix,
        delimiter: delimiter,
      );
      return response.toModel();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> deleteObjects({
    required String bucket, required List<String> keys, String? token,
  }) async {
    try {
      await client.deleteObjects(
        token: token,
        bucket: bucket,
        keys: keys,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> uploadObject({
    required String bucket, required String key, required Stream<List<int>> data, required int length, String? token,
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

  Future<ObjectDataModel> getObject({
    required String bucket, required String key, String? token,
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

  Future<List<int>> download({
    required String bucket, required List<String> keys, String? token,
  }) async {
    try {
      return await client.download(
        token: token,
        bucket: bucket,
        keys: keys,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }
}

extension BucketResponseMapping on BucketResponse {
  BucketModel toModel() {
    return BucketModel(
      name: name,
      objectCount: objectCount,
      sizeBytes: sizeBytes,
      creationDate: creationDate,
    );
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

extension ObjectDataResponseMapping on ObjectDataResponse {
  ObjectDataModel toModel() {
    return ObjectDataModel(
      bytes: bytes,
      contentType: contentType,
    );
  }
}
