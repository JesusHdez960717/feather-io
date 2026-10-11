import 'dart:async';

import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockClient extends Mock implements TransferClient {}

void main() {
  late _MockClient client;
  late TransferRepo repo;

  setUpAll(() {
    registerFallbackValue(CancelToken());
    registerFallbackValue(const Stream<List<int>>.empty());
  });

  setUp(() {
    client = _MockClient();
    repo = TransferRepo(client);
  });

  When<Future<List<int>>> whenDownload() => when(
    () => client.downloadZip(
      token: any(named: 'token'),
      bucket: any(named: 'bucket'),
      keys: any(named: 'keys'),
      cancelToken: any(named: 'cancelToken'),
      onProgress: any(named: 'onProgress'),
    ),
  );

  test('Cancelling cuts the request of that transfer', () async {
    final response = Completer<List<int>>();
    late CancelToken token;
    whenDownload().thenAnswer((call) {
      token = call.namedArguments[#cancelToken] as CancelToken;
      return response.future;
    });

    final download = repo.downloadZip(id: '1', bucket: 'media', keys: ['a']);
    await pumpEventQueue();
    repo.cancel('1');

    expect(token.isCancelled, isTrue);
    response.complete([1]);
    await download;
  });

  test('A finished transfer can no longer be cancelled', () async {
    late CancelToken token;
    whenDownload().thenAnswer((call) async {
      token = call.namedArguments[#cancelToken] as CancelToken;
      return [1];
    });

    await repo.downloadZip(id: '1', bucket: 'media', keys: ['a']);
    repo.cancel('1');

    expect(token.isCancelled, isFalse);
  });

  test('Uploaded parts are sent as the parts to complete', () async {
    when(
      () => client.completeMultipart(
        token: any(named: 'token'),
        bucket: any(named: 'bucket'),
        key: any(named: 'key'),
        uploadId: any(named: 'uploadId'),
        parts: any(named: 'parts'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async {});

    await repo.completeMultipart(
      id: '1',
      bucket: 'media',
      key: 'video.mp4',
      uploadId: 'u1',
      parts: const [
        UploadedPart(number: 1, etag: '"e1"'),
        UploadedPart(number: 2, etag: '"e2"'),
      ],
    );

    final parts =
        verify(
              () => client.completeMultipart(
                token: any(named: 'token'),
                bucket: 'media',
                key: 'video.mp4',
                uploadId: 'u1',
                parts: captureAny(named: 'parts'),
                cancelToken: any(named: 'cancelToken'),
              ),
            ).captured.single
            as List<CompleteMultipartPart>;
    expect(parts.map((p) => p.toJson()), [
      {'part_number': 1, 'etag': '"e1"'},
      {'part_number': 2, 'etag': '"e2"'},
    ]);
  });

  test('An API error arrives with the service message', () async {
    whenDownload().thenThrow(
      httpError(404, {'code': 'NoSuchKey', 'detail': 'Nothing to download'}),
    );

    await expectLater(
      () => repo.downloadZip(id: '1', bucket: 'media', keys: ['a']),
      throwsA(
        isA<GlobalException>().having(
          (e) => e.message,
          'message',
          'Nothing to download',
        ),
      ),
    );
  });
}
