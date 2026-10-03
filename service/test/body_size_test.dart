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
    // Above Winter's default 10 MB
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
      final response = await put('big.bin', 11 * mb);
      expect(response.statusCode, 200, reason: response.body);

      final stored = File('${server.storagePath}/$bucket/big.bin');
      expect(await stored.length(), 11 * mb);
    });

    test(
      'Should reject an object over MAX_OBJECT_SIZE with EntityTooLarge',
      () async {
        final response = await put('huge.bin', 13 * mb);
        expect(response.statusCode, 400);
        expect(response.body, contains('<Code>EntityTooLarge</Code>'));
        expect(
          File('${server.storagePath}/$bucket/huge.bin').existsSync(),
          isFalse,
        );
      },
    );

    test('Should answer EntityTooLarge as JSON when asked', () async {
      final response = await put('huge.bin', 13 * mb, json: true);
      expect(response.statusCode, 400);
      expect(jsonDecode(response.body)['code'], 'EntityTooLarge');
    });

    test(
      'Should reject a chunked object over MAX_OBJECT_SIZE while reading it',
      () async {
        // Without Content-Length the size is only known while the body arrives
        final request = http.StreamedRequest(
          'PUT',
          server.url('/$bucket/chunked-huge.bin'),
        )..headers.addAll(server.auth());
        final sent = request.send();
        for (var i = 0; i < 13; i++) {
          request.sink.add(List<int>.filled(mb, 7));
        }
        unawaited(request.sink.close());
        try {
          final response = await sent;
          final body = await response.stream.bytesToString();
          expect(response.statusCode, 400, reason: body);
          expect(body, contains('<Code>EntityTooLarge</Code>'));
        } on http.ClientException {
          // Winter cuts the body at MAX_OBJECT_SIZE while reading it, and
          // dart:io drops the connection because the body wasn't read to the
          // end: the client gets no response, but nothing is stored
        }
        expect(
          File('${server.storagePath}/$bucket/chunked-huge.bin').existsSync(),
          isFalse,
        );
      },
    );
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
      // send() first: the sink doesn't close until someone reads the stream.
      // If the server cuts it, the error comes through send()'s future
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

    test(
      'Should cut a chunked body over 2 MB while reading it (413)',
      () async {
        try {
          final response = await chunkedLogin(
            utf8.encode(
              jsonEncode({'access': 'a' * (3 * mb), 'secret': testSecret}),
            ),
          );
          expect(response.statusCode, 413);
        } on http.ClientException {
          // The server answers 413 and closes before the client finishes
          // writing: that also shows it didn't read the whole body
        }
      },
    );

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
