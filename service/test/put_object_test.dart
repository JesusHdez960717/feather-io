@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
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
}
