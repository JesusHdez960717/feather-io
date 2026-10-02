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

  setUpAll(() async {
    await server.start();
    await server.createBucket(bucket);
  });
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

    test('Should only delete the folder marker, like S3, keeping its content', () async {
      await createFolder('borrar/');
      await server.putObject(bucket, 'borrar/a.txt', 'a');
      final delete = await http.delete(
        server.url('/$bucket/borrar/'),
        headers: server.auth(),
      );
      expect(delete.statusCode, 204);
      expect(
        await File('${server.storagePath}/$bucket/borrar/a.txt').exists(),
        isTrue,
      );
      final keys = (await list(prefix: 'borrar/'))['contents'] as List;
      expect(keys.map((o) => o['key']), ['borrar/a.txt']);
    });

    test('Should delete an empty folder', () async {
      await createFolder('vacia-borrar/');
      final delete = await http.delete(
        server.url('/$bucket/vacia-borrar/'),
        headers: server.auth(),
      );
      expect(delete.statusCode, 204);
      expect(
        await Directory('${server.storagePath}/$bucket/vacia-borrar').exists(),
        isFalse,
      );
    });

    test('Should not delete a directory addressed without the slash', () async {
      await server.putObject(bucket, 'sin-barra/a.txt', 'a');
      final delete = await http.delete(
        server.url('/$bucket/sin-barra'),
        headers: server.auth(),
      );
      expect(delete.statusCode, 204);
      expect(
        await File('${server.storagePath}/$bucket/sin-barra/a.txt').exists(),
        isTrue,
      );
    });

    test('Should only delete the marker in a multi-delete too', () async {
      await createFolder('multi/');
      await server.putObject(bucket, 'multi/a.txt', 'a');
      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: server.auth(),
        body: '<Delete><Object><Key>multi/</Key></Object></Delete>',
      );
      expect(response.statusCode, 200);
      expect(
        await File('${server.storagePath}/$bucket/multi/a.txt').exists(),
        isTrue,
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

    test('Should answer HEAD and GET on the folder as an empty object', () async {
      expect((await createFolder('cabecera/')).statusCode, 200);

      final head = await http.head(
        server.url('/$bucket/cabecera/'),
        headers: server.auth(),
      );
      expect(head.statusCode, 200);
      expect(head.headers['content-length'], '0');
      expect(head.headers['etag'], '"d41d8cd98f00b204e9800998ecf8427e"');

      final get = await http.get(
        server.url('/$bucket/cabecera/'),
        headers: server.auth(),
      );
      expect(get.statusCode, 200);
      expect(get.body, isEmpty);
    });

    test('Should answer 404 on HEAD of a folder that does not exist', () async {
      final head = await http.head(
        server.url('/$bucket/no-existe/'),
        headers: server.auth(),
      );
      expect(head.statusCode, 404);
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
