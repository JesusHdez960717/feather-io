import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class TransferClient extends BaseClient {
  @override
  String get baseUrl => Environment.serviceUrl;

  TransferClient(super.dio);

  ///En web, Dio limita toda la peticion a conexion + recepcion (20 s): una
  ///subida o una descarga larga lo superaria. Sin limite; quien la lanza puede
  ///cancelarla
  Options _longOptions(String? token) => options(token: token)
      .copyWith(connectTimeout: Duration.zero, receiveTimeout: Duration.zero);

  ///Sube un objeto (`PUT`) avisando del progreso con [onProgress]
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

    await dio.put(
      '$baseUrl/$bucket/$key',
      data: data,
      options: requestOptions,
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
  }

  ///CreateMultipartUpload: devuelve el `uploadId` de la subida
  Future<String> createMultipart({
    required String bucket,
    required String key,
    required CancelToken cancelToken,
    String? token,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '$baseUrl/$bucket/$key',
      queryParameters: {'uploads': ''},
      options: options(token: token),
      cancelToken: cancelToken,
    );
    return CreateMultipartResponse.fromJson(response.data!).uploadId;
  }

  ///UploadPart: sube la parte [partNumber] y devuelve su ETag (cabecera)
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

  ///CompleteMultipartUpload: el servicio junta las partes en el objeto
  Future<void> completeMultipart({
    required String bucket,
    required String key,
    required String uploadId,
    required List<CompleteMultipartPart> parts,
    required CancelToken cancelToken,
    String? token,
  }) async {
    //juntar varios GB en el servicio puede tardar: sin limite de tiempo
    await dio.post(
      '$baseUrl/$bucket/$key',
      queryParameters: {'uploadId': uploadId},
      data: CompleteMultipartRequest(parts: parts).toJson(),
      options: _longOptions(token),
      cancelToken: cancelToken,
    );
  }

  ///AbortMultipartUpload: borra la subida y sus partes
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

  ///Descarga [keys] de [bucket] en un zip. [onProgress] recibe `total` -1
  ///mientras el servicio prepara el zip y aun no ha enviado su tamaño
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
