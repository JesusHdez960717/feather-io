@TestOn('vm')
library;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import '../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8105, name: 'delete_folder');
  const bucket = 'folder-delete';

  setUpAll(() async {
    await server.start();
    await server.createBucket(bucket);
  });
  tearDownAll(server.stop);

  Future<http.Response> deleteFolder(
    String prefix, {
    String target = bucket,
    bool auth = true,
  }) => http.delete(
    server.url(
      '/${env.adminPrefix}/bucket/$target/folder'
      '?prefix=${Uri.encodeQueryComponent(prefix)}',
    ),
    headers: auth ? server.auth() : {},
  );

  group('AdminController - Delete folder', () {
    test('Should delete the folder with all its content', () async {
      await server.putObject(bucket, 'photos/a.txt', 'a');
      await server.putObject(bucket, 'photos/2026/b.txt', 'b');
      await server.putObject(bucket, 'other/c.txt', 'c');

      final response = await deleteFolder('photos/');
      expect(response.statusCode, 204, reason: response.body);
      expect(await Directory('${server.storagePath}/$bucket/photos').exists(), isFalse);
      expect(await File('${server.storagePath}/$bucket/other/c.txt').exists(), isTrue);
    });

    test('Should delete a nested folder and clean its empty parents', () async {
      await server.putObject(bucket, 'a/b/c.txt', 'c');
      final response = await deleteFolder('a/b/');
      expect(response.statusCode, 204);
      expect(await Directory('${server.storagePath}/$bucket/a').exists(), isFalse);
    });

    test('Should succeed for a folder that does not exist', () async {
      expect((await deleteFolder('missing/')).statusCode, 204);
    });

    test('Should reject a prefix that is not a folder (400)', () async {
      await server.putObject(bucket, 'file.txt', 'f');
      final response = await deleteFolder('file.txt');
      expect(response.statusCode, 400);
      expect(await File('${server.storagePath}/$bucket/file.txt').exists(), isTrue);
    });

    test('Should reject a missing prefix and a path traversal (400)', () async {
      final missing = await http.delete(
        server.url('/${env.adminPrefix}/bucket/$bucket/folder'),
        headers: server.auth(),
      );
      expect(missing.statusCode, 400);
      expect((await deleteFolder('../')).statusCode, 400);
    });

    test('Should return 404 for a missing bucket', () async {
      expect((await deleteFolder('x/', target: 'missing')).statusCode, 404);
    });

    test('Should fail without auth (401)', () async {
      expect((await deleteFolder('x/', auth: false)).statusCode, 401);
    });
  });
}
