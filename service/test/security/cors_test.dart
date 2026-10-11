@TestOn('vm')
library;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../support/test_server.dart';

void main() {
  final server = TestServer(port: 8091, name: 'cors');

  setUpAll(server.start);
  tearDownAll(server.stop);

  group('CORS Tests', () {
    test('Preflight request (OPTIONS) should return CORS headers', () async {
      final request = http.Request('OPTIONS', server.url('/'));
      request.headers['Origin'] = 'http://example.com';
      request.headers['Access-Control-Request-Method'] = 'GET';
      request.headers['Access-Control-Request-Headers'] = 'Authorization';

      final response = await http.Response.fromStream(await request.send());

      expect(response.statusCode, anyOf(200, 204));
      expect(
        response.headers['access-control-allow-origin'],
        isNotNull,
        reason: 'Missing Access-Control-Allow-Origin',
      );
      expect(
        response.headers['access-control-allow-methods'],
        isNotNull,
        reason: 'Missing Access-Control-Allow-Methods',
      );
    });

    test('GET with Origin header should include CORS headers, even on 401', () async {
      final response = await http.get(
        server.url('/'),
        headers: {'Origin': 'http://example.com'},
      );

      expect(response.statusCode, 401);
      expect(
        response.headers['access-control-allow-origin'],
        isNotNull,
        reason: 'Missing Access-Control-Allow-Origin on GET',
      );
    });

    test('GET without Origin header should not include CORS headers', () async {
      final response = await http.get(server.url('/'), headers: server.auth());

      expect(
        response.headers.containsKey('access-control-allow-origin'),
        isFalse,
      );
    });
  });
}
