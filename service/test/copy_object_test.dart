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
  final server = TestServer(port: 8098, name: 'copy_object');
  const bucket = 'copy-bucket';

  String rulesPath(String name) =>
      '/${env.adminPrefix}/bucket/$name/anonymous-access';

  Future<http.Response> copy(
    String targetKey,
    String source, {
    String targetBucket = bucket,
    Map<String, String>? headers,
  }) {
    return http.put(
      server.url('/$targetBucket/$targetKey'),
      headers: {...(headers ?? server.auth()), 'x-amz-copy-source': source},
    );
  }

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'origen/informe.pdf', 'contenido');
    await server.putObject('other-bucket', 'base.txt', 'base');
  });
  tearDownAll(server.stop);

  group('S3Controller - CopyObject (x-amz-copy-source)', () {
    test('Should copy an object and keep the source', () async {
      final response = await copy('destino/informe.pdf', '/$bucket/origen/informe.pdf');
      expect(response.statusCode, 200);
      expect(response.body, contains('<CopyObjectResult'));
      expect(response.body, contains('<LastModified>'));
      expect(
        response.body,
        contains('<ETag>&quot;${md5.convert(utf8.encode('contenido'))}&quot;</ETag>'),
      );

      expect(
        await File('${server.storagePath}/$bucket/destino/informe.pdf').readAsString(),
        'contenido',
      );
      expect(
        await File('${server.storagePath}/$bucket/origen/informe.pdf').exists(),
        isTrue,
      );
    });

    test('Should answer the copied object in JSON when accepted', () async {
      final response = await copy(
        'copia.pdf',
        '/$bucket/origen/informe.pdf',
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['key'], 'copia.pdf');
      expect(body['size_bytes'], 'contenido'.length);
    });

    test('Should copy between buckets and accept a URL-encoded source', () async {
      final response = await copy('traido%20de%20otro.txt', 'other-bucket/base.txt');
      expect(response.statusCode, 200);
      expect(
        await File('${server.storagePath}/$bucket/traido de otro.txt').readAsString(),
        'base',
      );
    });

    test('Should overwrite an existing target', () async {
      await server.putObject(bucket, 'pisar.txt', 'viejo');
      expect((await copy('pisar.txt', '/other-bucket/base.txt')).statusCode, 200);
      expect(await File('${server.storagePath}/$bucket/pisar.txt').readAsString(), 'base');
    });

    test('Should return 404 for a missing source object', () async {
      final response = await copy('x.txt', '/$bucket/no-existe.txt', headers: server.auth(json: true));
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchKey');
    });

    test('Should return 404 for a missing target bucket', () async {
      final response = await copy(
        'copia.pdf',
        '/$bucket/origen/informe.pdf',
        targetBucket: 'no-existe',
      );
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchBucket</Code>'));
    });

    test('Should return 404 for a missing source bucket', () async {
      final response = await copy('x.txt', '/ghost-bucket/a.txt', headers: server.auth(json: true));
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchBucket');
    });

    test('Should reject copying an object onto itself (400)', () async {
      final response = await copy('origen/informe.pdf', '/$bucket/origen/informe.pdf');
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>InvalidRequest</Code>'));
    });

    test('Should reject a malformed source (400)', () async {
      for (final source in ['/', 'solo-bucket', '/$bucket/']) {
        final response = await copy('x.txt', source);
        expect(response.statusCode, 400, reason: source);
      }
    });

    test('Should reject a path traversal in the source (400)', () async {
      final response = await copy('x.txt', '/$bucket/..%2F..%2Fsecret.txt');
      expect(response.statusCode, 400);
    });

    test('Should fail without auth (401)', () async {
      final response = await copy('x.txt', '/$bucket/origen/informe.pdf', headers: {});
      expect(response.statusCode, 401);
    });

    test('Should not let an anonymous writer copy a private object (403)', () async {
      final rule = await http.post(
        server.url(rulesPath(bucket)),
        headers: {...server.auth(), 'content-type': 'application/json'},
        body: jsonEncode({'prefix': 'buzon/', 'access': 'writeOnly'}),
      );
      expect(rule.statusCode, 200);

      final response = await copy('buzon/robado.pdf', '/$bucket/origen/informe.pdf', headers: {});
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>AccessDenied</Code>'));
      expect(await File('${server.storagePath}/$bucket/buzon/robado.pdf').exists(), isFalse);
    });
  });
}
