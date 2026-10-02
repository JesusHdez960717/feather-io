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

    test('Should reject an invalid JSON body (400)', () async {
      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: {...server.auth(json: true), 'content-type': 'application/json'},
        body: 'not json',
      );
      expect(response.statusCode, 400);
      expect(jsonDecode(response.body)['code'], 'InvalidRequest');
    });

    test('Should reject a body that is neither JSON nor <Delete> (400)', () async {
      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: server.auth(),
        body: 'not xml',
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>MalformedXML</Code>'));
    });
  });

  group('S3Controller - Multi-delete Objects (S3 XML)', () {
    const bucket = 'multi-delete-xml';

    String deleteXml(List<String> keys, {bool quiet = false}) =>
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Delete xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
        '${quiet ? '<Quiet>true</Quiet>' : ''}'
        '${keys.map((k) => '<Object><Key>$k</Key></Object>').join()}'
        '</Delete>';

    test('Should delete several objects and answer the S3 XML', () async {
      await server.putObject(bucket, 'one.txt', '1');
      await server.putObject(bucket, 'a&b.txt', '2');

      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: {...server.auth(), 'content-type': 'application/xml'},
        body: deleteXml(['one.txt', 'a&amp;b.txt']),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(response.headers['content-type'], contains('application/xml'));
      expect(response.body, contains('<DeleteResult'));
      expect(response.body, contains('<Deleted><Key>one.txt</Key></Deleted>'));
      expect(response.body, contains('<Deleted><Key>a&amp;b.txt</Key></Deleted>'));
      expect(await File('${server.storagePath}/$bucket/one.txt').exists(), isFalse);
      expect(await File('${server.storagePath}/$bucket/a&b.txt').exists(), isFalse);
    });

    test('Should only list the errors in quiet mode', () async {
      await server.putObject(bucket, 'quiet.txt', '1');

      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: server.auth(),
        body: deleteXml(['quiet.txt', 'invalid:name'], quiet: true),
      );
      expect(response.statusCode, 200);
      expect(response.body, isNot(contains('<Deleted>')));
      expect(response.body, contains('<Key>invalid:name</Key>'));
      expect(response.body, contains('<Code>InvalidArgument</Code>'));
      expect(await File('${server.storagePath}/$bucket/quiet.txt').exists(), isFalse);
    });

    test('Should accept a request signed with SigV4', () async {
      await server.putObject(bucket, 'signed.txt', '1');

      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: server.sigV4('POST', '/$bucket', query: const {'delete': ''}),
        body: deleteXml(['signed.txt']),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(response.body, contains('<Deleted><Key>signed.txt</Key></Deleted>'));
    });

    test('Should reject more than 1000 keys (400)', () async {
      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: server.auth(),
        body: deleteXml([for (var i = 0; i < 1001; i++) 'k$i']),
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>MalformedXML</Code>'));
    });
  });
}
