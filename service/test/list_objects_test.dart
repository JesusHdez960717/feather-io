@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8085, name: 'list_objects');
  const bucket = 'list-bucket';

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'f1.txt', '1');
    await server.putObject(bucket, 'folder/f2.txt', '22');
  });
  tearDownAll(server.stop);

  group('S3Controller - LIST Objects', () {
    test('Should list objects in JSON', () async {
      final response = await http.get(
        server.url('/$bucket'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['name'], bucket);
      final contents = body['contents'] as List;
      expect(contents.map((e) => e['key']), unorderedEquals(['f1.txt', 'folder/f2.txt']));
      final f2 = contents.firstWhere((e) => e['key'] == 'folder/f2.txt');
      expect(f2['size_bytes'], 2);
    });

    test('Should group folders with prefix and delimiter', () async {
      final root = await http.get(
        server.url('/$bucket?delimiter=/'),
        headers: server.auth(json: true),
      );
      final rootBody = jsonDecode(root.body);
      expect((rootBody['contents'] as List).map((e) => e['key']), ['f1.txt']);
      expect(rootBody['common_prefixes'], ['folder/']);

      final folder = await http.get(
        server.url('/$bucket?prefix=folder/&delimiter=/'),
        headers: server.auth(json: true),
      );
      final folderBody = jsonDecode(folder.body);
      expect((folderBody['contents'] as List).map((e) => e['key']), ['folder/f2.txt']);
      expect(folderBody['common_prefixes'], isEmpty);
    });

    test('Should list objects in XML by default', () async {
      final response = await http.get(
        server.url('/$bucket'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/xml'));
      expect(response.body, contains('<ListBucketResult'));
      expect(response.body, contains('<Key>f1.txt</Key>'));
      expect(response.body, contains('<Key>folder/f2.txt</Key>'));
    });

    test('Should return an empty list for an empty prefix', () async {
      final response = await http.get(
        server.url('/$bucket?prefix=nothing/'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body)['contents'], isEmpty);
    });

    test('Should fail without auth (401)', () async {
      final response = await http.get(server.url('/$bucket'));
      expect(response.statusCode, 401);
    });

    test('Should fail with an invalid token (401)', () async {
      final response = await http.get(
        server.url('/$bucket'),
        headers: {'authorization': 'Bearer not-a-jwt'},
      );
      expect(response.statusCode, 401);
    });

    test('Should return 404 if bucket does not exist', () async {
      final response = await http.get(
        server.url('/no-bucket'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchBucket</Code>'));
    });
  });
}
