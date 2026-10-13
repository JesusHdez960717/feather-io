import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class TransferClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  TransferClient(super.dio);

  /// On web, Dio limits the whole request to connect + receive (20 s): a long
  /// upload or download would exceed it. No limit; whoever starts it can
  /// cancel it
  Options _longOptions(String? token) => options(token: token)
      .copyWith(connectTimeout: Duration.zero, receiveTimeout: Duration.zero);

  /// The service stores the `Content-Type` of the upload as the object's and
  /// sends it back on GET; without this the JSON default of Dio would be kept
  static Map<String, String> _objectHeaders(String key) => {
    Headers.contentTypeHeader:
        lookupMimeType(key) ?? 'application/octet-stream',
  };

  /// Uploads an object (`PUT`) reporting progress through [onProgress]
  Future<void> putObject({
    required String bucket,
    required String key,
    required Stream<List<int>> data,
    required int length,
    required CancelToken cancelToken,
    void Function(int sent, int total)? onProgress,
    String? token,
  }) async {
    final requestOptions = _longOptions(token);
    requestOptions.headers!['content-length'] = length.toString();
    requestOptions.headers!.addAll(_objectHeaders(key));

    await dio.put(
      '$baseUrl/$bucket/$key',
      data: data,
      options: requestOptions,
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
  }

  /// CreateMultipartUpload: returns the upload's `uploadId`
  Future<String> createMultipart({
    required String bucket,
    required String key,
    required CancelToken cancelToken,
    String? token,
  }) async {
    final requestOptions = options(token: token);
    requestOptions.headers!.addAll(_objectHeaders(key));

    final response = await dio.post<Map<String, dynamic>>(
      '$baseUrl/$bucket/$key',
      queryParameters: {'uploads': ''},
      options: requestOptions,
      cancelToken: cancelToken,
    );
    return CreateMultipartResponse.fromJson(response.data!).uploadId;
  }

  /// UploadPart: uploads the part [partNumber] and returns its ETag (header)
  Future<String> uploadPart({
    required String bucket,
    required String key,
    required String uploadId,
    required int partNumber,
    required Stream<List<int>> data,
    required int length,
    required CancelToken cancelToken,
    void Function(int sent, int total)? onProgress,
    String? token,
  }) async {
    final requestOptions = _longOptions(token);
    requestOptions.headers!['content-length'] = length.toString();

    final response = await dio.put(
      '$baseUrl/$bucket/$key',
      queryParameters: {'partNumber': '$partNumber', 'uploadId': uploadId},
      data: data,
      options: requestOptions,
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
    return response.headers.value('etag') ?? '';
  }

  /// CompleteMultipartUpload: the service joins the parts into the object
  Future<void> completeMultipart({
    required String bucket,
    required String key,
    required String uploadId,
    required List<CompleteMultipartPart> parts,
    required CancelToken cancelToken,
    String? token,
  }) async {
    // joining several GB on the service can take a while: no time limit
    await dio.post(
      '$baseUrl/$bucket/$key',
      queryParameters: {'uploadId': uploadId},
      data: CompleteMultipartRequest(parts: parts).toJson(),
      options: _longOptions(token),
      cancelToken: cancelToken,
    );
  }

  /// AbortMultipartUpload: deletes the upload and its parts
  Future<void> abortMultipart({
    required String bucket,
    required String key,
    required String uploadId,
    String? token,
  }) async {
    await dio.delete(
      '$baseUrl/$bucket/$key',
      queryParameters: {'uploadId': uploadId},
      options: options(token: token),
    );
  }

  /// Downloads [keys] of [bucket] in a zip. [onProgress] gets `total` -1
  /// while the service builds the zip and hasn't sent its size yet
  Future<List<int>> downloadZip({
    required String bucket,
    required List<String> keys,
    required CancelToken cancelToken,
    void Function(int received, int total)? onProgress,
    String? token,
  }) async {
    final admin = Environment.adminPrefix;
    final response = await dio.post<List<int>>(
      '$baseUrl/$admin/bucket/$bucket/download',
      data: DownloadObjectsRequest(keys: keys).toJson(),
      options: _longOptions(token).copyWith(responseType: ResponseType.bytes),
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
    );
    return response.data!;
  }
}

//---------- CREATE MULTIPART RESPONSE ----------
class CreateMultipartResponse {
  final String uploadId;

  CreateMultipartResponse({required this.uploadId});

  factory CreateMultipartResponse.fromJson(Map<String, dynamic> json) {
    return CreateMultipartResponse(uploadId: json['upload_id']);
  }
}

//---------- COMPLETE MULTIPART REQUEST ----------
class CompleteMultipartPart {
  final int partNumber;
  final String etag;

  CompleteMultipartPart({required this.partNumber, required this.etag});

  Map<String, dynamic> toJson() => {'part_number': partNumber, 'etag': etag};
}

class CompleteMultipartRequest {
  final List<CompleteMultipartPart> parts;

  CompleteMultipartRequest({required this.parts});

  Map<String, dynamic> toJson() => {
    'parts': parts.map((part) => part.toJson()).toList(),
  };
}

//---------- DOWNLOAD OBJECTS REQUEST ----------
class DownloadObjectsRequest {
  final List<String> keys;

  DownloadObjectsRequest({required this.keys});

  Map<String, dynamic> toJson() => {'keys': keys};
}
