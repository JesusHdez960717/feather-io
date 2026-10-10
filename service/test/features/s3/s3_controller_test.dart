@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8090, name: 'main_test');

  setUpAll(server.start);
  tearDownAll(server.stop);

  group('S3Controller - Happy Path Flow', () {
    const bucket = 'main-bucket';
    const key = 'test-file.txt';
    const content = 'Hello World';

    test('0. PUT /{bucket} - Should create the bucket', () async {
      final response = await http.put(
        server.url('/$bucket'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.headers['location'], '/$bucket');
    });

    test('1. PUT - Should upload successfully', () async {
      final response = await http.put(
        server.url('/$bucket/$key'),
        headers: server.auth(),
        body: content,
      );
      expect(response.statusCode, 200);
    });

    test('2. GET /{bucket} - Should find the uploaded file', () async {
      final response = await http.get(
        server.url('/$bucket'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 200);
      final contents = jsonDecode(response.body)['contents'] as List;
      expect(contents.map((e) => e['key']), contains(key));
    });

    test('3. GET /{key} - Should download the file content', () async {
      final response = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.body, content);
    });

    test('4. DELETE - Should remove the file', () async {
      final response = await http.delete(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(response.statusCode, 204);

      final verify = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(verify.statusCode, 404);
    });
  });
}
