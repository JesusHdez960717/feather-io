@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support/test_server.dart';

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
    'x-amz-meta-autor': 'jesus',
    'x-amz-meta-Proyecto': 'feather',
  };

  group('S3Controller - Object metadata', () {
    test('Should keep the headers and x-amz-meta-* of the upload', () async {
      await server.putObject(bucket, 'foto.bin', 'jpg', headers: uploadHeaders);

      final response = await head('foto.bin');
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'image/jpeg');
      expect(response.headers['content-language'], 'es');
      expect(response.headers['cache-control'], 'max-age=60');
      expect(response.headers['x-amz-meta-autor'], 'jesus');
      //los nombres se guardan en minusculas, como los devuelve S3
      expect(response.headers['x-amz-meta-proyecto'], 'feather');

      final get = await http.get(
        server.url('/$bucket/foto.bin'),
        headers: server.auth(),
      );
      expect(get.headers['content-type'], 'image/jpeg');
      expect(get.headers['x-amz-meta-autor'], 'jesus');
    });

    test('Should not store the other request headers', () async {
      await server.putObject(
        bucket,
        'otras.txt',
        'x',
        headers: {'x-amz-date': '20260101T000000Z', 'x-custom': 'no'},
      );
      final response = await head('otras.txt');
      expect(response.headers['x-amz-date'], isNull);
      expect(response.headers['x-custom'], isNull);
    });

    test('Should use the extension when no Content-Type was sent', () async {
      await server.putObject(bucket, 'sin-tipo.png', 'png');
      expect((await head('sin-tipo.png')).headers['content-type'], 'image/png');
    });

    test('Should replace the metadata when the object is overwritten', () async {
      await server.putObject(bucket, 'cambia.bin', '1', headers: uploadHeaders);
      await server.putObject(
        bucket,
        'cambia.bin',
        '2',
        headers: {'content-type': 'text/csv'},
      );

      final response = await head('cambia.bin');
      expect(response.headers['content-type'], 'text/csv');
      expect(response.headers['x-amz-meta-autor'], isNull);
    });

    test('Should keep the metadata when the file changes outside', () async {
      await server.putObject(bucket, 'fuera.bin', 'antes', headers: uploadHeaders);
      await File('${server.storagePath}/$bucket/fuera.bin').writeAsString('despues!');

      final response = await head('fuera.bin');
      expect(response.headers['content-length'], '8');
      expect(response.headers['x-amz-meta-autor'], 'jesus');
    });
  });

  group('S3Controller - Object metadata on copy', () {
    Future<http.Response> copy(String target, Map<String, String> headers) =>
        http.put(
          server.url('/$bucket/$target'),
          headers: {
            ...server.auth(),
            ...headers,
            'x-amz-copy-source': '/$bucket/origen.bin',
          },
        );

    setUpAll(() => server.putObject(bucket, 'origen.bin', 'o', headers: uploadHeaders));

    test('Should copy the metadata of the source by default', () async {
      final response = await copy('copia.bin', {'content-type': 'text/plain'});
      expect(response.statusCode, 200);

      final copied = await head('copia.bin');
      expect(copied.headers['content-type'], 'image/jpeg');
      expect(copied.headers['x-amz-meta-autor'], 'jesus');
    });

    test('Should use the request metadata with REPLACE', () async {
      final response = await copy('reemplazo.bin', {
        'x-amz-metadata-directive': 'REPLACE',
        'content-type': 'text/plain',
        'x-amz-meta-autor': 'otro',
      });
      expect(response.statusCode, 200);

      final copied = await head('reemplazo.bin');
      expect(copied.headers['content-type'], 'text/plain');
      expect(copied.headers['x-amz-meta-autor'], 'otro');
      expect(copied.headers['content-language'], isNull);
    });
  });

  group('S3Controller - Object metadata on multipart', () {
    test('Should apply the metadata of CreateMultipartUpload', () async {
      final created = await http.post(
        server.url('/$bucket/partes.bin?uploads'),
        headers: {...server.auth(json: true), ...uploadHeaders},
      );
      final uploadId = jsonDecode(created.body)['upload_id'] as String;

      final part = await http.put(
        server.url('/$bucket/partes.bin?partNumber=1&uploadId=$uploadId'),
        headers: server.auth(),
        body: [1, 2, 3],
      );
      final completed = await http.post(
        server.url('/$bucket/partes.bin?uploadId=$uploadId'),
        headers: {...server.auth(json: true), 'content-type': 'application/json'},
        body: jsonEncode({
          'parts': [
            {'part_number': 1, 'etag': part.headers['etag']},
          ],
        }),
      );
      expect(completed.statusCode, 200, reason: completed.body);

      final response = await head('partes.bin');
      expect(response.headers['content-type'], 'image/jpeg');
      expect(response.headers['x-amz-meta-autor'], 'jesus');
    });
  });

  group('S3Controller - Storage class', () {
    test('Should keep the storage class and send it back', () async {
      await server.putObject(
        bucket,
        'frio.bin',
        'x',
        headers: {'x-amz-storage-class': 'reduced_redundancy'},
      );
      final response = await head('frio.bin');
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
        server.url('/$bucket/mala.bin'),
        headers: {...server.auth(), 'x-amz-storage-class': 'DE_PLATA'},
        body: [1],
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>InvalidStorageClass</Code>'));
      expect(await File('${server.storagePath}/$bucket/mala.bin').exists(), isFalse);
    });

    test('Should take the class of the copy request, not of the source', () async {
      await server.putObject(
        bucket,
        'clase-origen.bin',
        'x',
        headers: {'x-amz-storage-class': 'GLACIER', 'x-amz-meta-autor': 'jesus'},
      );
      Future<http.Response> copy(String target, [String? storageClass]) =>
          http.put(
            server.url('/$bucket/$target'),
            headers: {
              ...server.auth(),
              'x-amz-copy-source': '/$bucket/clase-origen.bin',
              'x-amz-storage-class': ?storageClass,
            },
          );

      expect((await copy('clase-ia.bin', 'STANDARD_IA')).statusCode, 200);
      final ia = await head('clase-ia.bin');
      expect(ia.headers['x-amz-storage-class'], 'STANDARD_IA');
      expect(ia.headers['x-amz-meta-autor'], 'jesus');

      expect((await copy('clase-normal.bin')).statusCode, 200);
      expect((await head('clase-normal.bin')).headers['x-amz-storage-class'], isNull);
    });
  });
}
