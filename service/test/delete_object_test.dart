@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8082, name: 'delete_test');

  setUpAll(server.start);
  tearDownAll(server.stop);

  group('S3Controller - DELETE Object', () {
    const bucket = 'delete-bucket';

    test('Should delete file successfully', () async {
      const key = 'todelete.txt';
      await server.putObject(bucket, key, 'data');

      final response = await http.delete(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(response.statusCode, 204);

      final getResponse = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(getResponse.statusCode, 404);
    });

    test('Should clean up empty parent folders after delete', () async {
      const key = 'a/b/c/file.txt';
      await server.putObject(bucket, key, 'data');
      await server.putObject(bucket, 'keep.txt', 'data');

      await http.delete(server.url('/$bucket/$key'), headers: server.auth());

      expect(await Directory('${server.storagePath}/$bucket/a').exists(), isFalse);
      final listResponse = await http.get(
        server.url('/$bucket'),
        headers: server.auth(json: true),
      );
      final contents = jsonDecode(listResponse.body)['contents'] as List;
      expect(contents.map((e) => e['key']), ['keep.txt']);
    });

    test('Should succeed if file does not exist (204, idempotent)', () async {
      final response = await http.delete(
        server.url('/$bucket/non-existent.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 204);
    });

    test('Should fail without auth (401)', () async {
      final response = await http.delete(server.url('/$bucket/keep.txt'));
      expect(response.statusCode, 401);
      expect(await File('${server.storagePath}/$bucket/keep.txt').exists(), isTrue);
    });

    test('Should fail with invalid key (400)', () async {
      final response = await http.delete(
        server.url('/$bucket/invalid:name'),
        headers: server.auth(),
      );
      expect(response.statusCode, 400);
    });
  });

  group('S3Controller - Multi-delete Objects', () {
    const bucket = 'multi-delete-bucket';

    test('Should delete several objects', () async {
      await server.putObject(bucket, 'one.txt', '1');
      await server.putObject(bucket, 'two.txt', '2');

      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: server.auth(json: true),
        body: jsonEncode({
          'objects': [
            {'key': 'one.txt'},
            {'key': 'two.txt'},
          ],
        }),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect((body['deleted'] as List).map((e) => e['key']), ['one.txt', 'two.txt']);
      expect(body['errors'], isEmpty);
    });

    test('Should report invalid keys with their S3 code', () async {
      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: server.auth(json: true),
        body: jsonEncode({
          'objects': [
            {'key': 'invalid:name'},
          ],
        }),
      );
      expect(response.statusCode, 200);
      final error = (jsonDecode(response.body)['errors'] as List).single;
      expect(error['key'], 'invalid:name');
      expect(error['code'], 'InvalidArgument');
    });

    test('Should require the ?delete parameter (400)', () async {
      final response = await http.post(
        server.url('/$bucket'),
        headers: server.auth(json: true),
        body: jsonEncode({'objects': []}),
      );
      expect(response.statusCode, 400);
      expect(jsonDecode(response.body)['code'], 'InvalidRequest');
    });

    test('Should reject an invalid body (400)', () async {
      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: server.auth(json: true),
        body: 'not json',
      );
      expect(response.statusCode, 400);
      expect(jsonDecode(response.body)['code'], 'InvalidRequest');
    });
  });
}
