@TestOn('vm')
library;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8083, name: 'get_test');
  const bucket = 'get-bucket';

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'test.txt', 'content');
    await server.putObject(bucket, 'image.png', 'png');
  });
  tearDownAll(server.stop);

  group('S3Controller - GET Object', () {
    test('Should download successfully with auth', () async {
      final response = await http.get(
        server.url('/$bucket/test.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.body, 'content');
      expect(response.headers['content-type'], contains('text/plain'));
      expect(response.headers['content-length'], '7');
    });

    test('Should send the content type of the file', () async {
      final response = await http.get(
        server.url('/$bucket/image.png'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'image/png');
    });

    test('Should fail without auth (401)', () async {
      final response = await http.get(server.url('/$bucket/test.txt'));
      expect(response.statusCode, 401);
    });

    test('Should return 404 for non-existent file', () async {
      final response = await http.get(
        server.url('/$bucket/notfound.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchKey</Code>'));
    });

    test('Should return 404 for non-existent bucket', () async {
      final response = await http.get(
        server.url('/other-bucket/test.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
    });

    test('Should return 400 for invalid bucket name', () async {
      final response = await http.get(
        server.url('/INVALID_BUCKET/test.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 400);
    });

    test('Should return 400 for invalid key', () async {
      final response = await http.get(
        server.url('/$bucket/invalid:name'),
        headers: server.auth(),
      );
      expect(response.statusCode, 400);
    });
  });
}
