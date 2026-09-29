@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

void main() {
  int port = 8087;
  String localUrl = 'http://localhost:$port';
  const String secret = 'test_secret';
  const String access = 'test_access';
  const String storagePath = './uploads_test/create_bucket';
  late String token;

  Uri url(String path) => Uri.parse(localUrl + path);

  Map<String, String> jsonHeaders({String? bearer}) => {
    'content-type': 'application/json',
    'accept': 'application/json',
    if (bearer != null) 'authorization': 'Bearer $bearer',
  };

  setUpAll(() async {
    env.put('FEATHER_SECRET', secret);
    env.put('FEATHER_ACCESS', access);
    env.put('JWT_SECRET', 'create-bucket-test-jwt-secret');
    env.put('STORAGE_VOLUME_PATH', storagePath);

    final dir = Directory(storagePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    await FeatherIO.start(port: port);

    final login = await http.post(
      url('/${env.adminPrefix}/login'),
      headers: jsonHeaders(),
      body: jsonEncode({'access': access, 'secret': secret}),
    );
    expect(login.statusCode, 200);
    token = jsonDecode(login.body)['access_token'] as String;
  });

  tearDownAll(() async {
    await Winter.close(force: true);
    final dir = Directory(storagePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  group('S3Controller - Create Bucket', () {
    test('PUT /{bucket} - Should fail without token (403)', () async {
      final response = await http.put(
        url('/create-test-no-token'),
        headers: jsonHeaders(),
        body: jsonEncode({}),
      );
      //el AuthFilter de Winter responde 403 (no 401) a una peticion sin autenticar
      expect(response.statusCode, 403);
      expect(await Directory('$storagePath/create-test-no-token').exists(), isFalse);
    });

    test('PUT /{bucket} - Should fail with a wrong token (401)', () async {
      final response = await http.put(
        url('/create-test-wrong-token'),
        headers: jsonHeaders(bearer: 'not-a-jwt'),
        body: jsonEncode({}),
      );
      expect(response.statusCode, anyOf(401, 403));
    });

    test('PUT /{bucket} - Should create a bucket with description and color', () async {
      const color = 0xFFC0156E;
      final response = await http.put(
        url('/create-test-colored'),
        headers: jsonHeaders(bearer: token),
        body: jsonEncode({'description': 'Imágenes de la web', 'color': color}),
      );
      expect(response.statusCode, 200);
      expect(await Directory('$storagePath/create-test-colored').exists(), isTrue);

      final list = await http.get(url('/'), headers: jsonHeaders(bearer: token));
      expect(list.statusCode, 200);
      final bucket = (jsonDecode(list.body) as List).firstWhere(
        (b) => b['name'] == 'create-test-colored',
      );
      expect(bucket['description'], 'Imágenes de la web');
      expect(bucket['color'], color);
    });

    test('PUT /{bucket} - Should create a bucket without body', () async {
      final response = await http.put(
        url('/create-test-no-body'),
        headers: {'authorization': 'Bearer $token'},
      );
      expect(response.statusCode, 200);
    });

    test('PUT /{bucket} - Should reject an existing bucket (409)', () async {
      final response = await http.put(
        url('/create-test-colored'),
        headers: jsonHeaders(bearer: token),
        body: jsonEncode({}),
      );
      expect(response.statusCode, 409);
    });

    test('PUT /{bucket} - Should reject an invalid name (400)', () async {
      for (final name in ['Media_Assets', 'ab', '-media']) {
        final response = await http.put(
          url('/$name'),
          headers: jsonHeaders(bearer: token),
          body: jsonEncode({}),
        );
        expect(response.statusCode, 400, reason: name);
      }
    });

    test('PUT /{bucket} - Should reject a description that is too long (422)', () async {
      final response = await http.put(
        url('/create-test-long-desc'),
        headers: jsonHeaders(bearer: token),
        body: jsonEncode({
          'description': 'x' * (CreateBucketRequest.maxDescriptionLength + 1),
        }),
      );
      expect(response.statusCode, 422);
      final List violations = jsonDecode(response.body);
      expect(violations.single['fieldName'], 'description');
      expect(violations.single['message'], isNotEmpty);
      expect(await Directory('$storagePath/create-test-long-desc').exists(), isFalse);
    });

    test('PUT /{bucket} - Should reject an out of range color (422)', () async {
      final response = await http.put(
        url('/create-test-bad-color'),
        headers: jsonHeaders(bearer: token),
        body: jsonEncode({'color': -1}),
      );
      expect(response.statusCode, 422);
      final List violations = jsonDecode(response.body);
      expect(violations.single['fieldName'], 'color');
    });
  });
}
