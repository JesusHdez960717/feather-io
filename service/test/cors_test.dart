@TestOn('vm')
library;

import 'package:feather_io/feather.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  int port = 8081;
  String localUrl = 'http://localhost:$port';

  setUpAll(() async {
    env.put('FEATHER_SECRET', 'test_secret');
    env.put('FEATHER_ACCESS', 'test_access');
    env.put('STORAGE_PATH', './uploads_test_cors');

    await FeatherIO.start(port: port);
  });

  tearDownAll(() async {
    await Winter.close(force: true);
  });

  Uri url(String path) => Uri.parse(localUrl + path);

  group('CORS Tests', () {
    test('Preflight request (OPTIONS) should return CORS headers', () async {
      final request = http.Request('OPTIONS', url('/s3/list'));
      request.headers['Origin'] = 'http://example.com';
      request.headers['Access-Control-Request-Method'] = 'GET';
      request.headers['Access-Control-Request-Headers'] = 'Content-Type';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Check for success status (200 or 204 are common for OPTIONS)
      expect(response.statusCode, anyOf(200, 204));

      // Check CORS headers
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

    test(
      'Regular GET request with Origin header should include CORS headers',
      () async {
        final response = await http.get(
          url('/s3/list'),
          headers: {'Origin': 'http://example.com'},
        );

        // Regardless of authentication status (401/200), CORS headers should be present
        // if the request has an Origin header.
        expect(
          response.headers['access-control-allow-origin'],
          isNotNull,
          reason: 'Missing Access-Control-Allow-Origin on GET',
        );
      },
    );

    test(
      'Request from same origin should not necessarily have CORS headers (optional behavior)',
      () async {
        final response = await http.get(url('/s3/list'));

        // Usually, if no Origin is sent, CORS headers are omitted
        expect(
          response.headers.containsKey('access-control-allow-origin'),
          isFalse,
        );
      },
    );
  });
}
