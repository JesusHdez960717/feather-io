@TestOn('vm')
library;

import 'dart:io';

import 'package:feather_io/feather.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  // Use a different port than 8080 in case you have the real app running
  int port = 8080;
  String localUrl = 'http://localhost:$port';

  const String secret = 'test_secret';
  const String access = 'test_access';

  setUpAll(() async {
    // 2. Configure the global env before instantiating the filters
    // This allows SecurityAccessFilter to read these credentials in its constructor
    env.put('FEATHER_SECRET', secret);
    env.put('FEATHER_ACCESS', access);
    env.put('STORAGE_PATH', './uploads_test');

    await FeatherIO.start();
  });

  tearDownAll(() async {
    await Winter.close(force: true);
  });

  Uri url(String path) => Uri.parse(localUrl + path);

  Map<String, String> authHeaders = {
    'FEATHER_SECRET': secret,
    'FEATHER_ACCESS': access,
  };

  Map<String, String> wrongAuthHeaders = {
    'FEATHER_SECRET': 'wrong',
    'FEATHER_ACCESS': 'wrong',
  };

  group('S3Controller - Full Flow (Real-like)', () {
    test('1. PUT /s3/{key} - Should fail without headers (401)', () async {
      final response = await http.put(url('/s3/test.jpg'), body: 'data');
      expect(response.statusCode, 401);
    });

    test('1. PUT /s3/{key} - Should fail with wrong headers (403)', () async {
      final response = await http.put(
        url('/s3/test.jpg'),
        body: 'data',
        headers: wrongAuthHeaders,
      );
      expect(response.statusCode, 403);
    });

    test('2. PUT /s3/{key} - Should upload file with auth (200)', () async {
      final testFile = File('test/test-file.jpg');
      final bytes = await testFile.readAsBytes();

      final response = await http.put(
        url('/s3/test-file.jpg'),
        headers: authHeaders,
        body: bytes,
      );

      expect(response.statusCode, 200);
      expect(response.body, contains('File uploaded successfully'));
    });

    test('3. GET /s3/list - Should fail without headers (401)', () async {
      final response = await http.get(url('/s3/list'));
      expect(response.statusCode, 401);
    });

    test('3. GET /s3/list - Should fail with wrong headers (403)', () async {
      final response = await http.get(
        url('/s3/list'),
        headers: wrongAuthHeaders,
      );
      expect(response.statusCode, 403);
    });

    test('3. GET /s3/list - Should list file with auth (200)', () async {
      final response = await http.get(url('/s3/list'), headers: authHeaders);

      expect(response.statusCode, 200);
      expect(response.body, contains('test-file.jpg'));
    });

    test(
      '4. GET /s3/{key} - Should download WITHOUT auth (Whitelist/Public)',
      () async {
        final response = await http.get(url('/s3/test-file.jpg'));

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], 'image/jpeg');

        // We validate that the content is identical to the original
        final originalBytes = await File('test/test-file.jpg').readAsBytes();
        expect(response.bodyBytes, originalBytes);
      },
    );

    test(
      '5. GET /s3/{key} - Should download with wrong auth (Whitelist/Public)',
      () async {
        final response = await http.get(
          url('/s3/test-file.jpg'),
          headers: wrongAuthHeaders,
        );

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], 'image/jpeg');

        // We validate that the content is identical to the original
        final originalBytes = await File('test/test-file.jpg').readAsBytes();
        expect(response.bodyBytes, originalBytes);
      },
    );

    test(
      '5. GET /s3/{key} - Should download with correct auth (Whitelist/Public)',
      () async {
        final response = await http.get(
          url('/s3/test-file.jpg'),
          headers: authHeaders,
        );

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], 'image/jpeg');

        final originalBytes = await File('test/test-file.jpg').readAsBytes();
        expect(response.bodyBytes, originalBytes);
      },
    );

    test('6. DELETE /s3/{key} - Should fail without headers (401)', () async {
      final response = await http.delete(url('/s3/test-file.jpg'));
      expect(response.statusCode, 401);
    });

    test(
      '6. DELETE /s3/{key} - Should fail with wrong headers (403)',
      () async {
        final response = await http.delete(
          url('/s3/test-file.jpg'),
          headers: wrongAuthHeaders,
        );
        expect(response.statusCode, 403);
      },
    );

    test('7. DELETE /s3/{key} - Should delete with auth (200)', () async {
      final response = await http.delete(
        url('/s3/test-file.jpg'),
        headers: authHeaders,
      );

      expect(response.statusCode, 200);
      expect(response.body, contains('deleted successfully'));

      // We verify that it no longer exists
      final check = await http.get(url('/s3/test-file.jpg'));
      expect(check.statusCode, 404);
    });
  });
}
