@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'package:service/feather.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  int port = 8085;
  String localUrl = 'http://localhost:$port';
  const String secret = 'test_secret';
  const String access = 'test_access';
  const String storagePath = './uploads_test/list_objects';

  setUpAll(() async {
    env.put('FEATHER_SECRET', secret);
    env.put('FEATHER_ACCESS', access);
    env.put('STORAGE_PATH', storagePath);

    final dir = Directory(storagePath);
    if (await dir.exists()) await dir.delete(recursive: true);

    await FeatherIO.start(port: port);

    // Pre-upload files
    final headers = {'FEATHER_SECRET': secret, 'FEATHER_ACCESS': access};
    await http.put(Uri.parse('http://localhost:$port/list-bucket/f1.txt'), headers: headers, body: '1');
    await http.put(Uri.parse('http://localhost:$port/list-bucket/folder/f2.txt'), headers: headers, body: '22');
  });

  tearDownAll(() async {
    await Winter.close(force: true);
    final dir = Directory(storagePath);
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Uri url(String path) => Uri.parse(localUrl + path);
  Map<String, String> authHeaders = {
    'FEATHER_SECRET': secret,
    'FEATHER_ACCESS': access,
  };

  group('S3Controller - LIST Objects', () {
    const bucket = 'list-bucket';

    test('Should list objects in JSON', () async {
      final response = await http.get(
        url('/$bucket/list'),
        headers: {...authHeaders, 'Accept': 'application/json'},
      );
      expect(response.statusCode, 200);
      final List body = jsonDecode(response.body);
      expect(body.length, 2);
      expect(body.any((e) => e['key'] == 'f1.txt'), isTrue);
      expect(body.any((e) => e['key'] == 'folder/f2.txt'), isTrue);
    });

    test('Should list objects in XML by default', () async {
      final response = await http.get(
        url('/$bucket/list'),
        headers: authHeaders,
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/xml'));
      expect(response.body, contains('<ListBucketResult'));
      expect(response.body, contains('<Key>f1.txt</Key>'));
      expect(response.body, contains('<Key>folder/f2.txt</Key>'));
    });

    test('Should fail without auth (401)', () async {
      final response = await http.get(url('/$bucket/list'));
      expect(response.statusCode, 401);
    });

    test('Should fail with wrong auth (403)', () async {
      final response = await http.get(
        url('/$bucket/list'),
        headers: {'FEATHER_SECRET': 'w', 'FEATHER_ACCESS': 'w'},
      );
      expect(response.statusCode, 403);
    });

    test('Should return 404 if bucket does not exist', () async {
      final response = await http.get(
        url('/no-bucket/list'),
        headers: authHeaders,
      );
      expect(response.statusCode, 404);
    });
  });
}
