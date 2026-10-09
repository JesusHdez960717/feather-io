@TestOn('vm')
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8111, name: 'access_keys');
  const photos = 'ak-photos';
  const backups = 'ak-backups';
  const inbox = 'ak-inbox';

  String keysPath([String suffix = '']) =>
      '/${env.adminPrefix}/access-keys$suffix';

  Map<String, String> jsonAuth() => {
    ...server.auth(),
    'content-type': 'application/json',
  };

  Future<http.Response> createKey(Map<String, dynamic> body) => http.post(
    server.url(keysPath()),
    headers: jsonAuth(),
    body: jsonEncode(body),
  );

  /// Creates a key and returns its JSON (with the secret).
  Future<Map<String, dynamic>> newKey(Map<String, dynamic> body) async {
    final response = await createKey(body);
    expect(response.statusCode, 201, reason: response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<http.Response> updateKey(String id, Map<String, dynamic> body) =>
      http.put(
        server.url(keysPath('/$id')),
        headers: jsonAuth(),
        body: jsonEncode(body),
      );

  Future<Map<String, dynamic>> listKeys() async {
    final response = await http.get(
      server.url(keysPath()),
      headers: server.auth(),
    );
    expect(response.statusCode, 200);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// A request signed with [key] (its id and secret).
  Future<http.Response> signed(
    String method,
    String path,
    Map<String, dynamic> key, {
    List<int>? body,
    Map<String, String> headers = const {},
    String? secret,
  }) {
    final request = http.Request(method, server.url(path))
      ..headers.addAll(
        server.sigV4(
          method,
          path,
          access: key['access_key_id'] as String,
          secret: secret ?? key['secret_access_key'] as String,
          extraHeaders: headers,
        ),
      );
    if (body != null) request.bodyBytes = body;
    return request.send().then(http.Response.fromStream);
  }

  setUpAll(() async {
    await server.start();
    await server.putObject(photos, 'cat.jpg', 'meow');
    await server.putObject(backups, 'db.sql', 'dump');
    await server.createBucket(inbox);
  });
  tearDownAll(server.stop);

  group('Access keys - admin API', () {
    test('Should create a key and show its secret once', () async {
      final key = await newKey({
        'name': 'Web CDN',
        'buckets': [
          {'bucket': photos, 'access': 'readOnly'},
        ],
      });
      expect(key['access_key_id'], matches(RegExp(r'^FIOK[A-Z2-7]{16}$')));
      expect(key['secret_access_key'], matches(RegExp(r'^[A-Za-z0-9]{40}$')));
      expect(key['name'], 'Web CDN');
      expect(key['enabled'], isTrue);
      expect(key['expired'], isFalse);
      expect(key['all_buckets'], isNull);
      expect(key['buckets'], [
        {'bucket': photos, 'access': 'readOnly'},
      ]);
      expect(key['last_used_at'], isNull);

      final listed = await listKeys();
      expect(listed['root_access_key_id'], testAccess);
      final found = (listed['keys'] as List).firstWhere(
        (k) => k['access_key_id'] == key['access_key_id'],
      );
      expect(found.containsKey('secret_access_key'), isFalse);
    });

    test('Should store the secret encrypted', () async {
      final key = await newKey({'name': 'Stored', 'all_buckets': 'readOnly'});
      final db = di.find<AppDatabase>();
      final row = await (db.select(
        db.accessKeyTable,
      )..where((t) => t.id.equals(key['access_key_id']))).getSingle();
      expect(row.secretEncrypted, isNot(contains(key['secret_access_key'])));
      expect(
        di.find<SecretCipher>().decrypt(
          row.secretEncrypted,
          associatedData: key['access_key_id'],
        ),
        key['secret_access_key'],
      );
    });

    test('Should require the JWT (401)', () async {
      final response = await http.get(server.url(keysPath()));
      expect(response.statusCode, 401);
    });

    test('Should not be reachable with a SigV4 signature (401)', () async {
      final path = keysPath();
      final response = await http.get(
        server.url(path),
        headers: server.sigV4('GET', path),
      );
      expect(response.statusCode, 401);
    });

    test('Should reject a key without name or scope (422)', () async {
      expect((await createKey({'all_buckets': 'readOnly'})).statusCode, 422);
      expect((await createKey({'name': 'No scope'})).statusCode, 422);
      expect((await createKey({'name': 'x', 'buckets': []})).statusCode, 422);
    });

    test(
      'Should reject both scopes, bad levels and repeated buckets (422)',
      () async {
        final both = await createKey({
          'name': 'Both',
          'all_buckets': 'readOnly',
          'buckets': [
            {'bucket': photos, 'access': 'readOnly'},
          ],
        });
        expect(both.statusCode, 422);

        final badLevel = await createKey({
          'name': 'Bad',
          'buckets': [
            {'bucket': photos, 'access': 'everything'},
          ],
        });
        expect(badLevel.statusCode, 422);
        expect(
          (jsonDecode(badLevel.body)['violations'] as List).single['fieldName'],
          'buckets[0].access',
        );

        final repeated = await createKey({
          'name': 'Twice',
          'buckets': [
            {'bucket': photos, 'access': 'readOnly'},
            {'bucket': photos, 'access': 'writeOnly'},
          ],
        });
        expect(repeated.statusCode, 422);

        final longName = await createKey({
          'name': 'x' * 65,
          'all_buckets': 'readOnly',
        });
        expect(longName.statusCode, 422);
      },
    );

    test(
      'Should name the field of a body with the wrong shape (400)',
      () async {
        final response = await createKey({
          'name': 'Shape',
          'buckets': ['photos'],
        });
        expect(response.statusCode, 400);
        expect(
          jsonDecode(response.body)['detail'],
          r'$.buckets[0]: expected an object, got a string',
        );
      },
    );

    test('Should reject an expiration in the past (422)', () async {
      final response = await createKey({
        'name': 'Old',
        'all_buckets': 'readOnly',
        'expires_at': '2020-01-01T00:00:00Z',
      });
      expect(response.statusCode, 422);
    });

    test('Should return 404 for a bucket that does not exist', () async {
      final response = await createKey({
        'name': 'Ghost',
        'buckets': [
          {'bucket': 'no-such-bucket', 'access': 'readOnly'},
        ],
      });
      expect(response.statusCode, 404);
      expect(jsonDecode(response.body)['code'], 'NoSuchBucket');
    });

    test('Should update name, scope and state', () async {
      final key = await newKey({'name': 'Before', 'all_buckets': 'readOnly'});
      final response = await updateKey(key['access_key_id'], {
        'name': 'After',
        'enabled': false,
        'buckets': [
          {'bucket': backups, 'access': 'readWrite'},
        ],
      });
      expect(response.statusCode, 200, reason: response.body);
      final updated = jsonDecode(response.body);
      expect(updated['name'], 'After');
      expect(updated['enabled'], isFalse);
      expect(updated['all_buckets'], isNull);
      expect(updated['buckets'], [
        {'bucket': backups, 'access': 'readWrite'},
      ]);
      expect(updated.containsKey('secret_access_key'), isFalse);
    });

    test('Should return 404 for an unknown key', () async {
      final update = await updateKey('FIOKNOPE', {
        'name': 'x',
        'all_buckets': 'readOnly',
      });
      expect(update.statusCode, 404);
      final delete = await http.delete(
        server.url(keysPath('/FIOKNOPE')),
        headers: server.auth(),
      );
      expect(delete.statusCode, 404);
    });
  });

  group('Access keys - S3 with a key', () {
    test('A read-only key reads its bucket and nothing else', () async {
      final key = await newKey({
        'name': 'Reader',
        'buckets': [
          {'bucket': photos, 'access': 'readOnly'},
        ],
      });

      final get = await signed('GET', '/$photos/cat.jpg', key);
      expect(get.statusCode, 200);
      expect(get.body, 'meow');
      expect((await signed('GET', '/$photos', key)).statusCode, 200);

      final put = await signed(
        'PUT',
        '/$photos/dog.jpg',
        key,
        body: utf8.encode('woof'),
      );
      expect(put.statusCode, 403);
      expect((await signed('DELETE', '/$photos/cat.jpg', key)).statusCode, 403);

      expect((await signed('GET', '/$backups/db.sql', key)).statusCode, 403);
      expect((await signed('GET', '/$backups', key)).statusCode, 403);
      expect((await signed('PUT', '/ak-new-bucket', key)).statusCode, 403);
    });

    test('A write-only key uploads but does not read', () async {
      final key = await newKey({
        'name': 'Writer',
        'buckets': [
          {'bucket': inbox, 'access': 'writeOnly'},
        ],
      });

      final put = await signed(
        'PUT',
        '/$inbox/form.txt',
        key,
        body: utf8.encode('hello'),
      );
      expect(put.statusCode, 200, reason: put.body);
      expect((await signed('GET', '/$inbox/form.txt', key)).statusCode, 403);
      expect((await signed('GET', '/$inbox', key)).statusCode, 403);
      expect((await signed('DELETE', '/$inbox/form.txt', key)).statusCode, 204);
    });

    test('ListBuckets only shows the buckets of the key', () async {
      final key = await newKey({
        'name': 'Lister',
        'buckets': [
          {'bucket': photos, 'access': 'readOnly'},
          {'bucket': inbox, 'access': 'writeOnly'},
        ],
      });
      final response = await signed('GET', '/', key);
      expect(response.statusCode, 200);
      expect(response.body, contains('<Name>$photos</Name>'));
      expect(response.body, contains('<Name>$inbox</Name>'));
      expect(response.body, isNot(contains('<Name>$backups</Name>')));
    });

    test('A key on every bucket with write access creates buckets', () async {
      final key = await newKey({'name': 'CI', 'all_buckets': 'readWrite'});
      expect((await signed('PUT', '/ak-ci-bucket', key)).statusCode, 200);
      expect((await signed('GET', '/$backups/db.sql', key)).statusCode, 200);
      expect((await signed('DELETE', '/ak-ci-bucket', key)).statusCode, 204);

      final reader = await newKey({'name': 'All', 'all_buckets': 'readOnly'});
      expect((await signed('PUT', '/ak-ro-bucket', reader)).statusCode, 403);
      expect((await signed('GET', '/$backups/db.sql', reader)).statusCode, 200);
    });

    test('Copying needs read access to the source bucket', () async {
      final key = await newKey({
        'name': 'Copier',
        'buckets': [
          {'bucket': inbox, 'access': 'readWrite'},
          {'bucket': photos, 'access': 'writeOnly'},
        ],
      });

      final denied = await signed(
        'PUT',
        '/$inbox/stolen.sql',
        key,
        headers: {'x-amz-copy-source': '/$backups/db.sql'},
      );
      expect(denied.statusCode, 403);
      expect(denied.body, contains('AccessDenied'));

      final writeOnlySource = await signed(
        'PUT',
        '/$inbox/cat.jpg',
        key,
        headers: {'x-amz-copy-source': '/$photos/cat.jpg'},
      );
      expect(writeOnlySource.statusCode, 403);

      await server.putObject(inbox, 'source.txt', 'copy me');
      final allowed = await signed(
        'PUT',
        '/$photos/copied.txt',
        key,
        headers: {'x-amz-copy-source': '/$inbox/source.txt'},
      );
      expect(allowed.statusCode, 200, reason: allowed.body);
    });

    test('A disabled key answers InvalidAccessKeyId', () async {
      final key = await newKey({'name': 'Paused', 'all_buckets': 'readOnly'});
      expect((await signed('GET', '/$photos/cat.jpg', key)).statusCode, 200);

      final update = await updateKey(key['access_key_id'], {
        'name': 'Paused',
        'enabled': false,
        'all_buckets': 'readOnly',
      });
      expect(update.statusCode, 200);

      final response = await signed('GET', '/$photos/cat.jpg', key);
      expect(response.statusCode, 403);
      expect(response.body, contains('InvalidAccessKeyId'));
    });

    test('An expired key answers InvalidAccessKeyId', () async {
      final key = await newKey({
        'name': 'Short',
        'all_buckets': 'readOnly',
        'expires_at': DateTime.now()
            .add(const Duration(seconds: 2))
            .toUtc()
            .toIso8601String(),
      });
      expect((await signed('GET', '/$photos/cat.jpg', key)).statusCode, 200);
      await Future.delayed(const Duration(milliseconds: 2500));

      final response = await signed('GET', '/$photos/cat.jpg', key);
      expect(response.statusCode, 403);
      expect(response.body, contains('InvalidAccessKeyId'));
      final listed = (await listKeys())['keys'] as List;
      final found = listed.firstWhere(
        (k) => k['access_key_id'] == key['access_key_id'],
      );
      expect(found['expired'], isTrue);
    });

    test('A wrong secret answers SignatureDoesNotMatch', () async {
      final key = await newKey({'name': 'Wrong', 'all_buckets': 'readOnly'});
      final response = await signed(
        'GET',
        '/$photos/cat.jpg',
        key,
        secret: 'x' * 40,
      );
      expect(response.statusCode, 403);
      expect(response.body, contains('SignatureDoesNotMatch'));
    });

    test('Regenerating the secret invalidates the old one', () async {
      final key = await newKey({'name': 'Rotate', 'all_buckets': 'readOnly'});
      final response = await http.post(
        server.url(keysPath('/${key['access_key_id']}/secret')),
        headers: server.auth(),
      );
      expect(response.statusCode, 200);
      final rotated = jsonDecode(response.body) as Map<String, dynamic>;
      expect(rotated['access_key_id'], key['access_key_id']);
      expect(rotated['secret_access_key'], isNot(key['secret_access_key']));

      final old = await signed('GET', '/$photos/cat.jpg', key);
      expect(old.statusCode, 403);
      expect(old.body, contains('SignatureDoesNotMatch'));
      expect(
        (await signed('GET', '/$photos/cat.jpg', rotated)).statusCode,
        200,
      );
    });

    test('A deleted key answers InvalidAccessKeyId', () async {
      final key = await newKey({'name': 'Gone', 'all_buckets': 'readOnly'});
      final response = await http.delete(
        server.url(keysPath('/${key['access_key_id']}')),
        headers: server.auth(),
      );
      expect(response.statusCode, 204);

      final get = await signed('GET', '/$photos/cat.jpg', key);
      expect(get.statusCode, 403);
      expect(get.body, contains('InvalidAccessKeyId'));
    });

    test('Using a key records when it was last used', () async {
      final key = await newKey({'name': 'Used', 'all_buckets': 'readOnly'});
      await signed('GET', '/$photos/cat.jpg', key);
      final listed = (await listKeys())['keys'] as List;
      final found = listed.firstWhere(
        (k) => k['access_key_id'] == key['access_key_id'],
      );
      expect(found['last_used_at'], isNotNull);
    });

    test('Deleting a bucket removes it from the keys', () async {
      await server.createBucket('ak-temp');
      final key = await newKey({
        'name': 'Temp',
        'buckets': [
          {'bucket': 'ak-temp', 'access': 'readWrite'},
          {'bucket': photos, 'access': 'readOnly'},
        ],
      });
      final delete = await http.delete(
        server.url('/ak-temp'),
        headers: server.auth(),
      );
      expect(delete.statusCode, 204);

      final listed = (await listKeys())['keys'] as List;
      final found = listed.firstWhere(
        (k) => k['access_key_id'] == key['access_key_id'],
      );
      expect(found['buckets'], [
        {'bucket': photos, 'access': 'readOnly'},
      ]);
    });
  });
}
