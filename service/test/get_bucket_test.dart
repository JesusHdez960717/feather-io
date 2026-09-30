@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8094, name: 'get_bucket');

  setUpAll(() async {
    env.put('RESERVED_BUCKET_NAMES', 'reserved-bucket');
    await server.start();

    final create = await http.put(
      server.url('/detail-bucket'),
      headers: {...server.auth(), 'content-type': 'application/json'},
      body: jsonEncode({'description': 'Detalle', 'color': 0xFF112233}),
    );
    expect(create.statusCode, 200);
    await server.putObject('detail-bucket', 'a.txt', 'abc');
    await server.putObject('detail-bucket', 'folder/b.txt', 'de');
    final empty = await http.put(server.url('/empty-bucket'), headers: server.auth());
    expect(empty.statusCode, 200);
  });
  tearDownAll(server.stop);

  Future<http.Response> getBucket(String name, {bool auth = true}) => http.get(
    server.url('/${env.adminPrefix}/bucket/$name'),
    headers: auth ? server.auth() : {},
  );

  group('AdminController - Get Bucket', () {
    test('Should return the metadata and stats of the bucket', () async {
      final response = await getBucket('detail-bucket');
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['name'], 'detail-bucket');
      expect(body['description'], 'Detalle');
      expect(body['color'], 0xFF112233);
      expect(body['object_count'], 2);
      expect(body['size_bytes'], 5);
      expect(DateTime.parse(body['creation_date']), isA<DateTime>());
      expect(DateTime.parse(body['last_modified']), isA<DateTime>());
    });

    test('Should return a null last_modified for an empty bucket', () async {
      final response = await getBucket('empty-bucket');
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['object_count'], 0);
      expect(body['last_modified'], isNull);
    });

    test('Should return 404 for a non-existent bucket', () async {
      final response = await getBucket('ghost-bucket');
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchBucket');
    });

    test('Should reject an invalid bucket name (400)', () async {
      final response = await getBucket('Bad_Bucket');
      expect(response.statusCode, 400);
    });

    test('Should reject a reserved bucket name (403)', () async {
      final response = await getBucket('reserved-bucket');
      expect(response.statusCode, 403);
    });

    test('Should fail without auth (401)', () async {
      final response = await getBucket('detail-bucket', auth: false);
      expect(response.statusCode, 401);
    });
  });
}
