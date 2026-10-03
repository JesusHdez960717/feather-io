@TestOn('vm')
library;

import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
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

    test('Should reject wrong credentials (403) after the 1 s penalty', () async {
      final watch = Stopwatch()..start();
      final response = await login({'access': testAccess, 'secret': 'wrong'});
      expect(response.statusCode, 403);
      expect(watch.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 900)));
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

  group('AdminController - Login security', () {
    final claims = {
      'sub': testAccess,
      'roles': ['admin'],
      'permissions': ['s3.list-buckets'],
    };
    Future<int> listWith(String token) async => (await http.get(
      server.url('/'),
      headers: {'authorization': 'Bearer $token'},
    )).statusCode;

    test('Should reject a token without exp (it would never expire)', () async {
      final token = JWT(claims).sign(SecretKey('test-jwt-secret-${server.port}'));
      expect(await listWith(token), 401);
    });

    test('Should reject an expired token', () async {
      final token = JWT({...claims, 'exp': 1000}).sign(
        SecretKey('test-jwt-secret-${server.port}'),
      );
      expect(await listWith(token), 401);
    });

    test('Should reject a token signed with another secret', () async {
      final exp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      final token = JWT({...claims, 'exp': exp}).sign(SecretKey('otro-secreto'));
      expect(await listWith(token), 401);
    });

    test('Should reject an unsigned token (alg none)', () async {
      String b64(Object o) =>
          base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
      final token = '${b64({'alg': 'none', 'typ': 'JWT'})}.${b64(claims)}.';
      expect(await listWith(token), 401);
    });

    test('Should not reveal internal details on a malformed login', () async {
      final response = await login({'access': 1, 'secret': true});
      expect(response.statusCode, 400);
      expect(response.body, isNot(contains('Exception')));
      expect(response.body, isNot(contains('subtype')));
    });
  });
}
