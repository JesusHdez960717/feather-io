@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8106, name: 'aws_chunked');
  const bucket = 'chunked-bucket';
  const signature = 'ad80c730a21e5b8d04586a2213dd63b9a0e99e0e2307b0ade35a65485a288648';

  setUpAll(() async {
    await server.start();
    await server.createBucket(bucket);
  });
  tearDownAll(server.stop);

  /// The aws-chunked body of [parts], with a signature per chunk
  /// (`STREAMING-AWS4-…`) or with trailers (`STREAMING-UNSIGNED-PAYLOAD-TRAILER`).
  String encode(List<String> parts, {bool trailer = false}) {
    final buffer = StringBuffer();
    for (final part in [...parts, '']) {
      final size = utf8.encode(part).length.toRadixString(16);
      buffer.write(trailer ? '$size\r\n' : '$size;chunk-signature=$signature\r\n');
      if (part.isNotEmpty) buffer.write('$part\r\n');
    }
    buffer.write(trailer ? 'x-amz-checksum-crc32:AAAAAA==\r\n\r\n' : '\r\n');
    return buffer.toString();
  }

  Map<String, String> chunkedHeaders({bool trailer = false}) => {
    ...server.auth(),
    'x-amz-content-sha256': trailer
        ? 'STREAMING-UNSIGNED-PAYLOAD-TRAILER'
        : 'STREAMING-AWS4-HMAC-SHA256-PAYLOAD',
    'content-encoding': 'aws-chunked',
  };

  Future<String> stored(String key) =>
      File('${server.storagePath}/$bucket/$key').readAsString();

  group('AwsChunkedDecoder - PutObject', () {
    test('Should store the content without the chunk signatures', () async {
      final response = await http.put(
        server.url('/$bucket/signed.txt'),
        headers: chunkedHeaders(),
        body: encode(['hello ', 'mundo']),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(await stored('signed.txt'), 'hello mundo');
      expect(
        response.headers['etag'],
        '"${md5.convert(utf8.encode('hello mundo'))}"',
      );
    });

    test('Should ignore the trailing checksums', () async {
      final response = await http.put(
        server.url('/$bucket/trailer.txt'),
        headers: chunkedHeaders(trailer: true),
        body: encode(['abc', 'def'], trailer: true),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(await stored('trailer.txt'), 'abcdef');
    });

    test('Should store an empty object', () async {
      final response = await http.put(
        server.url('/$bucket/empty.txt'),
        headers: chunkedHeaders(),
        body: encode([]),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(await stored('empty.txt'), '');
    });

    test('Should decode a body that arrives cut at any byte', () async {
      final bytes = utf8.encode(encode(['first chunk, ', 'second chunk']));
      final request = http.StreamedRequest('PUT', server.url('/$bucket/split.txt'))
        ..headers.addAll(chunkedHeaders())
        ..contentLength = bytes.length;
      final sent = request.send();
      // 3 bytes at a time: splits the size lines and the \r\n
      for (var i = 0; i < bytes.length; i += 3) {
        request.sink.add(bytes.sublist(i, i + 3 > bytes.length ? bytes.length : i + 3));
      }
      unawaited(request.sink.close());
      final response = await sent;
      expect(response.statusCode, 200);
      expect(await stored('split.txt'), 'first chunk, second chunk');
    });

    test('Should not store aws-chunked as the Content-Encoding', () async {
      await http.put(
        server.url('/$bucket/encoded.txt'),
        headers: {...chunkedHeaders(), 'content-encoding': 'aws-chunked,gzip'},
        body: encode(['x']),
      );
      final head = await http.head(
        server.url('/$bucket/encoded.txt'),
        headers: server.auth(),
      );
      expect(head.headers['content-encoding'], 'gzip');

      final head2 = await http.head(
        server.url('/$bucket/signed.txt'),
        headers: server.auth(),
      );
      expect(head2.headers['content-encoding'], isNull);
    });

    test('Should reject a malformed chunk size (400) and store nothing', () async {
      final response = await http.put(
        server.url('/$bucket/broken.txt'),
        headers: chunkedHeaders(),
        body: 'zz;chunk-signature=$signature\r\nabc\r\n',
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>IncompleteBody</Code>'));
      expect(await File('${server.storagePath}/$bucket/broken.txt').exists(), isFalse);
    });

    test('Should keep the previous object when an upload fails', () async {
      await server.putObject(bucket, 'keep.txt', 'original');
      final response = await http.put(
        server.url('/$bucket/keep.txt'),
        headers: chunkedHeaders(),
        body: 'zz\r\nroto\r\n',
      );
      expect(response.statusCode, 400);
      expect(await stored('keep.txt'), 'original');
    });

    test('Should not list the temporary folder as a bucket', () async {
      final response = await http.get(
        server.url('/'),
        headers: server.auth(json: true),
      );
      final names = (jsonDecode(response.body) as List).map((b) => b['name']);
      expect(names, isNot(contains('.tmp')));
      expect(await Directory('${server.storagePath}/.tmp').list().isEmpty, isTrue);
    });

    test('Should reject a body without the last chunk (400)', () async {
      final response = await http.put(
        server.url('/$bucket/short.txt'),
        headers: chunkedHeaders(),
        body: '3;chunk-signature=$signature\r\nabc\r\n',
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>IncompleteBody</Code>'));
    });
  });

  group('AwsChunkedDecoder - UploadPart', () {
    test('Should decode the parts of a multipart upload', () async {
      final created = await http.post(
        server.url('/$bucket/parts.txt?uploads'),
        headers: server.auth(json: true),
      );
      final uploadId = jsonDecode(created.body)['upload_id'] as String;

      final part = await http.put(
        server.url('/$bucket/parts.txt?partNumber=1&uploadId=$uploadId'),
        headers: chunkedHeaders(),
        body: encode(['pa', 'rt']),
      );
      expect(part.statusCode, 200, reason: part.body);
      expect(part.headers['etag'], '"${md5.convert(utf8.encode('part'))}"');
    });
  });
}
