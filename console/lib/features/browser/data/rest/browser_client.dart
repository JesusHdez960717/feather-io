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

  Future<ListObjectsResponse> listObjects({
    required String access,
    required String secret,
    required String bucket,
    String? prefix,
    String? delimiter,
  }) async {
    Response rawResponse = await dio.get(
      '$baseUrl/$bucket',
      queryParameters: {'prefix': ?prefix, 'delimiter': ?delimiter},
      options: options(access: access, secret: secret),
    );

    return ListObjectsResponse.fromJson(rawResponse.data);
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

//--- LIST OBJECTS RESPONSE ---
class ListObjectsResponse {
  final String bucketName;
  final String? prefix;
  final String? delimiter;
  final List<ObjectResponse> contents;
  final List<String> commonPrefixes;

  ListObjectsResponse({
    required this.bucketName,
    this.prefix,
    this.delimiter,
    required this.contents,
    required this.commonPrefixes,
  });

  factory ListObjectsResponse.fromJson(Map<String, dynamic> json) {
    return ListObjectsResponse(
      bucketName: json['name'],
      prefix: json['prefix'],
      delimiter: json['delimiter'],
      contents: (json['contents'] as List)
          .map((e) => ObjectResponse.fromJson(e))
          .toList(),
      commonPrefixes: List<String>.from(json['common_prefixes'] ?? []),
    );
  }
}

class ObjectResponse {
  final String key;
  final int sizeBytes;
  final DateTime lastModified;

  ObjectResponse({
    required this.key,
    required this.sizeBytes,
    required this.lastModified,
  });

  factory ObjectResponse.fromJson(Map<String, dynamic> json) {
    return ObjectResponse(
      key: json['key'],
      sizeBytes: json['size_bytes'],
      lastModified: DateTime.parse(json['last_modified']),
    );
  }
}
