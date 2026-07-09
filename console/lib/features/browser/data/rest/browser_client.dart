import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class BrowserClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  BrowserClient(super.dio);

  Future<List<BucketResponse>> listBuckets({
    required String access,
    required String secret,
  }) async {
    Response rawResponse = await dio.get(
      baseUrl,
      options: options(access: access, secret: secret),
    );

    return (rawResponse.data as List)
        .map((e) => BucketResponse.fromJson(e))
        .toList();
  }
}

//--- BUCKET RESPONSE ---
class BucketResponse {
  final String name;
  final int objectCount;
  final int sizeBytes;
  final DateTime creationDate;

  BucketResponse({
    required this.name,
    required this.objectCount,
    required this.sizeBytes,
    required this.creationDate,
  });

  factory BucketResponse.fromJson(Map<String, dynamic> json) {
    return BucketResponse(
      name: json['name'],
      objectCount: json['object_count'],
      sizeBytes: json['size_bytes'],
      creationDate: DateTime.parse(json['creation_date']),
    );
  }
}
