@TestOn('vm')
library;

import 'dart:io';
import 'package:service/feather.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  int port = 8082;
  String localUrl = 'http://localhost:$port';
  const String secret = 'test_secret';
  const String access = 'test_access';
  const String storagePath = './uploads_test/delete_test';

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

  group('S3Controller - DELETE Object', () {
    const bucket = 'delete-bucket';

    test('Should delete file successfully', () async {
      final key = 'todelete.txt';
      // 1. Upload
      await http.put(url('/$bucket/$key'), headers: authHeaders, body: 'data');
      
      // 2. Delete
      final response = await http.delete(url('/$bucket/$key'), headers: authHeaders);
      expect(response.statusCode, 200);

      // 3. Verify
      final getResponse = await http.get(url('/$bucket/$key'));
      expect(getResponse.statusCode, 404);
    });

    test('Should clean up empty parent folders after delete', () async {
      final key = 'a/b/c/file.txt';
      await http.put(url('/$bucket/$key'), headers: authHeaders, body: 'data');
      
      await http.delete(url('/$bucket/$key'), headers: authHeaders);

      // We can verify this by checking if the folder exists on disk if we had access, 
      // but through API, a list should not show it.
      final listResponse = await http.get(
        url('/$bucket/list'),
        headers: {...authHeaders, 'Accept': 'application/json'},
      );
      expect(listResponse.body, '[]');
    });

    test('Should fail without auth (401)', () async {
      final response = await http.delete(url('/$bucket/file.txt'));
      expect(response.statusCode, 401);
    });

    test('Should fail with wrong auth (403)', () async {
      final response = await http.delete(
        url('/$bucket/file.txt'),
        headers: {'FEATHER_SECRET': 'w', 'FEATHER_ACCESS': 'w'},
      );
      expect(response.statusCode, 403);
    });

    test('Should return 404 if file does not exist', () async {
      final response = await http.delete(
        url('/$bucket/non-existent.txt'),
        headers: authHeaders,
      );
      expect(response.statusCode, 404);
    });
  });
}
