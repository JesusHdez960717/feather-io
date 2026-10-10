@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import '../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8115, name: 'health');

  setUpAll(server.start);
  tearDownAll(server.stop);

  Uri health() => server.url('/${env.adminPrefix}/health');

  group('AdminController - Health', () {
    test('Should be up, without a token, with every check', () async {
      final response = await http.get(health());
      expect(response.statusCode, 200);
      expect(response.headers['cache-control'], 'no-store');
      expect(jsonDecode(response.body), {
        'status': 'UP',
        'checks': {'database': 'UP', 'storage': 'UP'},
      });
    });

    test('Should answer HEAD with the status only', () async {
      final response = await http.head(health());
      expect(response.statusCode, 200);
      expect(response.body, isEmpty);
    });

    test('Should leave no probe file in the volume', () async {
      await http.get(health());
      final temp = Directory(
        p.join(env.storageVolumePath, ObjectService.tempFolderName),
      );
      expect(temp.listSync(), isEmpty);
    });

    // Last: it closes the database of the server
    test('Should be 503 when the database is down', () async {
      await di.find<AppDatabase>().close();
      final response = await http.get(health());
      expect(response.statusCode, 503);
      expect(jsonDecode(response.body), {
        'status': 'DOWN',
        'checks': {'database': 'DOWN', 'storage': 'UP'},
      });
    });
  });
}
