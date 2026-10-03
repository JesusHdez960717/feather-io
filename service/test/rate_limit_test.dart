@TestOn('vm')
library;

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8108, name: 'rate_limit');
  const window = Duration(seconds: 2);

  setUpAll(() async {
    // Small limit for the test: 5 requests every 2 s per IP
    env.put('RATE_LIMIT_REQUESTS', '5');
    env.put('RATE_LIMIT_WINDOW_SECONDS', '${window.inSeconds}');
    await server.start();
  });
  tearDownAll(server.stop);

  /// Waits for the window to empty (server.start's login counts too).
  Future<void> newWindow() =>
      Future<void>.delayed(window + const Duration(milliseconds: 200));

  group('RateLimiterFilter (general limit per IP)', () {
    test('Should send the rate limit headers', () async {
      await newWindow();
      final response = await http.get(server.url('/'), headers: server.auth());
      expect(response.statusCode, 200);
      expect(response.headers['x-ratelimit-limit'], '5');
      expect(response.headers['x-ratelimit-remaining'], '4');
    });

    test('Should answer 503 SlowDown on the S3 API, like S3', () async {
      await newWindow();
      final statuses = <int>[];
      for (var i = 0; i < 6; i++) {
        statuses.add((await http.get(server.url('/'), headers: server.auth())).statusCode);
      }
      // S3 clients retry a 503 SlowDown with backoff; they don't retry a 429
      expect(statuses, [200, 200, 200, 200, 200, 503]);

      final limited = await http.get(server.url('/'), headers: server.auth());
      expect(limited.statusCode, 503);
      expect(limited.headers['content-type'], contains('application/xml'));
      expect(limited.body, contains('<Code>SlowDown</Code>'));
      expect(int.parse(limited.headers['retry-after']!), inInclusiveRange(1, 2));
      expect(limited.headers['x-ratelimit-remaining'], '0');

      final json = await http.get(server.url('/'), headers: server.auth(json: true));
      expect(json.statusCode, 503);
      expect(json.body, contains('"SlowDown"'));
    });

    test('Should answer 429 on the admin API (the console)', () async {
      await newWindow();
      for (var i = 0; i < 5; i++) {
        await http.get(server.url('/'), headers: server.auth());
      }
      final admin = await http.get(
        server.url('/${env.adminPrefix}/bucket/x'),
        headers: server.auth(),
      );
      expect(admin.statusCode, 429);
      expect(admin.headers['retry-after'], isNotNull);
    });

    test('Should limit every kind of request: anonymous, admin and login', () async {
      await newWindow();
      for (var i = 0; i < 5; i++) {
        await http.get(server.url('/'));
      }
      expect((await http.get(server.url('/'))).statusCode, 503);
      expect(
        (await http.get(
          server.url('/${env.adminPrefix}/bucket/x'),
          headers: server.auth(),
        )).statusCode,
        429,
      );
      expect(
        (await http.post(server.url('/${env.adminPrefix}/login'))).statusCode,
        429,
      );
    });

    test('Should not be bypassed with a fake X-Forwarded-For', () async {
      await newWindow();
      for (var i = 0; i < 5; i++) {
        await http.get(server.url('/'), headers: server.auth());
      }
      final spoofed = await http.get(
        server.url('/'),
        headers: {...server.auth(), 'x-forwarded-for': '203.0.113.7'},
      );
      expect(spoofed.statusCode, 503);
    });

    test('Should allow requests again in the next window', () async {
      await newWindow();
      for (var i = 0; i < 6; i++) {
        await http.get(server.url('/'), headers: server.auth());
      }
      await newWindow();
      expect(
        (await http.get(server.url('/'), headers: server.auth())).statusCode,
        200,
      );
    });
  });
}
