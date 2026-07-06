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

    await FeatherIO.start(port: port);
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
    const bucket = 'my-test-bucket';

    test(
      '1. PUT /{bucket}/{key} - Should fail without headers (401)',
      () async {
        final response = await http.put(url('/$bucket/test.jpg'), body: 'data');
        expect(response.statusCode, 401);
      },
    );

    test(
      '1. PUT /{bucket}/{key} - Should fail with wrong headers (403)',
      () async {
        final response = await http.put(
          url('/$bucket/test.jpg'),
          body: 'data',
          headers: wrongAuthHeaders,
        );
        expect(response.statusCode, 403);
      },
    );

    test(
      '2. PUT /{bucket}/{key} - Should upload file with auth (200)',
      () async {
        final testFile = File('test/test-file.jpg');
        final bytes = await testFile.readAsBytes();

        final response = await http.put(
          url('/$bucket/test-file.jpg'),
          headers: authHeaders,
          body: bytes,
        );

        expect(response.statusCode, 200);
        expect(response.body, contains('File uploaded successfully'));
      },
    );

    test('3. GET /{bucket}/list - Should fail without headers (401)', () async {
      final response = await http.get(url('/$bucket/list'));
      expect(response.statusCode, 401);
    });

    test(
      '3. GET /{bucket}/list - Should fail with wrong headers (403)',
      () async {
        final response = await http.get(
          url('/$bucket/list'),
          headers: wrongAuthHeaders,
        );
        expect(response.statusCode, 403);
      },
    );

    test('3. GET /{bucket}/list - Should list file with auth (200)', () async {
      final response = await http.get(
        url('/$bucket/list'),
        headers: authHeaders,
      );

      expect(response.statusCode, 200);
      expect(response.body, contains('test-file.jpg'));
    });

    test(
      '4. GET /{bucket}/{key} - Should download WITHOUT auth (Whitelist/Public)',
      () async {
        final response = await http.get(url('/$bucket/test-file.jpg'));

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], 'image/jpeg');

        // We validate that the content is identical to the original
        final originalBytes = await File('test/test-file.jpg').readAsBytes();
        expect(response.bodyBytes, originalBytes);
      },
    );

    test(
      '5. GET /{bucket}/{key} - Should download with wrong auth (Whitelist/Public)',
      () async {
        final response = await http.get(
          url('/$bucket/test-file.jpg'),
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
      '5. GET /{bucket}/{key} - Should download with correct auth (Whitelist/Public)',
      () async {
        final response = await http.get(
          url('/$bucket/test-file.jpg'),
          headers: authHeaders,
        );

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], 'image/jpeg');

        final originalBytes = await File('test/test-file.jpg').readAsBytes();
        expect(response.bodyBytes, originalBytes);
      },
    );

    test(
      '6. DELETE /{bucket}/{key} - Should fail without headers (401)',
      () async {
        final response = await http.delete(url('/$bucket/test-file.jpg'));
        expect(response.statusCode, 401);
      },
    );

    test(
      '6. DELETE /{bucket}/{key} - Should fail with wrong headers (403)',
      () async {
        final response = await http.delete(
          url('/$bucket/test-file.jpg'),
          headers: wrongAuthHeaders,
        );
        expect(response.statusCode, 403);
      },
    );

    group('S3Controller - Multi-folder and Validations', () {
      test(
        '8. PUT /{bucket}/{key} - Should support multi-level folders (200)',
        () async {
          final key = 'files/test/deep/image.jpg';
          final response = await http.put(
            url('/$bucket/$key'),
            headers: authHeaders,
            body: 'image-data',
          );

          expect(response.statusCode, 200);
          expect(response.body, contains('File uploaded successfully'));

          // Verify listing shows the full path
          final listResponse = await http.get(
            url('/$bucket/list'),
            headers: authHeaders,
          );
          expect(listResponse.body, contains(key));

          // Verify download
          final getResponse = await http.get(url('/$bucket/$key'));
          expect(getResponse.statusCode, 200);
          expect(getResponse.body, 'image-data');
        },
      );

      test(
        '9. DELETE /{bucket}/{key} - Should clean up empty folders',
        () async {
          final key = 'temp/a/b/c/file.txt';
          // 1. Upload
          await http.put(
            url('/$bucket/$key'),
            headers: authHeaders,
            body: 'data',
          );

          // 2. Delete
          final delResponse = await http.delete(
            url('/$bucket/$key'),
            headers: authHeaders,
          );
          expect(delResponse.statusCode, 200);

          // 3. Verify physical cleanup (Internal check via listing other files)
          final listResponse = await http.get(
            url('/$bucket/list'),
            headers: authHeaders,
          );
          expect(listResponse.body, isNot(contains('temp/a/b/c')));
        },
      );

      test(
        '10. PUT /{bucket}/{key} - Should fail with invalid S3 characters (400)',
        () async {
          // Characters like < > : are forbidden by our new isValidKey
          final response = await http.put(
            url('/$bucket/invalid:name.jpg'),
            headers: authHeaders,
            body: 'data',
          );
          expect(response.statusCode, 400);
        },
      );

      test(
        '11. PUT /{bucket}/{key} - Should fail with Path Traversal attempt (400)',
        () async {
          // Usamos %2e (punto) para evitar que el cliente HTTP normalice la ruta
          // y así asegurar que los ".." lleguen al servidor para ser validados.
          final response = await http.put(
            url('/$bucket/%2e%2e/%2e%2e/etc/passwd.txt'),
            headers: authHeaders,
            body: 'data',
          );
          expect(response.statusCode, 200);
        },
      );

      test(
        '11b. PUT /{bucket}/{key} - Should allow keys that look like system paths but are internal (200)',
        () async {
          // Esta ruta es segura porque no contiene ".." para subir de nivel, 
          // es simplemente una carpeta llamada "etc" dentro del bucket.
          final key = 'etc/passwd.txt';
          final response = await http.put(
            url('/$bucket/$key'),
            headers: authHeaders,
            body: 'safe-data',
          );
          expect(response.statusCode, 200);

          final getResponse = await http.get(url('/$bucket/$key'));
          expect(getResponse.statusCode, 200);
          expect(getResponse.body, 'safe-data');
        },
      );

      test(
        '12. PUT /{bucket}/{key} - Should fail with invalid bucket name (400)',
        () async {
          final response = await http.put(
            url('/INVALID_BUCKET/file.txt'),
            headers: authHeaders,
            body: 'data',
          );
          expect(response.statusCode, 400);
        },
      );

      test(
        '13. GET /{bucket}/list - Should fail if bucket does not exist (404)',
        () async {
          final response = await http.get(
            url('/non-existent-bucket/list'),
            headers: authHeaders,
          );
          expect(response.statusCode, 404);
        },
      );
    });
  });
}
