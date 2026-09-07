import 'package:console/app_exporter.dart';

class BucketRepo {
  final BucketClient _client;

  BucketRepo(this._client);

  Future<void> createBucket({
    required String name,
    String? description,
    int? color,
    String? token,
  }) async {
    try {
      await _client.createBucket(
        name: name,
        request: BucketCreateRequest(description: description, color: color),
        token: token,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }

  Future<void> deleteBucket({
    required String name,
    String? token,
  }) async {
    try {
      await _client.deleteBucket(name: name, token: token);
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
  }
}
