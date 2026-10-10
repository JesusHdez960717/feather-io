@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import '../../support/test_server.dart';

void main() {
  final server = TestServer(
    port: 8110,
    name: 'database_path',
    fileDatabase: true,
  );
  const bucket = 'db-bucket';

  setUpAll(server.start);
  tearDownAll(server.stop);

  group('SQLite path', () {
    test('Should place the database inside STORAGE_VOLUME_PATH', () {
      expect(
        AppDatabase.defaultPath,
        p.join(server.storagePath, '.db', 'feather-io.sqlite'),
      );
    });

    test('Should store the bucket metadata in that file', () async {
      final response = await http.put(
        server.url('/$bucket'),
        headers: {...server.auth(), 'content-type': 'application/json'},
        body: jsonEncode({'description': 'In the volume'}),
      );
      expect(response.statusCode, 200, reason: response.body);

      // The file is created on the first query
      expect(File(AppDatabase.defaultPath).existsSync(), isTrue);

      // A second connection to the same file sees the row
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final other = AppDatabase();
      addTearDown(other.close);
      final rows = await (other.select(
        other.bucketTable,
      )..where((t) => t.name.equals(bucket))).get();
      expect(rows.single.description, 'In the volume');
    });

    test('Should not list the database folder as a bucket', () async {
      final response = await http.get(
        server.url('/'),
        headers: server.auth(json: true),
      );
      expect(response.statusCode, 200);
      final names = [
        for (final b in jsonDecode(response.body) as List) b['name'],
      ];
      expect(names, [bucket]);
    });
  });
}
