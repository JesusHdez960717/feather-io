@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8100, name: 'body_size');
  const bucket = 'big-bucket';
  const mb = 1024 * 1024;

  setUpAll(() async {
    //por encima de los 10 MB que Winter deja por defecto
    env.put('MAX_OBJECT_SIZE', '${12 * mb}');
    await server.start();
    await server.createBucket(bucket);
  });
  tearDownAll(server.stop);

  Future<http.Response> put(String key, int size, {bool json = false}) =>
      http.put(
        server.url('/$bucket/$key'),
        headers: server.auth(json: json),
        body: List<int>.filled(size, 7),
      );

  group('BodySizeFilter - objects', () {
    test('Should upload an object bigger than 10 MB', () async {
      final response = await put('grande.bin', 11 * mb);
      expect(response.statusCode, 200, reason: response.body);

      final stored = File('${server.storagePath}/$bucket/grande.bin');
      expect(await stored.length(), 11 * mb);
    });

    test(
      'Should reject an object over MAX_OBJECT_SIZE with EntityTooLarge',
      () async {
        final response = await put('enorme.bin', 13 * mb);
        expect(response.statusCode, 400);
        expect(response.body, contains('<Code>EntityTooLarge</Code>'));
        expect(
          File('${server.storagePath}/$bucket/enorme.bin').existsSync(),
          isFalse,
        );
      },
    );

    test('Should answer EntityTooLarge as JSON when asked', () async {
      final response = await put('enorme.bin', 13 * mb, json: true);
      expect(response.statusCode, 400);
      expect(jsonDecode(response.body)['code'], 'EntityTooLarge');
    });
  });

  group('BodySizeFilter - other requests', () {
    test('Should reject a JSON body over 2 MB (413)', () async {
      final response = await http.post(
        server.url('/${env.adminPrefix}/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'access': 'a' * (3 * mb), 'secret': testSecret}),
      );
      expect(response.statusCode, 413);
    });

    Future<http.StreamedResponse> chunkedLogin(List<int> body) {
      final request = http.StreamedRequest(
        'POST',
        server.url('/${env.adminPrefix}/login'),
      )..headers['content-type'] = 'application/json';
      //send() primero: el sink no se cierra hasta que alguien lee el stream.
      //Si el servidor corta, el error llega por el futuro de send()
      final sent = request.send();
      request.sink.add(body);
      unawaited(request.sink.close());
      return sent;
    }

    test('Should accept a chunked body without Content-Length', () async {
      final response = await chunkedLogin(
        utf8.encode(jsonEncode({'access': testAccess, 'secret': testSecret})),
      );
      expect(response.statusCode, 200);
    });

    test('Should cut a chunked body over 2 MB while reading it (413)', () async {
      try {
        final response = await chunkedLogin(
          utf8.encode(jsonEncode({'access': 'a' * (3 * mb), 'secret': testSecret})),
        );
        expect(response.statusCode, 413);
      } on http.ClientException {
        //el servidor responde 413 y cierra antes de que el cliente acabe de
        //escribir: tambien demuestra que no leyo el cuerpo entero
      }
    });

    test('Should still accept a normal JSON request', () async {
      final response = await http.post(
        server.url('/${env.adminPrefix}/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'access': testAccess, 'secret': testSecret}),
      );
      expect(response.statusCode, 200);
    });
  });
}
