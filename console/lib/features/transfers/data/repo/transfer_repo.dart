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

  Future<String> createMultipart({
    required String id,
    required String bucket,
    required String key,
    String? token,
  }) {
    return _track(
      id,
      (cancelToken) => client.createMultipart(
        token: token,
        bucket: bucket,
        key: key,
        cancelToken: cancelToken,
      ),
    );
  }

  ///Sube una parte y devuelve su ETag
  Future<String> uploadPart({
    required String id,
    required String bucket,
    required String key,
    required String uploadId,
    required int partNumber,
    required Stream<List<int>> data,
    required int length,
    void Function(int sent, int total)? onProgress,
    String? token,
  }) {
    return _track(
      id,
      (cancelToken) => client.uploadPart(
        token: token,
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: partNumber,
        data: data,
        length: length,
        cancelToken: cancelToken,
        onProgress: onProgress,
      ),
    );
  }

  Future<void> completeMultipart({
    required String id,
    required String bucket,
    required String key,
    required String uploadId,
    required List<UploadedPart> parts,
    String? token,
  }) {
    return _track(
      id,
      (cancelToken) => client.completeMultipart(
        token: token,
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        parts: parts.map((part) => part.toRequest()).toList(),
        cancelToken: cancelToken,
      ),
    );
  }

  Future<void> abortMultipart({
    required String bucket,
    required String key,
    required String uploadId,
    String? token,
  }) async {
    try {
      await client.abortMultipart(
        token: token,
        bucket: bucket,
        key: key,
        uploadId: uploadId,
      );
    } catch (e) {
      throw ExceptionConverter.parse(e);
    }
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

extension UploadedPartMapping on UploadedPart {
  CompleteMultipartPart toRequest() =>
      CompleteMultipartPart(partNumber: number, etag: etag);
}
