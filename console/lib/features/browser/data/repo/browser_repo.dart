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
