@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8101, name: 'multipart');
  const bucket = 'mp-bucket';
  const mb = 1024 * 1024;

  final part1 = List<int>.filled(5 * mb, 1);
  final part2 = List<int>.filled(1234, 2);

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'otro.txt', 'x');
  });
  tearDownAll(server.stop);

  String? xmlTag(String xml, String name) =>
      RegExp('<$name>(.*?)</$name>', dotAll: true).firstMatch(xml)?.group(1);

  Future<http.Response> create(String key, {bool json = false}) => http.post(
    server.url('/$bucket/$key?uploads'),
    headers: server.auth(json: json),
  );

  Future<String> createId(String key) async {
    final response = await create(key, json: true);
    expect(response.statusCode, 200, reason: response.body);
    return jsonDecode(response.body)['upload_id'] as String;
  }

  Future<http.Response> uploadPart(
    String key,
    String uploadId,
    int number,
    List<int> body, {
    Map<String, String> extra = const {},
  }) => http.put(
    server.url('/$bucket/$key?partNumber=$number&uploadId=$uploadId'),
    headers: {...server.auth(), ...extra},
    body: body,
  );

  Future<http.Response> completeXml(
    String key,
    String uploadId,
    List<(int, String)> parts,
  ) {
    final xml = StringBuffer('<CompleteMultipartUpload>');
    for (final (number, etag) in parts) {
      xml.write(
        '<Part><PartNumber>$number</PartNumber><ETag>$etag</ETag></Part>',
      );
    }
    xml.write('</CompleteMultipartUpload>');
    return http.post(
      server.url('/$bucket/$key?uploadId=$uploadId'),
      headers: {...server.auth(), 'content-type': 'application/xml'},
      body: xml.toString(),
    );
  }

  Future<http.Response> completeJson(
    String key,
    String uploadId,
    List<(int, String)> parts,
  ) => http.post(
    server.url('/$bucket/$key?uploadId=$uploadId'),
    headers: {...server.auth(json: true), 'content-type': 'application/json'},
    body: jsonEncode({
      'parts': [
        for (final (number, etag) in parts)
          {'part_number': number, 'etag': etag},
      ],
    }),
  );

  /// Sube las dos partes de prueba y devuelve sus ETags
  Future<List<String>> uploadBoth(String key, String uploadId) async {
    final etags = <String>[];
    for (final (number, body) in [(1, part1), (2, part2)]) {
      final response = await uploadPart(key, uploadId, number, body);
      expect(response.statusCode, 200, reason: response.body);
      etags.add(response.headers['etag']!);
    }
    return etags;
  }

  group('S3Controller - multipart upload', () {
    test('Should create, upload parts and complete (XML)', () async {
      const key = 'videos/grande.bin';
      final created = await create(key);
      expect(created.statusCode, 200);
      expect(created.headers['content-type'], contains('application/xml'));
      expect(xmlTag(created.body, 'Bucket'), bucket);
      expect(xmlTag(created.body, 'Key'), key);
      final uploadId = xmlTag(created.body, 'UploadId')!;
      expect(uploadId, matches(RegExp(r'^[0-9a-f]{32}$')));

      final etags = await uploadBoth(key, uploadId);
      expect(etags[0], '"${md5.convert(part1)}"');

      final completed = await completeXml(key, uploadId, [
        (1, etags[0].replaceAll('"', '&quot;')),
        (2, etags[1]),
      ]);
      expect(completed.statusCode, 200, reason: completed.body);
      final expectedEtag =
          '${md5.convert([...md5.convert(part1).bytes, ...md5.convert(part2).bytes])}-2';
      expect(xmlTag(completed.body, 'ETag'), '&quot;$expectedEtag&quot;');
      expect(xmlTag(completed.body, 'Key'), key);

      final object = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(object.statusCode, 200);
      expect(object.bodyBytes.length, part1.length + part2.length);
      expect(object.bodyBytes.last, 2);

      //la subida ya no existe
      final again = await uploadPart(key, uploadId, 3, [1]);
      expect(again.statusCode, 404);
      expect(again.body, contains('<Code>NoSuchUpload</Code>'));
    });

    test('Should create and complete with JSON (console)', () async {
      const key = 'consola.bin';
      final uploadId = await createId(key);
      final etags = await uploadBoth(key, uploadId);
      final completed = await completeJson(key, uploadId, [
        (1, etags[0]),
        (2, etags[1]),
      ]);
      expect(completed.statusCode, 200, reason: completed.body);
      final body = jsonDecode(completed.body);
      expect(body['key'], key);
      expect(body['size_bytes'], part1.length + part2.length);
      expect(body['etag'], endsWith('-2'));
    });

    test('Should use the last upload of a repeated part', () async {
      const key = 'repetida.bin';
      final uploadId = await createId(key);
      await uploadPart(key, uploadId, 1, List<int>.filled(5 * mb, 9));
      final etags = await uploadBoth(key, uploadId);
      final completed = await completeJson(key, uploadId, [
        (1, etags[0]),
        (2, etags[1]),
      ]);
      expect(completed.statusCode, 200);
      final object = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(object.bodyBytes.first, 1);
    });

    test('Should allow a single small part', () async {
      const key = 'pequena.txt';
      final uploadId = await createId(key);
      final part = await uploadPart(key, uploadId, 1, utf8.encode('hola'));
      final completed = await completeJson(key, uploadId, [
        (1, part.headers['etag']!),
      ]);
      expect(completed.statusCode, 200);
      final object = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(object.body, 'hola');
    });

    test('Should abort and remove the parts', () async {
      const key = 'abortada.bin';
      final uploadId = await createId(key);
      await uploadPart(key, uploadId, 1, part2);
      final dir = Directory(
        '${server.storagePath}/${MultipartService.folderName}/$uploadId',
      );
      expect(dir.existsSync(), isTrue);

      final aborted = await http.delete(
        server.url('/$bucket/$key?uploadId=$uploadId'),
        headers: server.auth(),
      );
      expect(aborted.statusCode, 204);
      expect(dir.existsSync(), isFalse);

      final part = await uploadPart(key, uploadId, 2, part2);
      expect(part.statusCode, 404);
    });

    test('Should not list the pending uploads as a bucket', () async {
      await createId('pendiente.bin');
      final response = await http.get(
        server.url('/'),
        headers: server.auth(json: true),
      );
      final names = [
        for (final b in jsonDecode(response.body) as List) b['name'],
      ];
      expect(names, isNot(contains(MultipartService.folderName)));
    });

    test('Should expose the ETag header to the browser (CORS)', () async {
      const key = 'cors.bin';
      final uploadId = await createId(key);
      final response = await uploadPart(
        key,
        uploadId,
        1,
        part2,
        extra: {'origin': 'http://localhost:8081'},
      );
      expect(
        response.headers['access-control-expose-headers']?.toLowerCase(),
        contains('etag'),
      );
    });
  });

  group('S3Controller - multipart errors', () {
    test('Should reject a small part that is not the last one', () async {
      const key = 'corta.bin';
      final uploadId = await createId(key);
      final a = await uploadPart(key, uploadId, 1, part2);
      final b = await uploadPart(key, uploadId, 2, part2);
      final completed = await completeXml(key, uploadId, [
        (1, a.headers['etag']!),
        (2, b.headers['etag']!),
      ]);
      expect(completed.statusCode, 400);
      expect(completed.body, contains('<Code>EntityTooSmall</Code>'));
    });

    test('Should reject parts out of order', () async {
      const key = 'desordenada.bin';
      final uploadId = await createId(key);
      final etags = await uploadBoth(key, uploadId);
      final completed = await completeXml(key, uploadId, [
        (2, etags[1]),
        (1, etags[0]),
      ]);
      expect(completed.statusCode, 400);
      expect(completed.body, contains('<Code>InvalidPartOrder</Code>'));
    });

    test('Should reject a missing part or a wrong ETag', () async {
      const key = 'incompleta.bin';
      final uploadId = await createId(key);
      final etags = await uploadBoth(key, uploadId);

      final missing = await completeXml(key, uploadId, [
        (1, etags[0]),
        (3, etags[1]),
      ]);
      expect(missing.statusCode, 400);
      expect(missing.body, contains('<Code>InvalidPart</Code>'));

      final wrong = await completeXml(key, uploadId, [
        (1, etags[1]),
        (2, etags[1]),
      ]);
      expect(wrong.statusCode, 400);
      expect(wrong.body, contains('<Code>InvalidPart</Code>'));
    });

    test('Should reject a malformed part list', () async {
      const key = 'mal.bin';
      final uploadId = await createId(key);
      final response = await http.post(
        server.url('/$bucket/$key?uploadId=$uploadId'),
        headers: {...server.auth(), 'content-type': 'application/xml'},
        body: '<CompleteMultipartUpload></CompleteMultipartUpload>',
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>MalformedXML</Code>'));
    });

    test('Should answer NoSuchUpload for unknown or foreign ids', () async {
      final uploadId = await createId('propia.bin');

      for (final (key, id) in [
        ('propia.bin', '0' * 32),
        ('propia.bin', '..%2F..%2Fotro'),
        ('ajena.bin', uploadId),
      ]) {
        final response = await uploadPart(key, id, 1, part2);
        expect(response.statusCode, 404, reason: '$key $id');
        expect(response.body, contains('<Code>NoSuchUpload</Code>'));
      }
    });

    test('Should reject an invalid part number', () async {
      const key = 'numero.bin';
      final uploadId = await createId(key);
      for (final number in [0, 10001]) {
        final response = await uploadPart(key, uploadId, number, part2);
        expect(response.statusCode, 400, reason: '$number');
        expect(response.body, contains('<Code>InvalidArgument</Code>'));
      }
    });

    test('Should fail on a missing bucket or a folder key', () async {
      final noBucket = await http.post(
        server.url('/no-existe/a.bin?uploads'),
        headers: server.auth(),
      );
      expect(noBucket.statusCode, 404);
      expect(noBucket.body, contains('<Code>NoSuchBucket</Code>'));

      final folder = await create('carpeta/');
      expect(folder.statusCode, 400);
    });

    test(
      'Should reject POST on an object without ?uploads/?uploadId',
      () async {
        final response = await http.post(
          server.url('/$bucket/otro.txt'),
          headers: server.auth(),
        );
        expect(response.statusCode, 400);
        expect(response.body, contains('<Code>InvalidRequest</Code>'));
      },
    );

    test('Should fail without auth (401)', () async {
      final response = await http.post(server.url('/$bucket/a.bin?uploads'));
      expect(response.statusCode, 401);
    });
  });

  group('S3Controller - multipart with SigV4', () {
    test('Should create an upload signed with the service keys', () async {
      final now = DateTime.now().toUtc();
      final amzDate = SigV4Signer.amzDate(now);
      final scope = SigV4Signer.scope(SigV4Signer.dateStamp(now));
      final headers = {
        'host': 'localhost:8101',
        'x-amz-date': amzDate,
        'x-amz-content-sha256': SigV4Signer.unsignedPayload,
      };
      const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
      final signature = SigV4Signer.signature(
        secret: testSecret,
        amzDate: amzDate,
        scope: scope,
        canonicalRequest: SigV4Signer.canonicalRequest(
          method: 'POST',
          path: '/$bucket/firmada.bin',
          query: const {'uploads': ''},
          headers: headers,
          signedHeaders: signedHeaders,
          payloadHash: SigV4Signer.unsignedPayload,
        ),
      );

      final response = await http.post(
        server.url('/$bucket/firmada.bin?uploads'),
        headers: {
          ...headers,
          'authorization':
              '${SigV4Signer.algorithm} Credential=$testAccess/$scope, '
              'SignedHeaders=$signedHeaders, Signature=$signature',
        },
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(xmlTag(response.body, 'UploadId'), isNotNull);
    });
  });

  group('BucketService - multipart cleanup', () {
    test('Should abort the pending uploads when a bucket is deleted', () async {
      const other = 'mp-temporal';
      final created = await http.put(
        server.url('/$other'),
        headers: server.auth(),
      );
      expect(created.statusCode, 200);
      final start = await http.post(
        server.url('/$other/a.bin?uploads'),
        headers: server.auth(json: true),
      );
      final uploadId = jsonDecode(start.body)['upload_id'] as String;

      final deleted = await http.delete(
        server.url('/$other'),
        headers: server.auth(),
      );
      expect(deleted.statusCode, 204);
      expect(
        Directory(
          '${server.storagePath}/${MultipartService.folderName}/$uploadId',
        ).existsSync(),
        isFalse,
      );
    });
  });
}
