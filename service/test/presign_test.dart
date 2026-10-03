@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8099, name: 'presign');
  const bucket = 'share-bucket';

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'docs/report final.pdf', 'content');
  });
  tearDownAll(server.stop);

  Future<http.Response> presign(Object body, {bool auth = true}) => http.post(
    server.url('/${env.adminPrefix}/bucket/$bucket/presign'),
    headers: {if (auth) ...server.auth(), 'content-type': 'application/json'},
    body: jsonEncode(body),
  );

  Future<String> presignedUrl({int expiresIn = 3600}) async {
    final response = await presign({
      'key': 'docs/report final.pdf',
      'expires_in': expiresIn,
    });
    expect(response.statusCode, 200, reason: response.body);
    return jsonDecode(response.body)['url'] as String;
  }

  group('AdminController - Presign', () {
    test(
      'Should return a URL to the same service that expires later',
      () async {
        final response = await presign({
          'key': 'docs/report final.pdf',
          'expires_in': 3600,
        });
        expect(response.statusCode, 200);
        final body = jsonDecode(response.body);
        final url = Uri.parse(body['url']);
        expect(url.host, 'localhost');
        expect(url.port, 8099);
        expect(url.path, '/$bucket/docs/report%20final.pdf');
        expect(url.queryParameters['X-Amz-Expires'], '3600');
        expect(url.queryParameters['X-Amz-Signature'], isNotEmpty);
        final expiresAt = DateTime.parse(body['expires_at']);
        expect(
          expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 59))),
          isTrue,
        );
      },
    );

    test('Should return 404 for a missing object', () async {
      final response = await presign({
        'key': 'no-existe.pdf',
        'expires_in': 60,
      });
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchKey');
    });

    test('Should reject an expiration out of range (422)', () async {
      for (final expiresIn in [0, 7 * 24 * 3600 + 1]) {
        final response = await presign({
          'key': 'docs/report final.pdf',
          'expires_in': expiresIn,
        });
        expect(response.statusCode, 422, reason: '$expiresIn');
      }
    });

    test('Should fail without auth (401)', () async {
      final response = await presign({
        'key': 'docs/report final.pdf',
        'expires_in': 60,
      }, auth: false);
      expect(response.statusCode, 401);
    });
  });

  group('S3SigV4Filter - presigned URLs', () {
    test('Should download the object without credentials', () async {
      final response = await http.get(Uri.parse(await presignedUrl()));
      expect(response.statusCode, 200);
      expect(response.body, 'content');
    });

    test('Should reject a tampered signature (403)', () async {
      final url = Uri.parse(await presignedUrl());
      final tampered = url.replace(
        queryParameters: {...url.queryParameters, 'X-Amz-Signature': '0' * 64},
      );
      final response = await http.get(tampered);
      expect(response.statusCode, 403);
      expect(response.body, contains('<Code>SignatureDoesNotMatch</Code>'));
    });

    test('Should reject the signature on another object (403)', () async {
      await server.putObject(bucket, 'secret.txt', 'no');
      final url = Uri.parse(await presignedUrl());
      final other = url.replace(path: '/$bucket/secret.txt');
      final response = await http.get(other);
      expect(response.statusCode, 403);
    });

    test(
      'Should reject a longer expiration than the signed one (403)',
      () async {
        final url = Uri.parse(await presignedUrl(expiresIn: 60));
        final longer = url.replace(
          queryParameters: {...url.queryParameters, 'X-Amz-Expires': '600000'},
        );
        expect((await http.get(longer)).statusCode, 403);
      },
    );

    test('Should not allow another method with the same URL (403)', () async {
      final url = Uri.parse(await presignedUrl());
      final response = await http.delete(url);
      expect(response.statusCode, 403);
    });

    test('Should reject an expired URL (403)', () async {
      final url = Uri.parse(await presignedUrl(expiresIn: 1));
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      final response = await http.get(url);
      expect(response.statusCode, 403);
      expect(response.body, contains('Request has expired'));
    });
  });

  group('S3SigV4Filter - Authorization header', () {
    test('Should accept a request signed with the service keys', () async {
      final now = DateTime.now().toUtc();
      final amzDate = SigV4Signer.amzDate(now);
      final scope = SigV4Signer.scope(SigV4Signer.dateStamp(now));
      final headers = {
        'host': 'localhost:8099',
        'x-amz-date': amzDate,
        'x-amz-content-sha256': SigV4Signer.unsignedPayload,
      };
      const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
      final signature = SigV4Signer.signature(
        secret: testSecret,
        amzDate: amzDate,
        scope: scope,
        canonicalRequest: SigV4Signer.canonicalRequest(
          method: 'GET',
          path: '/',
          query: const {},
          headers: headers,
          signedHeaders: signedHeaders,
          payloadHash: SigV4Signer.unsignedPayload,
        ),
      );

      final response = await http.get(
        server.url('/'),
        headers: {
          ...headers,
          'authorization':
              '${SigV4Signer.algorithm} Credential=$testAccess/$scope, '
              'SignedHeaders=$signedHeaders, Signature=$signature',
        },
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(response.body, contains('<Name>$bucket</Name>'));
    });
  });
}
