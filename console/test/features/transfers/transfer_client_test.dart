import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<RequestOptions> sent;
  late TransferClient client;

  setUp(() {
    sent = [];
    // The default headers of the app's Dio (features_init.dart)
    final dio = Dio()
      ..options.headers = {Headers.contentTypeHeader: 'application/json'};
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'upload_id': 'abc'},
            ),
          );
        },
      ),
    );
    client = TransferClient(dio);
  });

  Future<void> put(String key) => client.putObject(
    bucket: 'media',
    key: key,
    data: Stream.value([1, 2, 3]),
    length: 3,
    cancelToken: CancelToken(),
  );

  test('An upload sends the Content-Type of its extension', () async {
    await put('fotos/image.jpg');

    expect(sent.single.contentType, 'image/jpeg');
  });

  test('An upload without a known extension is octet-stream', () async {
    await put('fotos/preview');

    expect(sent.single.contentType, 'application/octet-stream');
  });

  test('A multipart upload sends the Content-Type on create', () async {
    await client.createMultipart(
      bucket: 'media',
      key: 'videos/clip.mp4',
      cancelToken: CancelToken(),
    );

    expect(sent.single.contentType, 'video/mp4');
  });
}
