@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:service/feather.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  int port = 8084;
  String localUrl = 'http://localhost:$port';
  const String secret = 'test_secret';
  const String access = 'test_access';
  const String storagePath = './uploads_test/list_buckets';

  setUpAll(() async {
    env.put('FEATHER_SECRET', secret);
    env.put('FEATHER_ACCESS', access);
    env.put('STORAGE_PATH', storagePath);

    final dir = Directory(storagePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    await FeatherIO.start(port: port);
  });

  tearDownAll(() async {
    await Winter.close(force: true);
    final dir = Directory(storagePath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  Uri url(String path) => Uri.parse(localUrl + path);

  Map<String, String> authHeaders = {
    'FEATHER_SECRET': secret,
    'FEATHER_ACCESS': access,
  };

  group('S3Controller - List Buckets', () {
    test('GET / - Should fail without headers (401)', () async {
      final response = await http.get(url('/'));
      expect(response.statusCode, 401);
    });

    test('GET / - Should return empty list initially (JSON)', () async {
      final response = await http.get(
        url('/'),
        headers: {...authHeaders, 'Accept': 'application/json'},
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body, isList);
      expect(body, isEmpty);
    });

    test('GET / - Should list buckets after upload (JSON)', () async {
      const bucketName = 'test-bucket-1';
      const fileName = 'test.txt';
      const content = 'Hello FeatherIO';

      // 1. Upload a file to create a bucket
      final uploadResponse = await http.put(
        url('/$bucketName/$fileName'),
        headers: authHeaders,
        body: content,
      );
      expect(uploadResponse.statusCode, 200);

      // 2. List buckets
      final response = await http.get(
        url('/'),
        headers: {...authHeaders, 'Accept': 'application/json'},
      );

      expect(response.statusCode, 200);
      final List body = jsonDecode(response.body);
      expect(body.length, 1);
      expect(body[0]['name'], bucketName);
      expect(body[0]['object_count'], 1);
      expect(body[0]['size_bytes'], content.length);
    });

    test('GET / - Should list multiple buckets and update stats (JSON)', () async {
      const bucket2 = 'test-bucket-2';
      final content1 = 'Data 1';
      final content2 = 'Data 2 extended';

      // Upload to bucket 2
      await http.put(url('/$bucket2/file1.txt'), headers: authHeaders, body: content1);
      await http.put(url('/$bucket2/file2.txt'), headers: authHeaders, body: content2);

      final response = await http.get(
        url('/'),
        headers: {...authHeaders, 'Accept': 'application/json'},
      );

      expect(response.statusCode, 200);
      final List body = jsonDecode(response.body);
      
      // Should have 2 buckets now (from previous test and this one)
      expect(body.length, 2);
      
      final b2 = body.firstWhere((b) => b['name'] == bucket2);
      expect(b2['object_count'], 2);
      expect(b2['size_bytes'], content1.length + content2.length);
    });

    test('GET / - Should return XML by default', () async {
      final response = await http.get(
        url('/'),
        headers: authHeaders,
      );

      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/xml'));
      expect(response.body, contains('<ListAllMyBucketsResult'));
      expect(response.body, contains('<Bucket>'));
      expect(response.body, contains('<Name>test-bucket-1</Name>'));
      expect(response.body, contains('<ObjectCount>1</ObjectCount>'));
    });
    test('GET / - Should update stats after deleting a file', () async {
      const bucketName = 'test-bucket-1';
      const fileName = 'test.txt';

      // 1. Delete the file we uploaded in the first test
      final deleteResponse = await http.delete(
        url('/$bucketName/$fileName'),
        headers: authHeaders,
      );
      expect(deleteResponse.statusCode, 200);

      // 2. List buckets again
      final response = await http.get(
        url('/'),
        headers: {...authHeaders, 'Accept': 'application/json'},
      );

      expect(response.statusCode, 200);
      final List body = jsonDecode(response.body);
      
      final b1 = body.firstWhere((b) => b['name'] == bucketName);
      expect(b1['object_count'], 0);
      expect(b1['size_bytes'], 0);
    });

   group('S3Controller - List Files in Bucket (Validation of XML format)', () {
      test('GET /{bucket}/list - Should return XML by default', () async {
        const bucketName = 'test-bucket-1';
        const fileName = 'test-xml.txt';
        
        // Ensure there is at least one file to see <Contents>
        await http.put(
          url('/$bucketName/$fileName'),
          headers: authHeaders,
          body: 'xml-content',
        );

        final response = await http.get(
          url('/$bucketName/list'),
          headers: authHeaders,
        );

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], contains('application/xml'));
        expect(response.body, contains('<ListBucketResult'));
        expect(response.body, contains('<Contents>'));
        expect(response.body, contains('<Key>$fileName</Key>'));
      });
    });
  });
}
