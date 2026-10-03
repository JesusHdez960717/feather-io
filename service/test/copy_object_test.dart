@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8098, name: 'copy_object');
  const bucket = 'copy-bucket';

  String rulesPath(String name) =>
      '/${env.adminPrefix}/bucket/$name/anonymous-access';

  Future<http.Response> copy(
    String targetKey,
    String source, {
    String targetBucket = bucket,
    Map<String, String>? headers,
  }) {
    return http.put(
      server.url('/$targetBucket/$targetKey'),
      headers: {...(headers ?? server.auth()), 'x-amz-copy-source': source},
    );
  }

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'source/report.pdf', 'content');
    await server.putObject('other-bucket', 'base.txt', 'base');
  });
  tearDownAll(server.stop);

  group('S3Controller - CopyObject (x-amz-copy-source)', () {
    test('Should copy an object and keep the source', () async {
      final response = await copy('target/report.pdf', '/$bucket/source/report.pdf');
      expect(response.statusCode, 200);
      expect(response.body, contains('<CopyObjectResult'));
      expect(response.body, contains('<LastModified>'));
      expect(
        response.body,
        contains('<ETag>&quot;${md5.convert(utf8.encode('content'))}&quot;</ETag>'),
      );

      expect(
        await File('${server.storagePath}/$bucket/target/report.pdf').readAsString(),
        'content',
      );
      expect(
        await File('${server.storagePath}/$bucket/source/report.pdf').exists(),
        isTrue,
      );
    });

    test('Should answer the copied object in JSON when accepted', () async {
      final response = await copy(
        'copy.pdf',
        '/$bucket/source/report.pdf',
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['key'], 'copy.pdf');
      expect(body['size_bytes'], 'content'.length);
    });

    test('Should copy between buckets and accept a URL-encoded source', () async {
      final response = await copy('copied%20from%20other.txt', 'other-bucket/base.txt');
      expect(response.statusCode, 200);
      expect(
        await File('${server.storagePath}/$bucket/copied from other.txt').readAsString(),
        'base',
      );
    });

    test('Should overwrite an existing target', () async {
      await server.putObject(bucket, 'overwrite.txt', 'old');
      expect((await copy('overwrite.txt', '/other-bucket/base.txt')).statusCode, 200);
      expect(await File('${server.storagePath}/$bucket/overwrite.txt').readAsString(), 'base');
    });

    test('Should return 404 for a missing source object', () async {
      final response = await copy('x.txt', '/$bucket/missing.txt', headers: server.auth(json: true));
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchKey');
    });

    test('Should return 404 for a missing target bucket', () async {
      final response = await copy(
        'copy.pdf',
        '/$bucket/source/report.pdf',
        targetBucket: 'missing',
      );
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchBucket</Code>'));
    });

    test('Should return 404 for a missing source bucket', () async {
      final response = await copy('x.txt', '/ghost-bucket/a.txt', headers: server.auth(json: true));
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchBucket');
    });

    test('Should reject copying an object onto itself without changes (400)', () async {
      final response = await copy('source/report.pdf', '/$bucket/source/report.pdf');
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>InvalidRequest</Code>'));
    });

    test('Should copy an object onto itself to change its metadata', () async {
      await server.putObject(bucket, 'same.txt', 'same');
      final response = await copy(
        'same.txt',
        '/$bucket/same.txt',
        headers: {
          ...server.auth(),
          'x-amz-metadata-directive': 'REPLACE',
          'content-type': 'text/csv',
        },
      );
      expect(response.statusCode, 200, reason: response.body);

      final head = await http.head(
        server.url('/$bucket/same.txt'),
        headers: server.auth(),
      );
      expect(head.headers['content-type'], 'text/csv');
      expect(
        await File('${server.storagePath}/$bucket/same.txt').readAsString(),
        'same',
      );
    });

    test('Should copy an object onto itself to change its storage class', () async {
      await server.putObject(bucket, 'same-class.txt', 'same');
      final response = await copy(
        'same-class.txt',
        '/$bucket/same-class.txt',
        headers: {...server.auth(), 'x-amz-storage-class': 'STANDARD_IA'},
      );
      expect(response.statusCode, 200, reason: response.body);
      final head = await http.head(
        server.url('/$bucket/same-class.txt'),
        headers: server.auth(),
      );
      expect(head.headers['x-amz-storage-class'], 'STANDARD_IA');
    });

    test('Should reject a malformed source (400)', () async {
      for (final source in ['/', 'only-bucket', '/$bucket/']) {
        final response = await copy('x.txt', source);
        expect(response.statusCode, 400, reason: source);
      }
    });

    test('Should reject a path traversal in the source (400)', () async {
      final response = await copy('x.txt', '/$bucket/..%2F..%2Fsecret.txt');
      expect(response.statusCode, 400);
    });

    test('Should fail without auth (401)', () async {
      final response = await copy('x.txt', '/$bucket/source/report.pdf', headers: {});
      expect(response.statusCode, 401);
    });

    test('Should not let an anonymous writer copy a private object (403)', () async {
      final rule = await http.post(
        server.url(rulesPath(bucket)),
        headers: {...server.auth(), 'content-type': 'application/json'},
        body: jsonEncode({'prefix': 'inbox/', 'access': 'writeOnly'}),
      );
      expect(rule.statusCode, 200);

      final response = await copy('inbox/stolen.pdf', '/$bucket/source/report.pdf', headers: {});
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>AccessDenied</Code>'));
      expect(await File('${server.storagePath}/$bucket/inbox/stolen.pdf').exists(), isFalse);
    });
  });

  group('S3Controller - CopyObject conditions', () {
    late String etag;

    setUpAll(() async {
      await server.putObject(bucket, 'conditions/source.txt', 'condition');
      etag = md5.convert(utf8.encode('condition')).toString();
    });

    Future<http.Response> copyIf(Map<String, String> conditions) => http.put(
      server.url('/$bucket/conditions/copy.txt'),
      headers: {
        ...server.auth(),
        'x-amz-copy-source': '/$bucket/conditions/source.txt',
        ...conditions,
      },
    );

    final past = HttpDate.format(DateTime.utc(2010, 3, 26));
    final future = HttpDate.format(DateTime.now().toUtc().add(const Duration(days: 1)));

    test('Should copy when the conditions hold', () async {
      for (final conditions in [
        {'x-amz-copy-source-if-match': '"$etag"'},
        {'x-amz-copy-source-if-match': '*'},
        {'x-amz-copy-source-if-none-match': '"other"'},
        {'x-amz-copy-source-if-modified-since': past},
        {'x-amz-copy-source-if-unmodified-since': future},
        // When if-match holds, if-unmodified-since doesn't count
        {
          'x-amz-copy-source-if-match': etag,
          'x-amz-copy-source-if-unmodified-since': past,
        },
      ]) {
        final response = await copyIf(conditions);
        expect(response.statusCode, 200, reason: '$conditions: ${response.body}');
      }
    });

    test('Should fail with 412 when a condition does not hold', () async {
      for (final conditions in [
        {'x-amz-copy-source-if-match': '"other"'},
        {'x-amz-copy-source-if-none-match': '"$etag"'},
        {'x-amz-copy-source-if-modified-since': future},
        {'x-amz-copy-source-if-unmodified-since': past},
      ]) {
        final response = await copyIf(conditions);
        expect(response.statusCode, 412, reason: '$conditions');
        expect(response.body, contains('<Code>PreconditionFailed</Code>'));
      }
    });

    test('Should ignore a date it does not understand', () async {
      final response = await copyIf({'x-amz-copy-source-if-modified-since': 'yesterday'});
      expect(response.statusCode, 200);
    });
  });
}
