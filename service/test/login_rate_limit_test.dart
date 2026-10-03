@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8107, name: 'login_rate_limit');

  setUpAll(() async {
    // Small limits, so the test doesn't wait
    env.put('LOGIN_MAX_FAILURES', '3');
    env.put('LOGIN_LOCK_SECONDS', '2');
    env.put('LOGIN_FAILURE_DELAY_MS', '0');
    await server.start();
  });
  tearDownAll(server.stop);

  Future<http.Response> login(
    String secret, {
    Map<String, String> headers = const {},
  }) => http.post(
    server.url('/${env.adminPrefix}/login'),
    headers: {'content-type': 'application/json', ...headers},
    body: jsonEncode({'access': testAccess, 'secret': secret}),
  );

  group('AdminController - Login rate limit', () {
    test('Should lock the IP after 3 failures, even with good credentials', () async {
      for (var i = 0; i < 3; i++) {
        expect((await login('wrong$i')).statusCode, 403);
      }

      final locked = await login(testSecret);
      expect(locked.statusCode, 429);
      expect(int.parse(locked.headers['retry-after']!), inInclusiveRange(1, 2));

      // X-Forwarded-For doesn't count without TRUSTED_PROXIES: it can't bypass the lock
      final spoofed = await login(
        testSecret,
        headers: {'x-forwarded-for': '203.0.113.7'},
      );
      expect(spoofed.statusCode, 429);

      // A token issued before keeps working during the lock
      final list = await http.get(server.url('/'), headers: server.auth());
      expect(list.statusCode, 200);

      // Once the lock ends, the login works again
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect((await login(testSecret)).statusCode, 200);
    });

    test('Should forget the failures after a successful login', () async {
      for (var i = 0; i < 2; i++) {
        expect((await login('wrong$i')).statusCode, 403);
      }
      expect((await login(testSecret)).statusCode, 200);
      for (var i = 0; i < 2; i++) {
        expect((await login('wrong$i')).statusCode, 403);
      }
      expect((await login(testSecret)).statusCode, 200);
    });
  });
}
