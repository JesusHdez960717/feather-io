@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8113, name: 'i18n');

  setUpAll(server.start);
  tearDownAll(server.stop);

  String keysPath() => '/${env.adminPrefix}/access-keys';

  Future<http.Response> getMissingBucket({
    String? language,
    bool json = false,
  }) => http.get(
    server.url('/no-such-bucket'),
    headers: {
      ...server.auth(json: json),
      'accept-language': ?language,
    },
  );

  Future<http.Response> createKey(Map<String, dynamic> body, String language) =>
      http.post(
        server.url(keysPath()),
        headers: {...server.auth(json: true), 'accept-language': language},
        body: jsonEncode(body),
      );

  List<String> messages(http.Response response) => [
    for (final violation in jsonDecode(response.body) as List)
      violation['message'] as String,
  ];

  group('Localized error messages', () {
    test('Should answer in English without Accept-Language (XML)', () async {
      final response = await getMissingBucket();
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchBucket</Code>'));
      expect(
        response.body,
        contains(
          '<Message>The bucket &quot;no-such-bucket&quot; does not exist.</Message>',
        ),
      );
      expect(response.headers['vary'], contains('Accept-Language'));
    });

    test('Should translate the message but never the code (XML)', () async {
      final response = await getMissingBucket(language: 'es');
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchBucket</Code>'));
      expect(
        response.body,
        contains(
          '<Message>El bucket &quot;no-such-bucket&quot; no existe.</Message>',
        ),
      );
      expect(response.headers['vary'], contains('Accept-Language'));
    });

    test('Should translate the JSON error of the admin API', () async {
      final response = await http.get(
        server.url('/${env.adminPrefix}/bucket/no-such-bucket'),
        headers: {...server.auth(json: true), 'accept-language': 'es'},
      );
      expect(response.statusCode, 404);
      final body = jsonDecode(response.body);
      expect(body['code'], 'NoSuchBucket');
      expect(body['message'], 'El bucket "no-such-bucket" no existe.');
      expect(response.headers['vary'], contains('Accept-Language'));
    });

    test(
      'Should resolve regions, q-values and unsupported languages',
      () async {
        final mexico = await getMissingBucket(language: 'es-MX', json: true);
        expect(jsonDecode(mexico.body)['message'], contains('no existe'));

        final weighted = await getMissingBucket(
          language: 'fr;q=1, es;q=0.8',
          json: true,
        );
        expect(jsonDecode(weighted.body)['message'], contains('no existe'));

        final french = await getMissingBucket(language: 'fr', json: true);
        expect(jsonDecode(french.body)['message'], contains('does not exist'));
      },
    );

    test(
      'Should translate the rules of Winter and of the service (422)',
      () async {
        final winterRule = await createKey({'all_buckets': 'readOnly'}, 'es');
        expect(winterRule.statusCode, 422);
        expect(messages(winterRule), contains('El campo no puede ser null'));
        expect(winterRule.headers['vary'], contains('Accept-Language'));

        final serviceRule = await createKey({'name': 'No scope'}, 'es');
        expect(serviceRule.statusCode, 422);
        expect(
          messages(serviceRule),
          contains('Dale a la clave all_buckets o al menos un bucket'),
        );

        final english = await createKey({'name': 'No scope'}, 'en');
        expect(
          messages(english),
          contains('Give the key all_buckets or at least one bucket'),
        );
      },
    );

    test(
      'Should translate the violation of an expiration in the past',
      () async {
        final response = await createKey({
          'name': 'Old',
          'all_buckets': 'readOnly',
          'expires_at': '2020-01-01T00:00:00Z',
        }, 'es');
        expect(response.statusCode, 422);
        expect(
          messages(response),
          contains('La fecha de caducidad debe ser futura'),
        );
      },
    );

    test('Should not mix the languages of concurrent requests', () async {
      final languages = [for (var i = 0; i < 40; i++) i.isEven ? 'es' : 'en'];
      final responses = await Future.wait([
        for (final language in languages)
          getMissingBucket(language: language, json: true),
      ]);
      for (var i = 0; i < languages.length; i++) {
        expect(
          jsonDecode(responses[i].body)['message'],
          languages[i] == 'es'
              ? 'El bucket "no-such-bucket" no existe.'
              : 'The bucket "no-such-bucket" does not exist.',
        );
      }
    });

    test('Should translate a failed login', () async {
      final response = await http.post(
        server.url('/${env.adminPrefix}/login'),
        headers: {'content-type': 'application/json', 'accept-language': 'es'},
        body: jsonEncode({'access': testAccess, 'secret': 'wrong'}),
      );
      expect(response.statusCode, 403);
      final body = jsonDecode(response.body);
      expect(body['code'], 'InvalidCredentials');
      expect(body['message'], 'Credenciales no válidas');
    });
  });
}
