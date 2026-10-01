import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

class TransferRepo {
  final TransferClient client;

  ///Transferencias en curso por id, para poder cancelarlas
  final Map<String, CancelToken> _cancelTokens = {};

  TransferRepo(this.client);

  Future<void> upload({
    required String id,
    required String bucket,
    required String key,
    required Stream<List<int>> data,
    required int length,
    void Function(int sent, int total)? onProgress,
    String? token,
  }) {
    return _track(
      id,
      (cancelToken) => client.putObject(
        token: token,
        bucket: bucket,
        key: key,
        data: data,
        length: length,
        cancelToken: cancelToken,
        onProgress: onProgress,
      ),
    );
  }

  Future<List<int>> downloadZip({
    required String id,
    required String bucket,
    required List<String> keys,
    void Function(int received, int total)? onProgress,
    String? token,
  }) {
    return _track(
      id,
      (cancelToken) => client.downloadZip(
        token: token,
        bucket: bucket,
        keys: keys,
        cancelToken: cancelToken,
        onProgress: onProgress,
      ),
    );
  }

  ///Corta la transferencia [id] si sigue en curso; su llamada acaba con un error
  void cancel(String id) => _cancelTokens.remove(id)?.cancel();

  Future<T> _track<T>(
    String id,
    Future<T> Function(CancelToken cancelToken) call,
  ) async {
    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;
    try {
      return await call(cancelToken);
    } catch (e) {
      throw ExceptionConverter.parse(e);
    } finally {
      //un reintento rapido pudo registrar ya otro con el mismo id
      if (identical(_cancelTokens[id], cancelToken)) _cancelTokens.remove(id);
    }
  }
}
