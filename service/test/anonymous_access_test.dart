@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8096, name: 'anonymous_access');
  const bucket = 'anon-bucket';

  String rulesPath(String name) => '/${env.adminPrefix}/bucket/$name/anonymous-access';

  Future<http.Response> addRule(String prefix, String access, {String name = bucket}) {
    return http.post(
      server.url(rulesPath(name)),
      headers: {...server.auth(), 'content-type': 'application/json'},
      body: jsonEncode({'prefix': prefix, 'access': access}),
    );
  }

  Future<http.Response> deleteRule(String prefix) {
    final request = http.Request('DELETE', server.url(rulesPath(bucket)))
      ..headers.addAll({...server.auth(), 'content-type': 'application/json'})
      ..body = jsonEncode({'prefix': prefix});
    return request.send().then(http.Response.fromStream);
  }

  Future<List> listRules() async {
    final response = await http.get(server.url(rulesPath(bucket)), headers: server.auth());
    expect(response.statusCode, 200);
    return jsonDecode(response.body) as List;
  }

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'public/logo.png', 'png');
    await server.putObject(bucket, 'public/docs/manual.pdf', 'pdf');
    await server.putObject(bucket, 'private/secret.txt', 'secret');
    await server.putObject(bucket, 'photos/cat.jpg', 'jpg');
    await server.putObject(bucket, 'photos/cat.png', 'png');
    await server.putObject(bucket, 'photos/cat.jpg.zip', 'zip');
    await server.putObject(bucket, 'a+b/file.txt', 'literal');

    expect((await addRule('public/', 'readOnly')).statusCode, 200);
    expect((await addRule('inbox/', 'writeOnly')).statusCode, 200);
    expect((await addRule('shared/', 'readWrite')).statusCode, 200);
    expect((await addRule('photos/*.jpg', 'readOnly')).statusCode, 200);
    expect((await addRule('a+b/', 'readOnly')).statusCode, 200);
  });
  tearDownAll(server.stop);

  group('Anonymous access - Rules API', () {
    test('Should list the rules in creation order', () async {
      final rules = await listRules();
      expect(rules.map((r) => r['prefix']), [
        'public/',
        'inbox/',
        'shared/',
        'photos/*.jpg',
        'a+b/',
      ]);
      expect(rules.first['access'], 'readOnly');
    });

    test('Should reject an unknown access type (422)', () async {
      final response = await addRule('x/', 'everything');
      expect(response.statusCode, 422);
    });

    test('Should reject an empty prefix (422)', () async {
      final response = await addRule('', 'readOnly');
      expect(response.statusCode, 422);
    });

    test('Should return 404 for rules of a non-existent bucket', () async {
      final response = await addRule('x/', 'readOnly', name: 'ghost-bucket');
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchBucket');

      final list = await http.get(server.url(rulesPath('ghost-bucket')), headers: server.auth());
      expect(list.statusCode, 404);
    });

    test('Should delete a rule', () async {
      expect((await addRule('temp/', 'readOnly')).statusCode, 200);
      expect((await deleteRule('temp/')).statusCode, 200);
      expect((await listRules()).map((r) => r['prefix']), isNot(contains('temp/')));
    });

    test('Should fail without auth (401)', () async {
      final response = await http.get(server.url(rulesPath(bucket)));
      expect(response.statusCode, 401);
    });
  });

  group('Anonymous access - S3 requests without credentials', () {
    test('readOnly: should download an object under the prefix', () async {
      final response = await http.get(server.url('/$bucket/public/logo.png'));
      expect(response.statusCode, 200);
      expect(response.body, 'png');
    });

    test('readOnly: should list the prefix', () async {
      final response = await http.get(
        server.url('/$bucket?prefix=public/'),
        headers: {'accept': 'application/json'},
      );
      expect(response.statusCode, 200);
      final keys = (jsonDecode(response.body)['contents'] as List).map((e) => e['key']);
      expect(keys, containsAll(['public/logo.png', 'public/docs/manual.pdf']));
    });

    test('readOnly: should not upload or delete (401)', () async {
      final put = await http.put(server.url('/$bucket/public/new.txt'), body: 'x');
      expect(put.statusCode, 401);
      final delete = await http.delete(server.url('/$bucket/public/logo.png'));
      expect(delete.statusCode, 401);
    });

    test('Should deny objects that no rule covers (401)', () async {
      final response = await http.get(server.url('/$bucket/private/secret.txt'));
      expect(response.statusCode, 401);
    });

    test('Should deny listing the whole bucket (401)', () async {
      final response = await http.get(server.url('/$bucket'));
      expect(response.statusCode, 401);
    });

    test('writeOnly: should upload and delete but not read', () async {
      final put = await http.put(server.url('/$bucket/inbox/form.txt'), body: 'form');
      expect(put.statusCode, 200);
      final get = await http.get(server.url('/$bucket/inbox/form.txt'));
      expect(get.statusCode, 401);
      final list = await http.get(server.url('/$bucket?prefix=inbox/'));
      expect(list.statusCode, 401);
      final delete = await http.delete(server.url('/$bucket/inbox/form.txt'));
      expect(delete.statusCode, 204);
    });

    test('readWrite: should upload, read and delete', () async {
      expect((await http.put(server.url('/$bucket/shared/n.txt'), body: 'n')).statusCode, 200);
      expect((await http.get(server.url('/$bucket/shared/n.txt'))).body, 'n');
      expect((await http.delete(server.url('/$bucket/shared/n.txt'))).statusCode, 204);
    });

    test('Should support * as a wildcard', () async {
      expect((await http.get(server.url('/$bucket/photos/cat.jpg'))).statusCode, 200);
      expect((await http.get(server.url('/$bucket/photos/cat.png'))).statusCode, 401);
    });

    test('Should match the whole key when the rule has *', () async {
      // photos/*.jpg doesn't open photos/cat.jpg.zip
      expect((await http.get(server.url('/$bucket/photos/cat.jpg.zip'))).statusCode, 401);
    });

    test('Should treat regex characters in the prefix literally', () async {
      expect((await http.get(server.url('/$bucket/a%2Bb/file.txt'))).statusCode, 200);
      // With '+' as a regex, 'aab/' would match 'a+b/'
      await server.putObject(bucket, 'aab/file.txt', 'no');
      expect((await http.get(server.url('/$bucket/aab/file.txt'))).statusCode, 401);
    });

    test('Should never allow an anonymous multi-delete (401)', () async {
      final response = await http.post(
        server.url('/$bucket?delete'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'objects': [
            {'key': 'shared/x.txt'},
          ],
        }),
      );
      expect(response.statusCode, 401);
    });

    test('Should not apply the rules of one bucket to another', () async {
      await server.putObject('other-bucket', 'public/logo.png', 'png');
      final response = await http.get(server.url('/other-bucket/public/logo.png'));
      expect(response.statusCode, 401);
    });

    test('Should stop working once the rule is deleted', () async {
      expect((await addRule('temp-public/', 'readOnly')).statusCode, 200);
      await server.putObject(bucket, 'temp-public/a.txt', 'a');
      expect((await http.get(server.url('/$bucket/temp-public/a.txt'))).statusCode, 200);

      expect((await deleteRule('temp-public/')).statusCode, 200);
      expect((await http.get(server.url('/$bucket/temp-public/a.txt'))).statusCode, 401);
    });
  });

  group('Anonymous access - Bucket lifecycle', () {
    test('Should drop the rules when the bucket is deleted', () async {
      final create = await http.put(server.url('/short-lived'), headers: server.auth());
      expect(create.statusCode, 200);
      expect((await addRule('public/', 'readOnly', name: 'short-lived')).statusCode, 200);

      final delete = await http.delete(server.url('/short-lived'), headers: server.auth());
      expect(delete.statusCode, 204);

      final again = await http.put(server.url('/short-lived'), headers: server.auth());
      expect(again.statusCode, 200);
      final rules = await http.get(server.url(rulesPath('short-lived')), headers: server.auth());
      expect(jsonDecode(rules.body), isEmpty);
    });
  });

  group('Anonymous access - multipart is never anonymous', () {
    // shared/ has a readWrite rule: even so, an anonymous client can't touch
    // the multipart uploads (neither other users' nor its own)
    late String uploadId;

    setUpAll(() async {
      final created = await http.post(
        server.url('/$bucket/shared/big.bin?uploads'),
        headers: server.auth(json: true),
      );
      expect(created.statusCode, 200, reason: created.body);
      uploadId = jsonDecode(created.body)['upload_id'] as String;
    });

    void expectDenied(http.Response response) {
      expect(response.statusCode, 403, reason: response.body);
      expect(response.body, contains('AccessDenied'));
    }

    test('Should not list the pending uploads (ListMultipartUploads)', () async {
      expectDenied(
        await http.get(server.url('/$bucket?uploads&prefix=shared/')),
      );
    });

    test('Should not list the parts of an upload (ListParts)', () async {
      expectDenied(
        await http.get(server.url('/$bucket/shared/big.bin?uploadId=$uploadId')),
      );
    });

    test('Should not upload a part (UploadPart)', () async {
      expectDenied(
        await http.put(
          server.url('/$bucket/shared/big.bin?partNumber=1&uploadId=$uploadId'),
          body: 'intruder',
        ),
      );
    });

    test('Should not abort an upload (AbortMultipartUpload)', () async {
      expectDenied(
        await http.delete(
          server.url('/$bucket/shared/big.bin?uploadId=$uploadId'),
        ),
      );
    });

    test('Should not start or complete an upload', () async {
      expect(
        (await http.post(server.url('/$bucket/shared/other.bin?uploads'))).statusCode,
        401,
      );
      expect(
        (await http.post(
          server.url('/$bucket/shared/big.bin?uploadId=$uploadId'),
          body: '<CompleteMultipartUpload/>',
        )).statusCode,
        401,
      );
    });

    test('Should leave the upload untouched for its owner', () async {
      final parts = await http.get(
        server.url('/$bucket/shared/big.bin?uploadId=$uploadId'),
        headers: server.auth(json: true),
      );
      expect(parts.statusCode, 200, reason: parts.body);
      expect(jsonDecode(parts.body), isEmpty);

      final aborted = await http.delete(
        server.url('/$bucket/shared/big.bin?uploadId=$uploadId'),
        headers: server.auth(),
      );
      expect(aborted.statusCode, 204);
    });
  });

  group('AnonymousAccessService.matches', () {
    test('Should treat a rule without * as a prefix', () {
      expect(AnonymousAccessService.matches('public/', 'public/a/b.txt'), isTrue);
      expect(AnonymousAccessService.matches('public', 'public-2/x'), isTrue);
      expect(AnonymousAccessService.matches('public/', 'private/a.txt'), isFalse);
    });

    test('Should match the whole key when the rule has *', () {
      expect(AnonymousAccessService.matches('photos/*.jpg', 'photos/a.jpg'), isTrue);
      expect(AnonymousAccessService.matches('photos/*.jpg', 'photos/2026/a.jpg'), isTrue);
      expect(AnonymousAccessService.matches('photos/*.jpg', 'photos/a.jpg.zip'), isFalse);
      expect(AnonymousAccessService.matches('*.jpg', 'a/b/c.jpg'), isTrue);
      expect(AnonymousAccessService.matches('docs/*', 'docs/a/b.pdf'), isTrue);
      expect(AnonymousAccessService.matches('*', 'any/thing'), isTrue);
    });

    test('Should ignore a leading slash and treat regex characters literally', () {
      expect(AnonymousAccessService.matches('/public/', 'public/a.txt'), isTrue);
      expect(AnonymousAccessService.matches('a+b/', 'aab/x'), isFalse);
      expect(AnonymousAccessService.matches('a.b*', 'axb'), isFalse);
    });
  });
}
