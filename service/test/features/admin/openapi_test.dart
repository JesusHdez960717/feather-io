@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import '../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8114, name: 'openapi');

  setUpAll(server.start);
  tearDownAll(server.stop);

  Future<Map<String, dynamic>> document() async {
    final response = await http.get(
      server.url('/${env.adminPrefix}/openapi.json'),
    );
    expect(response.statusCode, 200);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  group('Admin API - OpenAPI', () {
    test('Should document every admin route without a token', () async {
      final paths = (await document())['paths'] as Map<String, dynamic>;
      final admin = '/${env.adminPrefix}';
      expect(
        paths.keys,
        containsAll([
          '$admin/health',
          '$admin/login',
          '$admin/bucket/{bucket}',
          '$admin/bucket/{bucket}/objects',
          '$admin/bucket/{bucket}/folder',
          '$admin/bucket/{bucket}/presign',
          '$admin/bucket/{bucket}/download',
          '$admin/bucket/{bucket}/anonymous-access',
          '$admin/access-keys',
          '$admin/access-keys/{id}',
          '$admin/access-keys/{id}/secret',
        ]),
      );
    });

    test('Should leave out the S3 API and the docs themselves', () async {
      final paths = ((await document())['paths'] as Map).keys;
      expect(paths, everyElement(startsWith('/${env.adminPrefix}/')));
      expect(paths, isNot(contains('/${env.adminPrefix}/openapi.json')));
      expect(paths, isNot(contains('/${env.adminPrefix}/docs')));
    });

    test('Should mark the protected routes with the Bearer scheme', () async {
      final paths = (await document())['paths'] as Map<String, dynamic>;
      final admin = '/${env.adminPrefix}';
      final list = paths['$admin/access-keys']['get'] as Map<String, dynamic>;
      expect(list['security'], isNotEmpty);
      expect((list['responses'] as Map).keys, containsAll(['401', '403']));

      final login = paths['$admin/login']['post'] as Map<String, dynamic>;
      expect(login['security'], isNull);
    });

    test('Should take the constraints of a body from its validate()', () async {
      final paths = (await document())['paths'] as Map<String, dynamic>;
      final presign =
          paths['/${env.adminPrefix}/bucket/{bucket}/presign']['post']
              as Map<String, dynamic>;
      final schema =
          presign['requestBody']['content']['application/json']['schema']
              as Map<String, dynamic>;
      expect(schema['required'], containsAll(['key', 'expires_in']));
      expect(
        schema['properties']['expires_in']['maximum'],
        SigV4Signer.maxExpiration.inSeconds,
      );
    });

    test('Should serve Swagger UI', () async {
      final response = await http.get(server.url('/${env.adminPrefix}/docs'));
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], startsWith('text/html'));
      expect(response.body, contains('/${env.adminPrefix}/openapi.json'));
    });
  });
}
