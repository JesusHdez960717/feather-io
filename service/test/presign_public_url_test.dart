@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8109, name: 'presign_public_url');
  const bucket = 'public-url-bucket';
  const publicUrl = 'https://s3.example.com';

  setUpAll(() async {
    env.put<String>('PUBLIC_URL', publicUrl);
    await server.start();
    await server.putObject(bucket, 'informe.txt', 'contenido');
  });
  tearDownAll(server.stop);

  Future<String> presign({Map<String, String> headers = const {}}) async {
    final response = await http.post(
      server.url('/${env.adminPrefix}/bucket/$bucket/presign'),
      headers: {
        ...server.auth(json: true),
        'content-type': 'application/json',
        ...headers,
      },
      body: jsonEncode({'key': 'informe.txt', 'expires_in': 3600}),
    );
    expect(response.statusCode, 200, reason: response.body);
    return jsonDecode(response.body)['url'] as String;
  }

  group('PresignService - PUBLIC_URL', () {
    test('Should build the URL with PUBLIC_URL, not with the request', () async {
      final url = await presign();
      expect(url, startsWith('$publicUrl/$bucket/informe.txt?'));
    });

    test('Should ignore a manipulated Host header', () async {
      final url = await presign(headers: {'host': 'atacante.example'});
      expect(Uri.parse(url).host, 's3.example.com');
    });

    test('Should be valid when it arrives through a proxy that keeps the Host', () async {
      //un proxy con HTTPS reenvia por HTTP y conserva el Host publico
      final url = Uri.parse(await presign());
      final response = await http.get(
        server.url('${url.path}?${url.query}'),
        headers: {'host': url.host},
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(response.body, 'contenido');
    });
  });

  group('ExtendedEnv.publicUrl', () {
    tearDown(() => env.put<String>('PUBLIC_URL', publicUrl));

    test('Should accept scheme, host and port', () {
      env.put<String>('PUBLIC_URL', 'http://storage.local:9000/');
      expect(env.publicUrl!.authority, 'storage.local:9000');
    });

    test('Should reject a path, another scheme or a missing host', () {
      for (final value in [
        'https://s3.example.com/s3',
        'ftp://s3.example.com',
        's3.example.com',
        'https://s3.example.com?x=1',
      ]) {
        env.put<String>('PUBLIC_URL', value);
        expect(() => env.publicUrl, throwsArgumentError, reason: value);
      }
    });
  });
}
