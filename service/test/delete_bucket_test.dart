@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8092, name: 'delete_bucket');

  setUpAll(() async {
    env.put('RESERVED_BUCKET_NAMES', 'reserved-bucket');
    await server.start();
  });
  tearDownAll(server.stop);

  Future<bool> bucketExists(String name) =>
      Directory('${server.storagePath}/$name').exists();

  group('S3Controller - Delete Bucket', () {
    test('DELETE /{bucket} - Should delete an empty bucket (204)', () async {
      final create = await http.put(
        server.url('/empty-bucket'),
        headers: server.auth(),
      );
      expect(create.statusCode, 200);

      final response = await http.delete(
        server.url('/empty-bucket'),
        headers: server.auth(),
      );
      expect(response.statusCode, 204);
      expect(await bucketExists('empty-bucket'), isFalse);

      final list = await http.get(server.url('/'), headers: server.auth(json: true));
      expect((jsonDecode(list.body) as List).map((b) => b['name']), isNot(contains('empty-bucket')));
    });

    test('DELETE /{bucket} - Should delete a bucket signed with SigV4 (204)', () async {
      final create = await http.put(
        server.url('/sigv4-bucket'),
        headers: server.auth(),
      );
      expect(create.statusCode, 200);

      final response = await http.delete(
        server.url('/sigv4-bucket'),
        headers: server.sigV4('DELETE', '/sigv4-bucket'),
      );
      expect(response.statusCode, 204, reason: response.body);
      expect(await bucketExists('sigv4-bucket'), isFalse);
    });

    test('DELETE /{bucket} - Should reject a non-empty bucket (409)', () async {
      await server.putObject('full-bucket', 'file.txt', 'data');

      final response = await http.delete(
        server.url('/full-bucket'),
        headers: server.auth(),
      );
      expect(response.statusCode, 409);
      expect(response.body, contains('<Code>BucketNotEmpty</Code>'));
      expect(await bucketExists('full-bucket'), isTrue);
    });

    test('DELETE /{bucket} - Should return 404 for a non-existent bucket', () async {
      final response = await http.delete(
        server.url('/ghost-bucket'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchBucket');
    });

    test('DELETE /{bucket} - Should reject a reserved name (403)', () async {
      //un bucket reservado que ya existe en disco (creado antes de reservar el nombre)
      await Directory('${server.storagePath}/reserved-bucket').create(recursive: true);

      final response = await http.delete(
        server.url('/reserved-bucket'),
        headers: server.auth(),
      );
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>AccessDenied</Code>'));
      expect(await bucketExists('reserved-bucket'), isTrue);
    });

    test('DELETE /{bucket} - Should fail without auth (401)', () async {
      final response = await http.delete(server.url('/full-bucket'));
      expect(response.statusCode, 401);
      expect(await bucketExists('full-bucket'), isTrue);
    });

    test('DELETE /{bucket} - Should reject an invalid name (400)', () async {
      final response = await http.delete(
        server.url('/INVALID_BUCKET'),
        headers: server.auth(),
      );
      expect(response.statusCode, 400);
    });
  });
}
