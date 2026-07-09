@TestOn('vm')
library;

import 'dart:io';
import 'package:service/feather.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  int port = 8080;
  String localUrl = 'http://localhost:$port';
  const String secret = 'test_secret';
  const String access = 'test_access';
  const String storagePath = './uploads_test/main_test';

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

  group('S3Controller - Happy Path Flow', () {
    const bucket = 'main-bucket';
    const key = 'test-file.txt';
    const content = 'Hello World';

    test('1. PUT - Should upload successfully', () async {
      final response = await http.put(
        url('/$bucket/$key'),
        headers: authHeaders,
        body: content,
      );
      expect(response.statusCode, 200);
    });

    test('2. GET /list - Should find the uploaded file', () async {
      final response = await http.get(
        url('/$bucket/list'),
        headers: {...authHeaders, 'Accept': 'application/json'},
      );
      expect(response.statusCode, 200);
      expect(response.body, contains(key));
    });

    test('3. GET /{key} - Should download the file content', () async {
      final response = await http.get(url('/$bucket/$key'));
      expect(response.statusCode, 200);
      expect(response.body, content);
    });

    test('4. DELETE - Should remove the file', () async {
      final response = await http.delete(
        url('/$bucket/$key'),
        headers: authHeaders,
      );
      expect(response.statusCode, 200);

      final verify = await http.get(url('/$bucket/$key'));
      expect(verify.statusCode, 404);
    });
  });
}
