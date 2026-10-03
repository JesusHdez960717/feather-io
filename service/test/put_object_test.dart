@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8086, name: 'put_test');
  const bucket = 'put-bucket';

  setUpAll(() async {
    await server.start();
    await server.createBucket(bucket);
  });
  tearDownAll(server.stop);

  group('S3Controller - PUT Object', () {

    test('Should upload successfully in root', () async {
      final response = await http.put(
        server.url('/$bucket/file.txt'),
        headers: server.auth(),
        body: 'data',
      );
      expect(response.statusCode, 200);
      expect(
        await File('${server.storagePath}/$bucket/file.txt').readAsString(),
        'data',
      );
    });

    test('Should upload successfully in deep folders', () async {
      final response = await http.put(
        server.url('/$bucket/a/b/c/d/file.txt'),
        headers: server.auth(),
        body: 'data',
      );
      expect(response.statusCode, 200);
      expect(
        await File('${server.storagePath}/$bucket/a/b/c/d/file.txt').exists(),
        isTrue,
      );
    });

    test('Should answer the ETag (md5 of the content) without body', () async {
      final response = await http.put(
        server.url('/$bucket/etag.txt'),
        headers: server.auth(),
        body: 'data',
      );
      expect(response.statusCode, 200);
      expect(
        response.headers['etag'],
        '"${md5.convert(utf8.encode('data'))}"',
      );
      expect(response.body, isEmpty);
    });

    test('Should not create the bucket if it does not exist (404)', () async {
      final response = await http.put(
        server.url('/no-existe/file.txt'),
        headers: server.auth(),
        body: 'data',
      );
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchBucket</Code>'));
      expect(await Directory('${server.storagePath}/no-existe').exists(), isFalse);
    });

    test('Should fail without auth (401)', () async {
      final response = await http.put(
        server.url('/$bucket/nopass.txt'),
        body: 'data',
      );
      expect(response.statusCode, 401);
    });

    test('Should fail with an invalid token (401)', () async {
      final response = await http.put(
        server.url('/$bucket/wrong.txt'),
        headers: {'authorization': 'Bearer not-a-jwt'},
        body: 'data',
      );
      expect(response.statusCode, 401);
    });

    test('Should fail with invalid bucket name (400)', () async {
      final response = await http.put(
        server.url('/INVALID_BUCKET/file.txt'),
        headers: server.auth(),
        body: 'data',
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>InvalidBucketName</Code>'));
    });

    test('Should fail with path traversal in key (400)', () async {
      //con %2F el cliente no normaliza los '..' y el key llega tal cual al servidor
      final response = await http.put(
        server.url('/$bucket/..%2F..%2Fescape.txt'),
        headers: server.auth(),
        body: 'data',
      );
      expect(response.statusCode, 400);
      expect(await File('${server.storagePath}/escape.txt').exists(), isFalse);
      expect(await File('./uploads_test/escape.txt').exists(), isFalse);
    });

    test('Should fail with invalid characters in key (400)', () async {
      final response = await http.put(
        server.url('/$bucket/invalid:file.txt'),
        headers: server.auth(),
        body: 'data',
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>InvalidArgument</Code>'));
    });
  });

  group('S3Controller - PUT Object over an open file (Windows)', () {
    //en Windows no se puede sustituir un fichero abierto: se reintenta un rato
    //y, si sigue abierto, 503 (los clientes S3 lo reintentan)
    Future<RandomAccessFile> openFor(String key, Duration duration) async {
      final handle = await File('${server.storagePath}/$bucket/$key').open();
      unawaited(Future<void>.delayed(duration, handle.close));
      return handle;
    }

    test(
      'Should replace an object that is open for a moment',
      () async {
        await server.putObject(bucket, 'abierto.txt', 'antes');
        await openFor('abierto.txt', const Duration(milliseconds: 300));

        final response = await http.put(
          server.url('/$bucket/abierto.txt'),
          headers: server.auth(),
          body: 'despues',
        );
        expect(response.statusCode, 200, reason: response.body);
        expect(
          await File('${server.storagePath}/$bucket/abierto.txt').readAsString(),
          'despues',
        );
      },
      testOn: 'windows',
    );

    test(
      'Should copy onto an object that is open for a moment',
      () async {
        await server.putObject(bucket, 'copia-origen.txt', 'nuevo');
        await server.putObject(bucket, 'copia-abierta.txt', 'viejo');
        await openFor('copia-abierta.txt', const Duration(milliseconds: 300));

        final response = await http.put(
          server.url('/$bucket/copia-abierta.txt'),
          headers: {
            ...server.auth(),
            'x-amz-copy-source': '/$bucket/copia-origen.txt',
          },
        );
        expect(response.statusCode, 200, reason: response.body);
        expect(
          await File('${server.storagePath}/$bucket/copia-abierta.txt').readAsString(),
          'nuevo',
        );
      },
      testOn: 'windows',
    );

    test(
      'Should answer 503 and keep the object if it stays open',
      () async {
        await server.putObject(bucket, 'bloqueado.txt', 'antes');
        final handle = await openFor(
          'bloqueado.txt',
          FileManagementService.replaceTimeout + const Duration(seconds: 3),
        );

        final response = await http.put(
          server.url('/$bucket/bloqueado.txt'),
          headers: server.auth(),
          body: 'despues',
        );
        await handle.close();
        expect(response.statusCode, 503);
        expect(response.body, contains('<Code>ServiceUnavailable</Code>'));
        expect(
          await File('${server.storagePath}/$bucket/bloqueado.txt').readAsString(),
          'antes',
        );
        //y no deja el fichero temporal
        expect(
          await Directory('${server.storagePath}/.tmp').list().isEmpty,
          isTrue,
        );
      },
      testOn: 'windows',
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });

  group('S3Controller - PUT Object key validation', () {
    test('Should reject a backslash in the key (400)', () async {
      //en Windows `a\b` seria otra forma de escribir `a/b`, y permitiria
      //escribir el marcador de carpeta (`x\.feather-folder`)
      for (final key in ['carpeta%5Cfichero.txt', 'otra%5C.feather-folder']) {
        final response = await http.put(
          server.url('/$bucket/$key'),
          headers: server.auth(),
          body: 'x',
        );
        expect(response.statusCode, 400, reason: key);
        expect(response.body, contains('<Code>InvalidArgument</Code>'));
      }
      expect(
        await File('${server.storagePath}/$bucket/carpeta/fichero.txt').exists(),
        isFalse,
      );
    });
  });
}
