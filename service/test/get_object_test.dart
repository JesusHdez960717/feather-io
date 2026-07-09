@TestOn('vm')
library;

import 'dart:io';
import 'package:service/feather.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  int port = 8083;
  String localUrl = 'http://localhost:$port';
  const String secret = 'test_secret';
  const String access = 'test_access';
  const String storagePath = './uploads_test/get_test';

  setUpAll(() async {
    env.put('FEATHER_SECRET', secret);
    env.put('FEATHER_ACCESS', access);
    env.put('STORAGE_PATH', storagePath);

    final dir = Directory(storagePath);
    if (await dir.exists()) await dir.delete(recursive: true);

    await FeatherIO.start(port: port);
    
    // Pre-upload a file for testing
    await http.put(
      Uri.parse('http://localhost:$port/get-bucket/test.txt'),
      headers: {'FEATHER_SECRET': secret, 'FEATHER_ACCESS': access},
      body: 'content',
    );
  });

  tearDownAll(() async {
    await Winter.close(force: true);
    final dir = Directory(storagePath);
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Uri url(String path) => Uri.parse(localUrl + path);

  group('S3Controller - GET Object', () {
    const bucket = 'get-bucket';

    test('Should download successfully WITHOUT auth (Public)', () async {
      final response = await http.get(url('/$bucket/test.txt'));
      expect(response.statusCode, 200);
      expect(response.body, 'content');
    });

    test('Should return 404 for non-existent file', () async {
      final response = await http.get(url('/$bucket/notfound.txt'));
      expect(response.statusCode, 404);
    });

    test('Should return 404 for non-existent bucket', () async {
      final response = await http.get(url('/other-bucket/test.txt'));
      expect(response.statusCode, 404);
    });

    test('Should return 400 for invalid bucket name', () async {
      final response = await http.get(url('/INVALID_BUCKET/test.txt'));
      expect(response.statusCode, 400);
    });

    test('Should return 400 for invalid key', () async {
      final response = await http.get(url('/$bucket/invalid:name'));
      expect(response.statusCode, 400);
    });
  });
}
