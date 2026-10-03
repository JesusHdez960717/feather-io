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
      // The message has the name in quotes
      expect(response.body, contains('&quot;missing-bucket&quot;'));
    });

    test('Should answer JSON when the client accepts it', () async {
      final response = await http.get(
        server.url('/missing-bucket'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 404);
      // Winter marks serialized errors as application/problem+json
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
      // Winter marks serialized errors as application/problem+json
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
    final now = DateTime.now().toUtc();

    test('Should reject a SigV4 request with a wrong access key (403)', () async {
      final response = await http.get(
        server.url('/'),
        headers: {
          'authorization':
              'AWS4-HMAC-SHA256 Credential=wrong/${SigV4Signer.dateStamp(now)}/us-east-1/s3/aws4_request, '
              'SignedHeaders=host;x-amz-date, Signature=abc',
          'x-amz-date': SigV4Signer.amzDate(now),
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
              'AWS4-HMAC-SHA256 Credential=$testAccess/${SigV4Signer.dateStamp(now)}/us-east-1/s3/aws4_request, '
              'SignedHeaders=host;x-amz-date, Signature=abc',
          'x-amz-date': SigV4Signer.amzDate(now),
        },
      );
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>SignatureDoesNotMatch</Code>'));
    });

    test('Should accept the Authorization fields without spaces (s3cmd)', () async {
      final headers = server.sigV4('GET', '/');
      headers['authorization'] = headers['authorization']!.replaceAll(', ', ',');
      final response = await http.get(server.url('/'), headers: headers);
      expect(response.statusCode, 200, reason: response.body);
    });
  });

  group('S3SigV4Filter - replay and body', () {
    test('Should reject a signature older than 15 minutes (replay)', () async {
      final response = await http.get(
        server.url('/'),
        headers: server.sigV4(
          'GET',
          '/',
          at: DateTime.now().subtract(const Duration(minutes: 16)),
        ),
      );
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>RequestTimeTooSkewed</Code>'));
    });

    test('Should reject a signature dated in the future', () async {
      final response = await http.get(
        server.url('/'),
        headers: server.sigV4(
          'GET',
          '/',
          at: DateTime.now().add(const Duration(minutes: 16)),
        ),
      );
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>RequestTimeTooSkewed</Code>'));
    });

    test('Should accept a small clock skew', () async {
      final response = await http.get(
        server.url('/'),
        headers: server.sigV4(
          'GET',
          '/',
          at: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      expect(response.statusCode, 200, reason: response.body);
    });

    test('Should reject a credential scope of another day', () async {
      final headers = server.sigV4('GET', '/');
      headers['authorization'] = headers['authorization']!.replaceFirst(
        RegExp(r'/\d{8}/'),
        '/20200101/',
      );
      final response = await http.get(server.url('/'), headers: headers);
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>SignatureDoesNotMatch</Code>'));
    });

    test('Should store a body that matches the signed sha256', () async {
      await server.createBucket('signed-body');
      final body = utf8.encode('original');
      final response = await http.put(
        server.url('/signed-body/ok.txt'),
        headers: server.sigV4(
          'PUT',
          '/signed-body/ok.txt',
          payloadHash: sha256.convert(body).toString(),
        ),
        body: body,
      );
      expect(response.statusCode, 200, reason: response.body);
    });

    test('Should reject a body that does not match the signed sha256', () async {
      await server.putObject('signed-body', 'changed.txt', 'previous');
      final response = await http.put(
        server.url('/signed-body/changed.txt'),
        headers: server.sigV4(
          'PUT',
          '/signed-body/changed.txt',
          payloadHash: sha256.convert(utf8.encode('original')).toString(),
        ),
        body: 'tampered',
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>XAmzContentSHA256Mismatch</Code>'));
      // The previous object stays intact
      expect(
        await File('${server.storagePath}/signed-body/changed.txt').readAsString(),
        'previous',
      );
    });

    test('Should reject a presigned URL dated in the future', () async {
      final future = DateTime.now().toUtc().add(const Duration(days: 30));
      final amzDate = SigV4Signer.amzDate(future);
      final scope = SigV4Signer.scope(SigV4Signer.dateStamp(future));
      final query = {
        SigV4Signer.algorithmParam: SigV4Signer.algorithm,
        SigV4Signer.credentialParam: '$testAccess/$scope',
        SigV4Signer.dateParam: amzDate,
        SigV4Signer.expiresParam: '3600',
        SigV4Signer.signedHeadersParam: 'host',
      };
      final signature = SigV4Signer.signature(
        secret: testSecret,
        amzDate: amzDate,
        scope: scope,
        canonicalRequest: SigV4Signer.canonicalRequest(
          method: 'GET',
          path: '/',
          query: query,
          headers: {'host': 'localhost:${server.port}'},
          signedHeaders: 'host',
          payloadHash: SigV4Signer.unsignedPayload,
        ),
      );
      final signedQuery = SigV4Signer.canonicalQuery({
        ...query,
        SigV4Signer.signatureParam: signature,
      });
      final response = await http.get(server.url('/?$signedQuery'));
      expect(response.statusCode, 403);
    });
  });
}
