import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class BrowserClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  BrowserClient(super.dio);

  Future<ListObjectsResponse> listObjects({
    required String bucket,
    String? token,
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
    required String bucket,
    required List<String> keys,
    String? token,
  }) async {
    await dio.post(
      '$baseUrl/$bucket',
      queryParameters: {'delete': ''},
      data: DeleteObjectsRequest(keys: keys).toJson(),
      options: options(token: token),
    );
  }

  Future<void> uploadObject({
    required String bucket,
    required String key,
    required Stream<List<int>> data,
    required int length,
    String? token,
  }) async {
    final requestOptions = options(token: token);
    requestOptions.headers!['content-length'] = length.toString();

    await dio.put('$baseUrl/$bucket/$key', data: data, options: requestOptions);
  }

  Future<ObjectDataResponse> getObject({
    required String bucket,
    required String key,
    String? token,
  }) async {
    Response<List<int>> response = await dio.get<List<int>>(
      '$baseUrl/$bucket/$key',
      options: options(token: token).copyWith(responseType: ResponseType.bytes),
    );
    return ObjectDataResponse(
      bytes: response.data!,
      contentType: response.headers.value('content-type'),
    );
  }

  Future<List<int>> download({
    required String bucket,
    required List<String> keys,
    String? token,
  }) async {
    final admin = Environment.adminPrefix;
    Response<List<int>> response = await dio.post<List<int>>(
      '$baseUrl/$admin/bucket/$bucket/download',
      data: DownloadObjectsRequest(keys: keys).toJson(),
      options: options(token: token).copyWith(responseType: ResponseType.bytes),
    );
    return response.data!;
  }
}

//---------- DELETE OBJECTS REQUEST ----------
class DeleteObjectsRequest {
  final List<String> keys;

  DeleteObjectsRequest({required this.keys});

  Map<String, dynamic> toJson() {
    return {
      'delete': {
        'objects': keys.map((k) => {'key': k}).toList(),
      },
    };
  }
}

//---------- DOWNLOAD OBJECTS REQUEST ----------
class DownloadObjectsRequest {
  final List<String> keys;

  DownloadObjectsRequest({required this.keys});

  Map<String, dynamic> toJson() {
    return {'keys': keys};
  }
}

//---------- LIST OBJECTS RESPONSE ----------
class ListObjectsResponse {
  final String bucketName;
  final String? prefix;
  final String? delimiter;
  final List<ObjectResponse> contents;
  final List<String> commonPrefixes;

  ListObjectsResponse({
    required this.bucketName,
    required this.contents,
    required this.commonPrefixes,
    this.prefix,
    this.delimiter,
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

//---------- OBJECT RESPONSE ----------
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

//---------- OBJECT DATA RESPONSE ----------
class ObjectDataResponse {
  final List<int> bytes;
  final String? contentType;

  ObjectDataResponse({required this.bytes, this.contentType});
}
