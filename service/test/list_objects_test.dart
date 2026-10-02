@TestOn('vm')
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
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

    test('Should send the ETag and a UTC LastModified in the XML', () async {
      final response = await http.get(
        server.url('/$bucket?prefix=f1'),
        headers: server.auth(),
      );
      final contents = RegExp(
        r'<Contents>(.*?)</Contents>',
        dotAll: true,
      ).firstMatch(response.body)!.group(1)!;
      expect(
        contents,
        contains('<ETag>&quot;${md5.convert(utf8.encode('1'))}&quot;</ETag>'),
      );
      final lastModified = RegExp(
        r'<LastModified>(.*?)</LastModified>',
      ).firstMatch(contents)!.group(1)!;
      expect(lastModified, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$')));
    });

    test('Should send the ETag in JSON', () async {
      final response = await http.get(
        server.url('/$bucket?prefix=folder/'),
        headers: server.auth(json: true),
      );
      final contents = jsonDecode(response.body)['contents'] as List;
      expect(contents.single['etag'], md5.convert(utf8.encode('22')).toString());
    });

    test('Should escape the XML special chars of the keys', () async {
      await server.putObject(bucket, 'a&b.txt', 'x');
      final response = await http.get(
        server.url('/$bucket?prefix=a'),
        headers: server.auth(),
      );
      expect(response.body, contains('<Key>a&amp;b.txt</Key>'));
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

  group('S3Controller - LIST Objects pagination', () {
    const pageBucket = 'page-bucket';

    setUpAll(() async {
      for (final key in ['a.txt', 'b.txt', 'c/1.txt', 'd.txt', 'e.txt']) {
        await server.putObject(pageBucket, key, key);
      }
    });

    Future<Map<String, dynamic>> page(String query) async {
      final response = await http.get(
        server.url('/$pageBucket?$query'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 200, reason: response.body);
      return jsonDecode(response.body);
    }

    List<String> keysOf(Map<String, dynamic> body) => [
      ...(body['contents'] as List).map((e) => e['key'] as String),
      ...(body['common_prefixes'] as List).cast<String>(),
    ]..sort();

    test('Should walk every key in order with max-keys and the token', () async {
      final seen = <String>[];
      String? token;
      var pages = 0;
      do {
        final body = await page(
          'delimiter=/&max-keys=2${token == null ? '' : '&continuation-token=$token'}',
        );
        expect(body['max_keys'], 2);
        expect(body['key_count'], lessThanOrEqualTo(2));
        expect(body['total_keys'], 5);
        seen.addAll(keysOf(body));
        token = body['next_continuation_token'];
        expect(body['is_truncated'], token != null);
        pages++;
      } while (token != null);

      expect(pages, 3);
      expect(seen, ['a.txt', 'b.txt', 'c/', 'd.txt', 'e.txt']);
    });

    test('Should not be truncated when everything fits', () async {
      final body = await page('delimiter=/');
      expect(body['is_truncated'], isFalse);
      expect(body['next_continuation_token'], isNull);
      expect(body['max_keys'], 1000);
      expect(body['key_count'], 5);
    });

    test('Should cap max-keys at 1000', () async {
      final body = await page('max-keys=5000');
      expect(body['max_keys'], 1000);
    });

    test('Should report the pagination in the XML', () async {
      final response = await http.get(
        server.url('/$pageBucket?max-keys=1'),
        headers: server.auth(),
      );
      expect(response.body, contains('<IsTruncated>true</IsTruncated>'));
      expect(response.body, contains('<MaxKeys>1</MaxKeys>'));
      expect(response.body, contains('<KeyCount>1</KeyCount>'));
      expect(response.body, contains('<NextContinuationToken>'));
    });

    test('Should reject an invalid max-keys (400)', () async {
      for (final value in ['-1', 'abc']) {
        final response = await http.get(
          server.url('/$pageBucket?max-keys=$value'),
          headers: server.auth(json: true),
        );
        expect(response.statusCode, 400, reason: value);
        expect(jsonDecode(response.body)['code'], 'InvalidArgument');
      }
    });

    test('Should reject an invalid continuation-token (400)', () async {
      final response = await http.get(
        server.url('/$pageBucket?continuation-token=%%%'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 400);
    });
  });
}
