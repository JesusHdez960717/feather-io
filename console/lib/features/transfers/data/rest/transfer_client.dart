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

//---------- DOWNLOAD OBJECTS REQUEST ----------
class DownloadObjectsRequest {
  final List<String> keys;

  DownloadObjectsRequest({required this.keys});

  Map<String, dynamic> toJson() => {'keys': keys};
}
