@TestOn('vm')
library;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../../../support/test_server.dart';

void main() {
  final server = TestServer(port: 8102, name: 'bucket_location');
  const bucket = 'location-bucket';

  setUpAll(() async {
    await server.start();
    await server.createBucket(bucket);
  });
  tearDownAll(server.stop);

  group('S3Controller - GetBucketLocation (?location)', () {
    test('Should answer an empty LocationConstraint (us-east-1)', () async {
      final response = await http.get(
        server.url('/$bucket?location'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/xml'));
      expect(response.body, contains('<LocationConstraint'));
      expect(response.body, isNot(contains('<ListBucketResult')));
    });

    test('Should answer a request signed with SigV4', () async {
      final response = await http.get(
        server.url('/$bucket?location'),
        headers: server.sigV4('GET', '/$bucket', query: const {'location': ''}),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(response.body, contains('<LocationConstraint'));
    });

    test('Should return 404 for a missing bucket', () async {
      final response = await http.get(
        server.url('/missing?location'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchBucket</Code>'));
    });

    test('Should fail without auth (401)', () async {
      final response = await http.get(server.url('/$bucket?location'));
      expect(response.statusCode, 401);
    });
  });
}
