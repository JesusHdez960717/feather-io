@TestOn('vm')
library;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8103, name: 'unsupported_subresource');
  const bucket = 'sub-bucket';

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'a.txt', 'contenido');
  });
  tearDownAll(server.stop);

  void expectNotImplemented(http.Response response) {
    expect(response.statusCode, 501, reason: response.body);
    expect(response.body, contains('<Code>NotImplemented</Code>'));
  }

  group('UnsupportedSubresourceFilter', () {
    test('Should answer 501 to bucket subresources', () async {
      for (final sub in ['versioning', 'policy', 'tagging', 'encryption', 'acl']) {
        expectNotImplemented(
          await http.get(server.url('/$bucket?$sub'), headers: server.auth()),
        );
      }
    });

    test('Should not create a bucket with PUT ?versioning', () async {
      expectNotImplemented(
        await http.put(
          server.url('/otro-bucket?versioning'),
          headers: server.auth(),
          body: '<VersioningConfiguration/>',
        ),
      );
      expect(await Directory('${server.storagePath}/otro-bucket').exists(), isFalse);
    });

    test('Should not overwrite an object with PUT ?legal-hold', () async {
      expectNotImplemented(
        await http.put(
          server.url('/$bucket/a.txt?legal-hold'),
          headers: server.auth(),
          body: '<LegalHold/>',
        ),
      );
      expect(
        await File('${server.storagePath}/$bucket/a.txt').readAsString(),
        'contenido',
      );
    });

    test('Should answer 501 to ListParts', () async {
      expectNotImplemented(
        await http.get(
          server.url('/$bucket/a.txt?uploadId=abc'),
          headers: server.auth(),
        ),
      );
    });

    test('Should still serve the supported operations', () async {
      final list = await http.get(server.url('/$bucket'), headers: server.auth());
      expect(list.statusCode, 200);
      final create = await http.post(
        server.url('/$bucket/b.bin?uploads'),
        headers: server.auth(),
      );
      expect(create.statusCode, 200);
    });
  });
}
