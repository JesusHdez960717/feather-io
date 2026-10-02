@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8084, name: 'list_buckets');

  setUpAll(server.start);
  tearDownAll(server.stop);

  Future<List> listBuckets() async {
    final response = await http.get(
      server.url('/'),
      headers: server.auth(json: true),
    );
    expect(response.statusCode, 200);
    return jsonDecode(response.body) as List;
  }

  group('S3Controller - List Buckets', () {
    test('GET / - Should fail without auth (401)', () async {
      final response = await http.get(server.url('/'));
      expect(response.statusCode, 401);
    });

    test('GET / - Should return empty list initially (JSON)', () async {
      expect(await listBuckets(), isEmpty);
    });

    test('GET / - Should list buckets after upload (JSON)', () async {
      const content = 'Hello FeatherIO';
      await server.putObject('test-bucket-1', 'test.txt', content);

      final body = await listBuckets();
      expect(body.length, 1);
      expect(body[0]['name'], 'test-bucket-1');
      expect(body[0]['object_count'], 1);
      expect(body[0]['size_bytes'], content.length);
    });

    test('GET / - Should list multiple buckets and update stats (JSON)', () async {
      const content1 = 'Data 1';
      const content2 = 'Data 2 extended';
      await server.putObject('test-bucket-2', 'file1.txt', content1);
      await server.putObject('test-bucket-2', 'file2.txt', content2);

      final body = await listBuckets();
      expect(body.length, 2);
      final b2 = body.firstWhere((b) => b['name'] == 'test-bucket-2');
      expect(b2['object_count'], 2);
      expect(b2['size_bytes'], content1.length + content2.length);
    });

    test('GET / - Should include the metadata of created buckets', () async {
      final create = await http.put(
        server.url('/test-bucket-3'),
        headers: {...server.auth(), 'content-type': 'application/json'},
        body: jsonEncode({'description': 'Backups', 'color': 0xFF00FF00}),
      );
      expect(create.statusCode, 200);

      final b3 = (await listBuckets()).firstWhere((b) => b['name'] == 'test-bucket-3');
      expect(b3['description'], 'Backups');
      expect(b3['color'], 0xFF00FF00);
      expect(b3['object_count'], 0);
    });

    test('GET / - Should return XML by default', () async {
      final response = await http.get(server.url('/'), headers: server.auth());

      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/xml'));
      expect(response.body, contains('<ListAllMyBucketsResult'));
      expect(response.body, contains('<Name>test-bucket-1</Name>'));
      expect(response.body, contains('<ObjectCount>1</ObjectCount>'));
      expect(response.body, contains('<Owner>'));
      final creationDate = RegExp(
        r'<CreationDate>(.*?)</CreationDate>',
      ).firstMatch(response.body)!.group(1)!;
      expect(creationDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$')));
    });

    test('GET / - Should update stats after deleting a file', () async {
      final deleteResponse = await http.delete(
        server.url('/test-bucket-1/test.txt'),
        headers: server.auth(),
      );
      expect(deleteResponse.statusCode, 204);

      final b1 = (await listBuckets()).firstWhere((b) => b['name'] == 'test-bucket-1');
      expect(b1['object_count'], 0);
      expect(b1['size_bytes'], 0);
    });
  });
}
