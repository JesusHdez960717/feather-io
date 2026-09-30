@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8088, name: 's3_error');

  setUpAll(() async {
    env.put('RESERVED_BUCKET_NAMES', 'reserved-bucket');
    await server.start();
  });
  tearDownAll(server.stop);

  group('S3Exception - Content negotiation', () {
    test('Should answer the S3 <Error> in XML by default', () async {
      final response = await http.get(
        server.url('/missing-bucket'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
      expect(response.headers['content-type'], contains('application/xml'));
      expect(response.body, contains('<Error>'));
      expect(response.body, contains('<Code>NoSuchBucket</Code>'));
      expect(response.body, contains('<Resource>missing-bucket</Resource>'));
      expect(response.body, contains('<Message>'));
    });

    test('Should escape the XML special chars of the message', () async {
      final response = await http.get(
        server.url('/missing-bucket'),
        headers: server.auth(),
      );
      //el mensaje lleva el nombre entre comillas
      expect(response.body, contains('&quot;missing-bucket&quot;'));
    });

    test('Should answer JSON when the client accepts it', () async {
      final response = await http.get(
        server.url('/missing-bucket'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 404);
      //Winter marca los errores serializados como application/problem+json
      expect(response.headers['content-type'], contains('json'));
      final body = jsonDecode(response.body);
      expect(body['code'], 'NoSuchBucket');
      expect(body['message'], isNotEmpty);
      expect(body['resource'], 'missing-bucket');
    });

    test('Should use the S3 format for errors thrown in filters', () async {
      final response = await http.get(
        server.url('/Bad_Bucket'),
        headers: server.auth(),
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>InvalidBucketName</Code>'));
    });

    test('Should deny a reserved bucket with AccessDenied (403)', () async {
      final response = await http.get(
        server.url('/reserved-bucket'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 403);
      expect(jsonDecode(response.body)['code'], 'AccessDenied');
    });
  });

  group('S3Exception - Admin API', () {
    test('Should always answer JSON, even without Accept', () async {
      final response = await http.get(
        server.url('/${env.adminPrefix}/bucket/Bad_Bucket/anonymous-access'),
        headers: server.auth(),
      );
      expect(response.statusCode, 400);
      //Winter marca los errores serializados como application/problem+json
      expect(response.headers['content-type'], contains('json'));
      expect(jsonDecode(response.body)['code'], 'InvalidBucketName');
    });

    test('Should answer JSON for errors of the download', () async {
      await server.putObject('zip-bucket', 'file.txt', 'data');

      final response = await http.post(
        server.url('/${env.adminPrefix}/bucket/zip-bucket/download'),
        headers: {...server.auth(), 'content-type': 'application/json'},
        body: jsonEncode({
          'keys': ['missing.txt'],
        }),
      );
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchKey');
    });
  });

  group('S3SigV4Filter', () {
    test('Should reject a SigV4 request with a wrong access key (403)', () async {
      final response = await http.get(
        server.url('/'),
        headers: {
          'authorization':
              'AWS4-HMAC-SHA256 Credential=wrong/20260101/us-east-1/s3/aws4_request, '
              'SignedHeaders=host;x-amz-date, Signature=abc',
          'x-amz-date': '20260101T000000Z',
        },
      );
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>InvalidAccessKeyId</Code>'));
    });

    test('Should reject a SigV4 request with a wrong signature (403)', () async {
      final response = await http.get(
        server.url('/'),
        headers: {
          'authorization':
              'AWS4-HMAC-SHA256 Credential=$testAccess/20260101/us-east-1/s3/aws4_request, '
              'SignedHeaders=host;x-amz-date, Signature=abc',
          'x-amz-date': '20260101T000000Z',
        },
      );
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>SignatureDoesNotMatch</Code>'));
    });
  });
}
