@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8104, name: 'object_metadata');
  const bucket = 'meta-bucket';

  setUpAll(() async {
    await server.start();
    await server.createBucket(bucket);
  });
  tearDownAll(server.stop);

  Future<http.Response> head(String key) =>
      http.head(server.url('/$bucket/$key'), headers: server.auth());

  const uploadHeaders = {
    'content-type': 'image/jpeg',
    'content-language': 'es',
    'cache-control': 'max-age=60',
    'x-amz-meta-author': 'alice',
    'x-amz-meta-Project': 'feather',
  };

  group('S3Controller - Object metadata', () {
    test('Should keep the headers and x-amz-meta-* of the upload', () async {
      await server.putObject(bucket, 'photo.bin', 'jpg', headers: uploadHeaders);

      final response = await head('photo.bin');
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'image/jpeg');
      expect(response.headers['content-language'], 'es');
      expect(response.headers['cache-control'], 'max-age=60');
      expect(response.headers['x-amz-meta-author'], 'alice');
      // Names are stored lowercased, as S3 returns them
      expect(response.headers['x-amz-meta-project'], 'feather');

      final get = await http.get(
        server.url('/$bucket/photo.bin'),
        headers: server.auth(),
      );
      expect(get.headers['content-type'], 'image/jpeg');
      expect(get.headers['x-amz-meta-author'], 'alice');
    });

    test('Should not store the other request headers', () async {
      await server.putObject(
        bucket,
        'others.txt',
        'x',
        headers: {'x-amz-date': '20260101T000000Z', 'x-custom': 'no'},
      );
      final response = await head('others.txt');
      expect(response.headers['x-amz-date'], isNull);
      expect(response.headers['x-custom'], isNull);
    });

    test('Should use the extension when no Content-Type was sent', () async {
      await server.putObject(bucket, 'no-type.png', 'png');
      expect((await head('no-type.png')).headers['content-type'], 'image/png');
    });

    test('Should replace the metadata when the object is overwritten', () async {
      await server.putObject(bucket, 'changes.bin', '1', headers: uploadHeaders);
      await server.putObject(
        bucket,
        'changes.bin',
        '2',
        headers: {'content-type': 'text/csv'},
      );

      final response = await head('changes.bin');
      expect(response.headers['content-type'], 'text/csv');
      expect(response.headers['x-amz-meta-author'], isNull);
    });

    test('Should keep the metadata when the file changes outside', () async {
      await server.putObject(bucket, 'outside.bin', 'before', headers: uploadHeaders);
      await File('${server.storagePath}/$bucket/outside.bin').writeAsString('after!');

      final response = await head('outside.bin');
      expect(response.headers['content-length'], '6');
      expect(response.headers['x-amz-meta-author'], 'alice');
    });
  });

  group('S3Controller - Object metadata on copy', () {
    Future<http.Response> copy(String target, Map<String, String> headers) =>
        http.put(
          server.url('/$bucket/$target'),
          headers: {
            ...server.auth(),
            ...headers,
            'x-amz-copy-source': '/$bucket/source.bin',
          },
        );

    setUpAll(() => server.putObject(bucket, 'source.bin', 'o', headers: uploadHeaders));

    test('Should copy the metadata of the source by default', () async {
      final response = await copy('copy.bin', {'content-type': 'text/plain'});
      expect(response.statusCode, 200);

      final copied = await head('copy.bin');
      expect(copied.headers['content-type'], 'image/jpeg');
      expect(copied.headers['x-amz-meta-author'], 'alice');
    });

    test('Should use the request metadata with REPLACE', () async {
      final response = await copy('replaced.bin', {
        'x-amz-metadata-directive': 'REPLACE',
        'content-type': 'text/plain',
        'x-amz-meta-author': 'other',
      });
      expect(response.statusCode, 200);

      final copied = await head('replaced.bin');
      expect(copied.headers['content-type'], 'text/plain');
      expect(copied.headers['x-amz-meta-author'], 'other');
      expect(copied.headers['content-language'], isNull);
    });
  });

  group('S3Controller - Object metadata on multipart', () {
    test('Should apply the metadata of CreateMultipartUpload', () async {
      final created = await http.post(
        server.url('/$bucket/parts.bin?uploads'),
        headers: {...server.auth(json: true), ...uploadHeaders},
      );
      final uploadId = jsonDecode(created.body)['upload_id'] as String;

      final part = await http.put(
        server.url('/$bucket/parts.bin?partNumber=1&uploadId=$uploadId'),
        headers: server.auth(),
        body: [1, 2, 3],
      );
      final completed = await http.post(
        server.url('/$bucket/parts.bin?uploadId=$uploadId'),
        headers: {...server.auth(json: true), 'content-type': 'application/json'},
        body: jsonEncode({
          'parts': [
            {'part_number': 1, 'etag': part.headers['etag']},
          ],
        }),
      );
      expect(completed.statusCode, 200, reason: completed.body);

      final response = await head('parts.bin');
      expect(response.headers['content-type'], 'image/jpeg');
      expect(response.headers['x-amz-meta-author'], 'alice');
    });
  });

  group('S3Controller - Storage class', () {
    test('Should keep the storage class and send it back', () async {
      await server.putObject(
        bucket,
        'cold.bin',
        'x',
        headers: {'x-amz-storage-class': 'reduced_redundancy'},
      );
      final response = await head('cold.bin');
      expect(response.headers['x-amz-storage-class'], 'REDUCED_REDUNDANCY');
    });

    test('Should not send the STANDARD class, like S3', () async {
      await server.putObject(
        bucket,
        'normal.bin',
        'x',
        headers: {'x-amz-storage-class': 'STANDARD'},
      );
      expect((await head('normal.bin')).headers['x-amz-storage-class'], isNull);
    });

    test('Should reject an unknown storage class (400)', () async {
      final response = await http.put(
        server.url('/$bucket/bad.bin'),
        headers: {...server.auth(), 'x-amz-storage-class': 'DE_PLATA'},
        body: [1],
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>InvalidStorageClass</Code>'));
      expect(await File('${server.storagePath}/$bucket/bad.bin').exists(), isFalse);
    });

    test('Should take the class of the copy request, not of the source', () async {
      await server.putObject(
        bucket,
        'class-source.bin',
        'x',
        headers: {'x-amz-storage-class': 'GLACIER', 'x-amz-meta-author': 'alice'},
      );
      Future<http.Response> copy(String target, [String? storageClass]) =>
          http.put(
            server.url('/$bucket/$target'),
            headers: {
              ...server.auth(),
              'x-amz-copy-source': '/$bucket/class-source.bin',
              'x-amz-storage-class': ?storageClass,
            },
          );

      expect((await copy('class-ia.bin', 'STANDARD_IA')).statusCode, 200);
      final ia = await head('class-ia.bin');
      expect(ia.headers['x-amz-storage-class'], 'STANDARD_IA');
      expect(ia.headers['x-amz-meta-author'], 'alice');

      expect((await copy('class-normal.bin')).statusCode, 200);
      expect((await head('class-normal.bin')).headers['x-amz-storage-class'], isNull);
    });
  });
}
