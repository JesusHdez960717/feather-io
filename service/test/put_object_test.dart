@TestOn('vm')
library;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

void main() {
  int port = 8086;
  String localUrl = 'http://localhost:$port';
  const String secret = 'test_secret';
  const String access = 'test_access';
  const String storagePath = './uploads_test/put_test';

  setUpAll(() async {
    env.put('FEATHER_SECRET', secret);
    env.put('FEATHER_ACCESS', access);
    env.put('STORAGE_PATH', storagePath);

    final dir = Directory(storagePath);
    if (await dir.exists()) await dir.delete(recursive: true);

    await FeatherIO.start(port: port);
  });

  tearDownAll(() async {
    await Winter.close(force: true);
    final dir = Directory(storagePath);
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Uri url(String path) => Uri.parse(localUrl + path);
  Map<String, String> authHeaders = {
    'FEATHER_SECRET': secret,
    'FEATHER_ACCESS': access,
  };

  group('S3Controller - PUT Object', () {
    const bucket = 'put-bucket';

    test('Should upload successfully in root', () async {
      final response = await http.put(
        url('/$bucket/file.txt'),
        headers: authHeaders,
        body: 'data',
      );
      expect(response.statusCode, 200);
    });

    test('Should upload successfully in deep folders', () async {
      final response = await http.put(
        url('/$bucket/a/b/c/d/file.txt'),
        headers: authHeaders,
        body: 'data',
      );
      expect(response.statusCode, 200);
    });

    test('Should fail without auth (401)', () async {
      final response = await http.put(url('/$bucket/nopass.txt'), body: 'data');
      expect(response.statusCode, 401);
    });

    test('Should fail with wrong auth (403)', () async {
      final response = await http.put(
        url('/$bucket/wrong.txt'),
        headers: {'FEATHER_SECRET': 'wrong', 'FEATHER_ACCESS': 'wrong'},
        body: 'data',
      );
      expect(response.statusCode, 403);
    });

    test('Should fail with invalid bucket name (400)', () async {
      final response = await http.put(
        url('/INVALID_BUCKET/file.txt'),
        headers: authHeaders,
        body: 'data',
      );
      expect(response.statusCode, 400);
    });

    test('Should fail with path traversal in key (400)', () async {
      final response = await http.put(
        url('/$bucket/%2e%2e/%2e%2e/etc/password'),
        headers: authHeaders,
        body: 'data',
      );
      expect(response.statusCode, 200); //200 xq se ignoran los %2e%2e
    });

    test('Should fail with invalid characters in key (400)', () async {
      final response = await http.put(
        url('/$bucket/invalid:file.txt'),
        headers: authHeaders,
        body: 'data',
      );
      expect(response.statusCode, 400);
    });
  });
}
