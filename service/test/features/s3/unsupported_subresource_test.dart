@TestOn('vm')
library;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8103, name: 'unsupported_subresource');
  const bucket = 'sub-bucket';

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'a.txt', 'content');
  });
  tearDownAll(server.stop);

  void expectNotImplemented(http.Response response) {
    expect(response.statusCode, 501, reason: response.body);
    expect(response.body, contains('<Code>NotImplemented</Code>'));
  }

  group('UnsupportedSubresourceFilter', () {
    test('Should answer 501 to bucket subresources', () async {
      for (final sub in ['policy', 'tagging', 'encryption', 'acl', 'lifecycle']) {
        expectNotImplemented(
          await http.get(server.url('/$bucket?$sub'), headers: server.auth()),
        );
      }
    });

    test('Should not create a bucket with PUT ?versioning', () async {
      expectNotImplemented(
        await http.put(
          server.url('/other-bucket?versioning'),
          headers: server.auth(),
          body: '<VersioningConfiguration/>',
        ),
      );
      expect(await Directory('${server.storagePath}/other-bucket').exists(), isFalse);
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
        'content',
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

  group('S3Controller - GetObjectTagging', () {
    test('Should answer an empty TagSet for an existing object', () async {
      final response = await http.get(
        server.url('/$bucket/a.txt?tagging'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.body, contains('<TagSet></TagSet>'));
    });

    test('Should return 404 for a missing object', () async {
      final response = await http.get(
        server.url('/$bucket/missing.txt?tagging'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
    });

    test('Should still answer 501 to writing tags', () async {
      expectNotImplemented(
        await http.put(
          server.url('/$bucket/a.txt?tagging'),
          headers: server.auth(),
          body: '<Tagging><TagSet/></Tagging>',
        ),
      );
    });
  });

  group('S3Controller - GetBucketVersioning', () {
    test('Should answer that versioning was never enabled', () async {
      final response = await http.get(
        server.url('/$bucket?versioning'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.body, contains('<VersioningConfiguration'));
      expect(response.body, isNot(contains('<Status>')));
    });

    test('Should return 404 for a missing bucket', () async {
      final response = await http.get(
        server.url('/missing?versioning'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
    });
  });
}
