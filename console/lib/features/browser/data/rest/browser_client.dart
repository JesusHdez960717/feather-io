import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class BrowserClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  BrowserClient(super.dio);

  Future<ListObjectsResponse> listObjects({
    required String bucket,
    String? token,
    String? prefix,
    String? delimiter,
    int? maxKeys,
    String? continuationToken,
  }) async {
    Response rawResponse = await dio.get(
      '$baseUrl/$bucket',
      queryParameters: {
        'prefix': prefix,
        'delimiter': delimiter,
        'max-keys': ?maxKeys,
        'continuation-token': ?continuationToken,
      },
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

  /// Deletes a folder with all its content. With the S3 API, deleting the key
  /// `folder/` only removes the empty folder
  Future<void> deleteFolder({
    required String bucket,
    required String prefix,
    String? token,
  }) async {
    await dio.delete(
      '$baseUrl/${Environment.adminPrefix}/bucket/$bucket/folder',
      queryParameters: {'prefix': prefix},
      options: options(token: token),
    );
  }

  /// Creates an empty folder: a `PUT` of the key ending in `/` without a body
  Future<void> createFolder({
    required String bucket,
    required String key,
    String? token,
  }) async {
    await dio.put('$baseUrl/$bucket/$key', options: options(token: token));
  }

  /// CopyObject: copies `sourceBucket/sourceKey` to `bucket/key`
  Future<void> copyObject({
    required String sourceBucket,
    required String sourceKey,
    required String bucket,
    required String key,
    String? token,
  }) async {
    final requestOptions = options(token: token);
    requestOptions.headers!['x-amz-copy-source'] =
        '/$sourceBucket/${Uri.encodeComponent(sourceKey)}';
    await dio.put('$baseUrl/$bucket/$key', options: requestOptions);
  }

  /// Headers of the object without downloading it (`HEAD`)
  Future<ObjectInfoResponse> headObject({
    required String bucket,
    required String key,
    String? token,
  }) async {
    Response response = await dio.head(
      '$baseUrl/$bucket/$key',
      options: options(token: token),
    );
    return ObjectInfoResponse.fromHeaders(response.headers);
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

  /// Presigned URL to download [key] without credentials for [expiresIn]
  Future<PresignResponse> presign({
    required String bucket,
    required String key,
    required Duration expiresIn,
    String? token,
  }) async {
    final admin = Environment.adminPrefix;
    Response rawResponse = await dio.post(
      '$baseUrl/$admin/bucket/$bucket/presign',
      data: PresignRequest(key: key, expiresIn: expiresIn).toJson(),
      options: options(token: token),
    );
    return PresignResponse.fromJson(rawResponse.data);
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

//---------- PRESIGN REQUEST ----------
class PresignRequest {
  final String key;
  final Duration expiresIn;

  PresignRequest({required this.key, required this.expiresIn});

  Map<String, dynamic> toJson() {
    return {'key': key, 'expires_in': expiresIn.inSeconds};
  }
}

//---------- PRESIGN RESPONSE ----------
class PresignResponse {
  final String url;
  final DateTime expiresAt;

  PresignResponse({required this.url, required this.expiresAt});

  factory PresignResponse.fromJson(Map<String, dynamic> json) {
    return PresignResponse(
      url: json['url'],
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}

//---------- LIST OBJECTS RESPONSE ----------
class ListObjectsResponse {
  final String bucketName;
  final String? prefix;
  final String? delimiter;
  final List<ObjectResponse> contents;
  final List<String> commonPrefixes;
  final bool isTruncated;
  final String? nextContinuationToken;
  final int totalKeys;

  ListObjectsResponse({
    required this.bucketName,
    required this.contents,
    required this.commonPrefixes,
    required this.isTruncated,
    required this.totalKeys,
    this.prefix,
    this.delimiter,
    this.nextContinuationToken,
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
      isTruncated: json['is_truncated'] ?? false,
      nextContinuationToken: json['next_continuation_token'],
      totalKeys: json['total_keys'] ?? 0,
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

//---------- OBJECT INFO RESPONSE ----------
class ObjectInfoResponse {
  final String? contentType;
  final int? sizeBytes;
  final DateTime? lastModified;

  ObjectInfoResponse({this.contentType, this.sizeBytes, this.lastModified});

  factory ObjectInfoResponse.fromHeaders(Headers headers) {
    final length = headers.value('content-length');
    final modified = headers.value('last-modified');
    DateTime? lastModified;
    try {
      // HTTP date (RFC 7231): "Tue, 29 Sep 2026 18:04:51 GMT"
      lastModified = modified == null
          ? null
          : DateFormat(
              'EEE, dd MMM yyyy HH:mm:ss',
              'en_US',
            ).parseUtc(modified.replaceAll(' GMT', '')).toLocal();
    } catch (_) {
      lastModified = null;
    }
    return ObjectInfoResponse(
      contentType: headers.value('content-type'),
      sizeBytes: length == null ? null : int.tryParse(length),
      lastModified: lastModified,
    );
  }
}

//---------- OBJECT DATA RESPONSE ----------
class ObjectDataResponse {
  final List<int> bytes;
  final String? contentType;

  ObjectDataResponse({required this.bytes, this.contentType});
}
