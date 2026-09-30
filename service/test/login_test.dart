@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8089, name: 'login');

  setUpAll(server.start);
  tearDownAll(server.stop);

  Future<http.Response> login(Object body) => http.post(
    server.url('/${env.adminPrefix}/login'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode(body),
  );

  group('AdminController - Login', () {
    test('Should issue a token with valid credentials', () async {
      final response = await login({'access': testAccess, 'secret': testSecret});
      expect(response.statusCode, 200);
      final body = jsonDecode(response.body);
      expect(body['access_token'], isNotEmpty);
      expect(body['expires_in'], greaterThan(0));
      expect(body['expire_at'], greaterThan(DateTime.now().millisecondsSinceEpoch));
    });

    test('Should reject wrong credentials (403)', () async {
      final response = await login({'access': testAccess, 'secret': 'wrong'});
      expect(response.statusCode, 403);
    });

    test('Should reject a malformed body (400)', () async {
      final response = await login({'access': testAccess});
      expect(response.statusCode, 400);
    });

    test('Should authorize requests with the issued token', () async {
      final response = await login({'access': testAccess, 'secret': testSecret});
      final token = jsonDecode(response.body)['access_token'];

      final list = await http.get(
        server.url('/'),
        headers: {'authorization': 'Bearer $token'},
      );
      expect(list.statusCode, 200);
    });
  });
}
