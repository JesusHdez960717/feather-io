import 'package:console/app_exporter.dart';

class BrowserRepo {
  final BrowserClient client;

  BrowserRepo(this.client);

  Future<List<BucketModel>> listBuckets({
    required String access,
    required String secret,
  }) async {
    try {
      final response = await client.listBuckets(access: access, secret: secret);
      return response.map((e) => e.toModel()).toList();
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<ListObjectsModel> listObjects({
    required String access,
    required String secret,
    required String bucket,
    String? prefix,
    String? delimiter,
  }) async {
    try {
      final response = await client.listObjects(
        access: access,
        secret: secret,
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
    required String access,
    required String secret,
    required String bucket,
    required List<String> keys,
  }) async {
    try {
      await client.deleteObjects(
        access: access,
        secret: secret,
        bucket: bucket,
        keys: keys,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> uploadObject({
    required String access,
    required String secret,
    required String bucket,
    required String key,
    required Stream<List<int>> data,
    required int length,
  }) async {
    try {
      await client.uploadObject(
        access: access,
        secret: secret,
        bucket: bucket,
        key: key,
        data: data,
        length: length,
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
