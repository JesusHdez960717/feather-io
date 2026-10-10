@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8083, name: 'get_test');
  const bucket = 'get-bucket';

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'test.txt', 'content');
    await server.putObject(bucket, 'image.png', 'png');
    await server.putObject(bucket, 'no-extension', 'abcdef');
  });

  String md5Of(String content) => md5.convert(utf8.encode(content)).toString();

  Future<http.Response> getRange(String key, String range) => http.get(
    server.url('/$bucket/$key'),
    headers: {...server.auth(), 'range': range},
  );
  tearDownAll(server.stop);

  group('S3Controller - GET Object', () {
    test('Should download successfully with auth', () async {
      final response = await http.get(
        server.url('/$bucket/test.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.body, 'content');
      expect(response.headers['content-type'], contains('text/plain'));
      expect(response.headers['content-length'], '7');
    });

    test('Should send the content type of the file', () async {
      final response = await http.get(
        server.url('/$bucket/image.png'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'image/png');
    });

    test('Should fail without auth (401)', () async {
      final response = await http.get(server.url('/$bucket/test.txt'));
      expect(response.statusCode, 401);
    });

    test('Should return 404 for non-existent file', () async {
      final response = await http.get(
        server.url('/$bucket/notfound.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchKey</Code>'));
    });

    test('Should return 404 for non-existent bucket', () async {
      final response = await http.get(
        server.url('/other-bucket/test.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
    });

    test('Should return 400 for invalid bucket name', () async {
      final response = await http.get(
        server.url('/INVALID_BUCKET/test.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 400);
    });

    test('Should return 400 for invalid key', () async {
      final response = await http.get(
        server.url('/$bucket/invalid:name'),
        headers: server.auth(),
      );
      expect(response.statusCode, 400);
    });
  });

  group('S3Controller - HEAD Object', () {
    test('Should answer the headers without the body', () async {
      final response = await http.head(
        server.url('/$bucket/test.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.body, isEmpty);
      expect(response.headers['content-length'], '7');
      expect(response.headers['content-type'], contains('text/plain'));
      expect(HttpDate.parse(response.headers['last-modified']!), isA<DateTime>());
    });

    test('Should send Last-Modified on GET too', () async {
      final response = await http.get(
        server.url('/$bucket/test.txt'),
        headers: server.auth(),
      );
      expect(response.headers['last-modified'], isNotNull);
    });

    test('Should answer an object without extension as octet-stream', () async {
      final response = await http.head(
        server.url('/$bucket/no-extension'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'application/octet-stream');
      expect(response.headers['content-length'], '6');
    });

    test('Should send the ETag (md5 of the content)', () async {
      final response = await http.head(
        server.url('/$bucket/test.txt'),
        headers: server.auth(),
      );
      expect(response.headers['etag'], '"${md5Of('content')}"');
      expect(response.headers['accept-ranges'], 'bytes');
    });

    test('Should return 404 for a missing object', () async {
      final response = await http.head(
        server.url('/$bucket/notfound.txt'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
    });

    test('Should fail without auth (401)', () async {
      final response = await http.head(server.url('/$bucket/test.txt'));
      expect(response.statusCode, 401);
    });
  });

  group('S3Controller - GET Object (no extension, ETag)', () {
    test('Should download an object without extension as octet-stream', () async {
      final response = await http.get(
        server.url('/$bucket/no-extension'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.body, 'abcdef');
      expect(response.headers['content-type'], 'application/octet-stream');
    });

    test('Should send the ETag (md5 of the content)', () async {
      final response = await http.get(
        server.url('/$bucket/test.txt'),
        headers: server.auth(),
      );
      expect(response.headers['etag'], '"${md5Of('content')}"');
    });

    test('Should recompute the ETag when the file changes outside', () async {
      await server.putObject(bucket, 'changes.txt', 'before');
      // Another size, so it doesn't depend on the disk's date precision
      await File(
        '${server.storagePath}/$bucket/changes.txt',
      ).writeAsString('after');

      final response = await http.head(
        server.url('/$bucket/changes.txt'),
        headers: server.auth(),
      );
      expect(response.headers['etag'], '"${md5Of('after')}"');
    });
  });

  group('S3Controller - GET Object (Range)', () {
    test('Should answer a closed range with 206', () async {
      final response = await getRange('no-extension', 'bytes=1-3');
      expect(response.statusCode, 206);
      expect(response.body, 'bcd');
      expect(response.headers['content-range'], 'bytes 1-3/6');
      expect(response.headers['content-length'], '3');
      expect(response.headers['etag'], '"${md5Of('abcdef')}"');
    });

    test('Should answer an open range up to the end', () async {
      final response = await getRange('no-extension', 'bytes=4-');
      expect(response.statusCode, 206);
      expect(response.body, 'ef');
      expect(response.headers['content-range'], 'bytes 4-5/6');
    });

    test('Should answer the last bytes with a suffix range', () async {
      final response = await getRange('no-extension', 'bytes=-2');
      expect(response.statusCode, 206);
      expect(response.body, 'ef');
      expect(response.headers['content-range'], 'bytes 4-5/6');
    });

    test('Should cut a range that goes past the end', () async {
      final response = await getRange('no-extension', 'bytes=2-100');
      expect(response.statusCode, 206);
      expect(response.body, 'cdef');
      expect(response.headers['content-range'], 'bytes 2-5/6');
    });

    test('Should answer the whole object for a suffix bigger than it', () async {
      final response = await getRange('no-extension', 'bytes=-100');
      expect(response.statusCode, 206);
      expect(response.body, 'abcdef');
      expect(response.headers['content-range'], 'bytes 0-5/6');
    });

    test('Should reject a range that starts after the end (416)', () async {
      final response = await getRange('no-extension', 'bytes=6-');
      expect(response.statusCode, 416);
      expect(response.body, contains('<Code>InvalidRange</Code>'));
    });

    test('Should ignore a malformed range and answer everything', () async {
      for (final range in ['bytes=3-1', 'bytes=0-1,3-4', 'items=0-1']) {
        final response = await getRange('no-extension', range);
        expect(response.statusCode, 200, reason: range);
        expect(response.body, 'abcdef', reason: range);
      }
    });

    test('Should send only the headers of the range on HEAD', () async {
      final response = await http.head(
        server.url('/$bucket/no-extension'),
        headers: {...server.auth(), 'range': 'bytes=0-1'},
      );
      expect(response.statusCode, 206);
      expect(response.body, isEmpty);
      expect(response.headers['content-range'], 'bytes 0-1/6');
    });
  });

  group('S3Controller - GET Object (response-* overrides)', () {
    test('Should override the response headers from the query', () async {
      final response = await http.get(
        server.url(
          '/$bucket/test.txt?response-content-type=application/pdf'
          '&response-content-disposition=attachment%3B%20filename%3D%22a.pdf%22'
          '&response-cache-control=no-cache',
        ),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'application/pdf');
      expect(response.headers['content-disposition'], 'attachment; filename="a.pdf"');
      expect(response.headers['cache-control'], 'no-cache');
      expect(response.body, 'content');
    });

    test('Should ignore the overrides of an anonymous request', () async {
      final rule = await http.post(
        server.url('/_admin/bucket/$bucket/anonymous-access'),
        headers: {...server.auth(json: true), 'content-type': 'application/json'},
        body: jsonEncode({'prefix': 'test.txt', 'access': 'readOnly'}),
      );
      expect(rule.statusCode, anyOf(200, 201), reason: rule.body);

      final response = await http.get(
        server.url('/$bucket/test.txt?response-content-type=application/pdf'),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('text/plain'));
    });
  });
}
