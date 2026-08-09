import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class BrowserClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  BrowserClient(super.dio);

  Future<List<BucketResponse>> listBuckets({
    String? token,
  }) async {
    Response rawResponse = await dio.get(
      baseUrl,
      options: options(token: token),
    );

    return (rawResponse.data as List)
        .map((e) => BucketResponse.fromJson(e))
        .toList();
  }

  Future<ListObjectsResponse> listObjects({
    String? token,
    required String bucket,
    String? prefix,
    String? delimiter,
  }) async {
    Response rawResponse = await dio.get(
      '$baseUrl/$bucket',
      queryParameters: {'prefix': prefix, 'delimiter': delimiter},
      options: options(token: token),
    );

    return ListObjectsResponse.fromJson(rawResponse.data);
  }

  Future<void> deleteObjects({
    String? token,
    required String bucket,
    required List<String> keys,
  }) async {
    await dio.post(
      '$baseUrl/$bucket',
      queryParameters: {'delete': ''},
      data: {
        'delete': {
          'objects': keys.map((k) => {'key': k}).toList(),
        },
      },
      options: options(token: token),
    );
  }

  Future<void> uploadObject({
    String? token,
    required String bucket,
    required String key,
    required Stream<List<int>> data,
    required int length,
  }) async {
    final uri = Uri.parse('$baseUrl/$bucket/$key');

    Map<String, dynamic> headers = {
      'content-length': length.toString(),
      if (token != null) 'Authorization': 'Bearer $token',
    };

    await dio.put(
      uri.toString(),
      data: data,
      options: Options(headers: headers),
    );
  }

  Future<ObjectDataResponse> getObject({
    String? token,
    required String bucket,
    required String key,
  }) async {
    Response<List<int>> response = await dio.get<List<int>>(
      '$baseUrl/$bucket/$key',
      options: options(
        token: token,
      ).copyWith(responseType: ResponseType.bytes),
    );
    return ObjectDataResponse(
      bytes: response.data!,
      contentType: response.headers.value('content-type'),
    );
  }

  Future<List<int>> download({
    String? token,
    required String bucket,
    required List<String> keys,
  }) async {
    final admin = Environment.adminPrefix;
    Response<List<int>> response = await dio.post<List<int>>(
      '$baseUrl/$admin/bucket/$bucket/download',
      data: {'keys': keys},
      options: options(
        token: token,
      ).copyWith(responseType: ResponseType.bytes),
    );
    return response.data!;
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

class ObjectDataResponse {
  final List<int> bytes;
  final String? contentType;

  ObjectDataResponse({
    required this.bytes,
    this.contentType,
  });
}
