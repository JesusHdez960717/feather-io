@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import '../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8095, name: 'empty_bucket');

  setUpAll(server.start);
  tearDownAll(server.stop);

  String admin(String path) => '/${env.adminPrefix}$path';

  Future<http.Response> empty(String name, {bool auth = true}) => http.delete(
    server.url(admin('/bucket/$name/objects')),
    headers: auth ? server.auth() : {},
  );

  group('AdminController - Empty Bucket', () {
    test('Should delete every object and keep the bucket, metadata and rules', () async {
      final create = await http.put(
        server.url('/full-bucket'),
        headers: {...server.auth(), 'content-type': 'application/json'},
        body: jsonEncode({'description': 'Stays'}),
      );
      expect(create.statusCode, 200);
      await server.putObject('full-bucket', 'a.txt', 'a');
      await server.putObject('full-bucket', 'deep/folder/b.txt', 'b');
      final rule = await http.post(
        server.url(admin('/bucket/full-bucket/anonymous-access')),
        headers: {...server.auth(), 'content-type': 'application/json'},
        body: jsonEncode({'prefix': 'public/', 'access': 'readOnly'}),
      );
      expect(rule.statusCode, 200);

      final response = await empty('full-bucket');
      expect(response.statusCode, 204);

      final dir = Directory('${server.storagePath}/full-bucket');
      expect(await dir.exists(), isTrue);
      expect(await dir.list().isEmpty, isTrue);

      final bucket = await http.get(
        server.url(admin('/bucket/full-bucket')),
        headers: server.auth(),
      );
      final body = jsonDecode(bucket.body);
      expect(body['object_count'], 0);
      expect(body['description'], 'Stays');

      final rules = await http.get(
        server.url(admin('/bucket/full-bucket/anonymous-access')),
        headers: server.auth(),
      );
      expect((jsonDecode(rules.body) as List).single['prefix'], 'public/');
    });

    test('Should allow deleting the bucket once it is empty', () async {
      await server.putObject('then-delete', 'a.txt', 'a');
      expect((await empty('then-delete')).statusCode, 204);

      final delete = await http.delete(
        server.url('/then-delete'),
        headers: server.auth(),
      );
      expect(delete.statusCode, 204);
    });

    test('Should succeed on an already empty bucket', () async {
      final create = await http.put(server.url('/nothing-here'), headers: server.auth());
      expect(create.statusCode, 200);
      expect((await empty('nothing-here')).statusCode, 204);
    });

    test('Should return 404 for a non-existent bucket', () async {
      final response = await empty('ghost-bucket');
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchBucket');
    });

    test('Should fail without auth (401)', () async {
      await server.putObject('guarded', 'a.txt', 'a');
      final response = await empty('guarded', auth: false);
      expect(response.statusCode, 401);
      expect(await File('${server.storagePath}/guarded/a.txt').exists(), isTrue);
    });
  });
}
