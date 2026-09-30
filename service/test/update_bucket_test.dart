@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8093, name: 'update_bucket');

  setUpAll(() async {
    env.put('RESERVED_BUCKET_NAMES', 'reserved-bucket');
    await server.start();

    final create = await http.put(
      server.url('/edit-bucket'),
      headers: {...server.auth(), 'content-type': 'application/json'},
      body: jsonEncode({'description': 'Original', 'color': 0xFF112233}),
    );
    expect(create.statusCode, 200);
  });
  tearDownAll(server.stop);

  Future<http.Response> update(String bucket, Object body, {bool auth = true}) {
    return http.put(
      server.url('/${env.adminPrefix}/bucket/$bucket'),
      headers: {
        if (auth) ...server.auth(),
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  Future<Map<String, dynamic>> findBucket(String name) async {
    final list = await http.get(server.url('/'), headers: server.auth(json: true));
    return (jsonDecode(list.body) as List).firstWhere((b) => b['name'] == name);
  }

  group('AdminController - Update Bucket', () {
    test('Should update description and color and return the bucket', () async {
      final response = await update('edit-bucket', {
        'description': 'Nueva descripción',
        'color': 0xFFAABBCC,
      });
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['name'], 'edit-bucket');
      expect(body['description'], 'Nueva descripción');
      expect(body['color'], 0xFFAABBCC);
      expect(body['object_count'], 0);

      final listed = await findBucket('edit-bucket');
      expect(listed['description'], 'Nueva descripción');
      expect(listed['color'], 0xFFAABBCC);
    });

    test('Should keep the creation date', () async {
      final before = (await findBucket('edit-bucket'))['creation_date'];
      await update('edit-bucket', {'description': 'Otra'});
      expect((await findBucket('edit-bucket'))['creation_date'], before);
    });

    test('Should clear the fields sent as null', () async {
      final response = await update('edit-bucket', {'description': null, 'color': null});
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['description'], isNull);
      expect(body['color'], isNull);
    });

    test('Should update a bucket created by an upload (without metadata)', () async {
      await server.putObject('uploaded-bucket', 'file.txt', 'data');

      final response = await update('uploaded-bucket', {'description': 'Subido'});
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['description'], 'Subido');
      expect(body['object_count'], 1);
      expect(body['size_bytes'], 4);
    });

    test('Should return 404 for a non-existent bucket', () async {
      final response = await update('ghost-bucket', {'description': 'x'});
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchBucket');
    });

    test('Should reject an invalid bucket name (400)', () async {
      final response = await update('Bad_Bucket', {'description': 'x'});
      expect(response.statusCode, 400);
      expect(jsonDecode(response.body)['code'], 'InvalidBucketName');
    });

    test('Should reject a reserved bucket name (403)', () async {
      final response = await update('reserved-bucket', {'description': 'x'});
      expect(response.statusCode, 403);
    });

    test('Should reject a description that is too long (422)', () async {
      final response = await update('edit-bucket', {
        'description': 'x' * (CreateBucketRequest.maxDescriptionLength + 1),
      });
      expect(response.statusCode, 422);
      expect((jsonDecode(response.body) as List).single['fieldName'], 'description');
    });

    test('Should reject an out of range color (422)', () async {
      final response = await update('edit-bucket', {'color': 0x1FFFFFFFF});
      expect(response.statusCode, 422);
      expect((jsonDecode(response.body) as List).single['fieldName'], 'color');
    });

    test('Should reject a body that is not JSON (400)', () async {
      final response = await http.put(
        server.url('/${env.adminPrefix}/bucket/edit-bucket'),
        headers: {...server.auth(), 'content-type': 'application/json'},
        body: 'not json',
      );
      expect(response.statusCode, 400);
    });

    test('Should fail without auth (401)', () async {
      final response = await update('edit-bucket', {'description': 'x'}, auth: false);
      expect(response.statusCode, 401);
    });
  });
}
