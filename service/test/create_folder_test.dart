@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8097, name: 'create_folder');
  const bucket = 'folder-bucket';

  setUpAll(server.start);
  tearDownAll(server.stop);

  Future<http.Response> createFolder(String key, {bool auth = true}) =>
      http.put(
        server.url('/$bucket/$key'),
        headers: auth ? server.auth() : {},
      );

  Future<Map<String, dynamic>> list({String prefix = ''}) async {
    final response = await http.get(
      server.url('/$bucket?delimiter=/&prefix=$prefix'),
      headers: server.auth(json: true),
    );
    expect(response.statusCode, 200);
    return jsonDecode(response.body);
  }

  group('S3Controller - Create folder (PUT key/)', () {
    test('Should create an empty folder listed as a common prefix', () async {
      expect((await createFolder('fotos/')).statusCode, 200);
      expect(
        await Directory('${server.storagePath}/$bucket/fotos').exists(),
        isTrue,
      );

      final root = await list();
      expect(root['common_prefixes'], ['fotos/']);
      expect(root['contents'], isEmpty);
    });

    test('Should list the folder itself as a 0 byte key inside it', () async {
      final inside = await list(prefix: 'fotos/');
      final contents = inside['contents'] as List;
      expect(contents.single['key'], 'fotos/');
      expect(contents.single['size_bytes'], 0);
    });

    test('Should create nested folders', () async {
      expect((await createFolder('docs/2026/facturas/')).statusCode, 200);
      final docs = await list(prefix: 'docs/');
      expect(docs['common_prefixes'], ['docs/2026/']);
    });

    test('Should keep the folder after deleting its last object', () async {
      await server.putObject(bucket, 'fotos/gato.jpg', 'jpg');
      final delete = await http.delete(
        server.url('/$bucket/fotos/gato.jpg'),
        headers: server.auth(),
      );
      expect(delete.statusCode, 204);

      final root = await list();
      expect(root['common_prefixes'], contains('fotos/'));
    });

    test('Should not count the folder as an object in the bucket stats', () async {
      final response = await http.get(server.url('/'), headers: server.auth(json: true));
      final stats = (jsonDecode(response.body) as List).firstWhere(
        (b) => b['name'] == bucket,
      );
      expect(stats['object_count'], 0);
    });

    test('Should delete the folder with its content', () async {
      await server.putObject(bucket, 'borrar/a.txt', 'a');
      final delete = await http.delete(
        server.url('/$bucket/borrar/'),
        headers: server.auth(),
      );
      expect(delete.statusCode, 204);
      expect(
        await Directory('${server.storagePath}/$bucket/borrar').exists(),
        isFalse,
      );
    });

    test('Should reject the folder marker name as a key (400)', () async {
      final response = await http.put(
        server.url('/$bucket/fotos/.feather-folder'),
        headers: server.auth(),
        body: 'x',
      );
      expect(response.statusCode, 400);
    });

    test('Should fail without auth (401)', () async {
      expect((await createFolder('sin-auth/', auth: false)).statusCode, 401);
    });

    test('Should delete a bucket that only has empty folders (204)', () async {
      final create = await http.put(server.url('/only-folders'), headers: server.auth());
      expect(create.statusCode, 200);
      final folder = await http.put(
        server.url('/only-folders/vacia/'),
        headers: server.auth(),
      );
      expect(folder.statusCode, 200);

      final delete = await http.delete(server.url('/only-folders'), headers: server.auth());
      expect(delete.statusCode, 204);
      expect(await Directory('${server.storagePath}/only-folders').exists(), isFalse);
    });
  });
}
