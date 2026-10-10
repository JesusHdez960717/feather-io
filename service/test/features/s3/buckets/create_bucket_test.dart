@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import '../../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8087, name: 'create_bucket');

  setUpAll(() async {
    env.put('RESERVED_BUCKET_NAMES', 'reserved-bucket');
    await server.start();
  });
  tearDownAll(server.stop);

  Map<String, String> jsonHeaders({bool auth = true}) => {
    'content-type': 'application/json',
    'accept': 'application/json',
    if (auth) 'authorization': 'Bearer ${server.token}',
  };

  Future<bool> bucketExists(String name) =>
      Directory('${server.storagePath}/$name').exists();

  group('S3Controller - Create Bucket', () {
    test('PUT /{bucket} - Should fail without token (401)', () async {
      final response = await http.put(
        server.url('/create-test-no-token'),
        headers: jsonHeaders(auth: false),
        body: jsonEncode({}),
      );
      expect(response.statusCode, 401);
      expect(await bucketExists('create-test-no-token'), isFalse);
    });

    test('PUT /{bucket} - Should fail with a wrong token (401)', () async {
      final response = await http.put(
        server.url('/create-test-wrong-token'),
        headers: {
          ...jsonHeaders(auth: false),
          'authorization': 'Bearer not-a-jwt',
        },
        body: jsonEncode({}),
      );
      expect(response.statusCode, 401);
    });

    test('PUT /{bucket} - Should create a bucket signed with SigV4', () async {
      final response = await http.put(
        server.url('/create-test-sigv4'),
        headers: server.sigV4('PUT', '/create-test-sigv4'),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(await bucketExists('create-test-sigv4'), isTrue);
      // As in S3: no body (clients would parse it as XML) and a Location
      expect(response.body, isEmpty);
      expect(response.headers['location'], '/create-test-sigv4');
    });

    test(
      'PUT /{bucket} - Should accept a request without Content-Length nor body',
      () async {
        // Like aws-sdk-java-v2's CreateBucket; package:http always sends the
        // header, so this goes through a raw socket
        final socket = await Socket.connect('localhost', server.port);
        socket.write(
          'PUT /create-test-no-length HTTP/1.1\r\n'
          'Host: localhost:${server.port}\r\n'
          'Authorization: Bearer ${server.token}\r\n'
          'Connection: close\r\n\r\n',
        );
        final response = await utf8.decodeStream(socket);
        socket.destroy();
        expect(response, startsWith('HTTP/1.1 200'));
        expect(await bucketExists('create-test-no-length'), isTrue);
      },
    );

    test(
      'PUT /{bucket} - Should create a bucket with description and color',
      () async {
        const color = 0xFFC0156E;
        final response = await http.put(
          server.url('/create-test-colored'),
          headers: jsonHeaders(),
          body: jsonEncode({
            'description': 'Website images: café',
            'color': color,
          }),
        );
        expect(response.statusCode, 200);
        expect(await bucketExists('create-test-colored'), isTrue);

        final list = await http.get(server.url('/'), headers: jsonHeaders());
        expect(list.statusCode, 200);
        final bucket = (jsonDecode(list.body) as List).firstWhere(
          (b) => b['name'] == 'create-test-colored',
        );
        expect(bucket['description'], 'Website images: café');
        expect(bucket['color'], color);
      },
    );

    test('PUT /{bucket} - Should create a bucket without body', () async {
      final response = await http.put(
        server.url('/create-test-no-body'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(await bucketExists('create-test-no-body'), isTrue);
    });

    test('PUT /{bucket} - Should reject an existing bucket (409)', () async {
      final response = await http.put(
        server.url('/create-test-colored'),
        headers: jsonHeaders(),
        body: jsonEncode({}),
      );
      expect(response.statusCode, 409);
      expect(jsonDecode(response.body)['code'], 'BucketAlreadyOwnedByYou');
    });

    test('PUT /{bucket} - Should reject an invalid name (400)', () async {
      for (final name in ['Media_Assets', 'ab', '-media']) {
        final response = await http.put(
          server.url('/$name'),
          headers: jsonHeaders(),
          body: jsonEncode({}),
        );
        expect(response.statusCode, 400, reason: name);
        expect(
          jsonDecode(response.body)['code'],
          'InvalidBucketName',
          reason: name,
        );
      }
    });

    test('PUT /{bucket} - Should reject a reserved name (403)', () async {
      final response = await http.put(
        server.url('/reserved-bucket'),
        headers: jsonHeaders(),
        body: jsonEncode({}),
      );
      expect(response.statusCode, 403);
      expect(jsonDecode(response.body)['code'], 'AccessDenied');
      expect(await bucketExists('reserved-bucket'), isFalse);
    });

    test(
      'PUT /{bucket} - Should reject a description that is too long (422)',
      () async {
        final response = await http.put(
          server.url('/create-test-long-desc'),
          headers: jsonHeaders(),
          body: jsonEncode({
            'description': 'x' * (CreateBucketRequest.maxDescriptionLength + 1),
          }),
        );
        expect(response.statusCode, 422);
        final List violations = jsonDecode(response.body)['violations'];
        expect(violations.single['fieldName'], 'description');
        expect(violations.single['message'], isNotEmpty);
        expect(await bucketExists('create-test-long-desc'), isFalse);
      },
    );

    test('PUT /{bucket} - Should reject an out of range color (422)', () async {
      final response = await http.put(
        server.url('/create-test-bad-color'),
        headers: jsonHeaders(),
        body: jsonEncode({'color': -1}),
      );
      expect(response.statusCode, 422);
      final List violations = jsonDecode(response.body)['violations'];
      expect(violations.single['fieldName'], 'color');
    });
  });
}
