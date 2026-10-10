@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../../support/test_server.dart';

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

  group('S3Controller - LIST Objects of a folder', () {
    const tree = 'list-tree';

    setUpAll(() async {
      for (final key in [
        'a.txt',
        'docs/x.txt',
        'docs/2026/y.txt',
        'docs/2026/z/w.txt',
        'deep/only/inner.txt',
      ]) {
        await server.putObject(tree, key, key);
      }
      final folder = await http.put(
        server.url('/$tree/photos/'),
        headers: server.auth(),
      );
      expect(folder.statusCode, 200);
      // A folder left without files (not created through the service)
      Directory('${server.storagePath}/$tree/empty/sub').createSync(recursive: true);
    });

    Future<Map<String, dynamic>> list(String query) async {
      final response = await http.get(
        server.url('/$tree?$query'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 200, reason: response.body);
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    List<Object?> keys(Map<String, dynamic> body) =>
        (body['contents'] as List).map((e) => e['key']).toList();

    test('Should list one level with the delimiter, folders without files left out', () async {
      final body = await list('delimiter=/');
      expect(keys(body), ['a.txt']);
      expect(body['common_prefixes'], ['deep/', 'docs/', 'photos/']);
    });

    test('Should list the level of a folder and its subfolders as prefixes', () async {
      final body = await list('prefix=docs/&delimiter=/');
      expect(keys(body), ['docs/x.txt']);
      expect(body['common_prefixes'], ['docs/2026/']);
    });

    test('Should match a prefix that ends in the middle of a name', () async {
      final body = await list('prefix=docs/20&delimiter=/');
      expect(keys(body), isEmpty);
      expect(body['common_prefixes'], ['docs/2026/']);
    });

    test('Should list every key below a prefix without delimiter', () async {
      final body = await list('prefix=docs/');
      expect(keys(body), ['docs/2026/y.txt', 'docs/2026/z/w.txt', 'docs/x.txt']);
    });

    test('Should list nothing for a folder that does not exist', () async {
      final body = await list('prefix=nope/&delimiter=/');
      expect(keys(body), isEmpty);
      expect(body['common_prefixes'], isEmpty);
    });

    test('Should never leave the bucket with a prefix that climbs up', () async {
      for (final prefix in ['../', '../$bucket/', 'docs/../../$bucket/']) {
        final body = await list('prefix=${Uri.encodeQueryComponent(prefix)}');
        expect(keys(body), isEmpty, reason: prefix);
      }
    });

    test('Should page over objects and prefixes of one level together', () async {
      final seen = <String>[];
      String? token;
      do {
        final body = await list(
          'list-type=2&delimiter=/&max-keys=1'
          '${token == null ? '' : '&continuation-token=$token'}',
        );
        seen
          ..addAll(keys(body).cast<String>())
          ..addAll((body['common_prefixes'] as List).cast<String>());
        token = body['next_continuation_token'] as String?;
      } while (token != null);
      expect(seen, ['a.txt', 'deep/', 'docs/', 'photos/']);
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

    test('Should report the V2 pagination in the XML', () async {
      final response = await http.get(
        server.url('/$pageBucket?list-type=2&max-keys=1'),
        headers: server.auth(),
      );
      expect(response.body, contains('<IsTruncated>true</IsTruncated>'));
      expect(response.body, contains('<MaxKeys>1</MaxKeys>'));
      expect(response.body, contains('<KeyCount>1</KeyCount>'));
      expect(response.body, contains('<NextContinuationToken>'));
      expect(response.body, isNot(contains('<NextMarker>')));
    });

    Future<String> xmlPage(String query) async {
      final response = await http.get(
        server.url('/$pageBucket?$query'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200, reason: response.body);
      return response.body;
    }

    List<String> xmlKeys(String xml) => RegExp(r'<Key>(.*?)</Key>')
        .allMatches(xml)
        .map((m) => m.group(1)!)
        .toList();

    test('Should walk every key with the V1 marker and NextMarker', () async {
      final keys = <String>[];
      String? marker;
      for (var i = 0; i < 10; i++) {
        final xml = await xmlPage(
          'max-keys=2${marker == null ? '' : '&marker=${Uri.encodeQueryComponent(marker)}'}',
        );
        expect(xml, isNot(contains('<KeyCount>')));
        expect(xml, contains('<Marker>${marker ?? ''}</Marker>'));
        keys.addAll(xmlKeys(xml));
        if (!xml.contains('<IsTruncated>true</IsTruncated>')) break;
        marker = RegExp(r'<NextMarker>(.*?)</NextMarker>').firstMatch(xml)!.group(1);
      }
      expect(keys, ['a.txt', 'b.txt', 'c/1.txt', 'd.txt', 'e.txt']);
    });

    test('Should start after start-after in V2', () async {
      final xml = await xmlPage('list-type=2&start-after=c/1.txt');
      expect(xmlKeys(xml), ['d.txt', 'e.txt']);
      expect(xml, contains('<StartAfter>c/1.txt</StartAfter>'));
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

  group('S3Controller - LIST Objects encoding-type=url', () {
    const encBucket = 'list-encoding';

    setUpAll(() async {
      await server.putObject(encBucket, 'folder with space/a+b%c.txt', 'x');
    });

    test('Should URL-encode the keys, keeping the slashes', () async {
      final response = await http.get(
        server.url('/$encBucket?list-type=2&encoding-type=url'),
        headers: server.auth(),
      );
      expect(response.body, contains('<EncodingType>url</EncodingType>'));
      expect(
        response.body,
        contains('<Key>folder%20with%20space/a%2Bb%25c.txt</Key>'),
      );
    });

    test('Should URL-encode the common prefixes', () async {
      final response = await http.get(
        server.url('/$encBucket?delimiter=/&encoding-type=url'),
        headers: server.auth(),
      );
      expect(response.body, contains('<Prefix>folder%20with%20space/</Prefix>'));
    });

    test('Should not encode without encoding-type', () async {
      final response = await http.get(
        server.url('/$encBucket?list-type=2'),
        headers: server.auth(),
      );
      expect(response.body, contains('<Key>folder with space/a+b%c.txt</Key>'));
      expect(response.body, isNot(contains('<EncodingType>')));
    });
  });
}
