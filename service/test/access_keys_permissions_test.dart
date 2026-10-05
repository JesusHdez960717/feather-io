@TestOn('vm')
library;

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

/// What each access key can and can't do: every S3 operation for each level,
/// on its bucket and on another one, keys on every bucket, multipart,
/// presigned URLs, changes of state and the edge cases of the admin API.
void main() {
  final server = TestServer(port: 8112, name: 'access_keys_permissions');
  const other = 'pm-other';

  String keysPath([String suffix = '']) =>
      '/${env.adminPrefix}/access-keys$suffix';

  Map<String, String> jsonAuth() => {
    ...server.auth(),
    'content-type': 'application/json',
  };

  Future<Map<String, dynamic>> newKey(Map<String, dynamic> body) async {
    final response = await http.post(
      server.url(keysPath()),
      headers: jsonAuth(),
      body: jsonEncode(body),
    );
    expect(response.statusCode, 201, reason: response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> keyOn(String bucket, String access) => newKey({
    'name': '$access on $bucket',
    'buckets': [
      {'bucket': bucket, 'access': access},
    ],
  });

  Future<http.Response> updateKey(String id, Map<String, dynamic> body) =>
      http.put(
        server.url(keysPath('/$id')),
        headers: jsonAuth(),
        body: jsonEncode(body),
      );

  Future<Map<String, dynamic>> listedKey(String id) async {
    final response = await http.get(
      server.url(keysPath()),
      headers: server.auth(),
    );
    expect(response.statusCode, 200);
    return ((jsonDecode(response.body)['keys']) as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((k) => k['access_key_id'] == id);
  }

  /// A request signed with [key] (its id and secret), as a native client.
  Future<http.Response> signed(
    String method,
    String path,
    Map<String, dynamic> key, {
    Map<String, String> query = const {},
    List<int>? body,
    Map<String, String> headers = const {},
  }) {
    final url = server.url(path);
    final request =
        http.Request(
            method,
            query.isEmpty ? url : url.replace(queryParameters: query),
          )
          ..headers.addAll(
            server.sigV4(
              method,
              path,
              query: query,
              access: key['access_key_id'] as String,
              secret: key['secret_access_key'] as String,
              extraHeaders: headers,
            ),
          );
    if (body != null) request.bodyBytes = body;
    return request.send().then(http.Response.fromStream);
  }

  /// A presigned GET URL signed with [key], like the ones S3 SDKs build.
  Uri presigned(Map<String, dynamic> key, String bucket, String object) {
    final now = DateTime.now().toUtc();
    final amzDate = SigV4Signer.amzDate(now);
    final scope = SigV4Signer.scope(SigV4Signer.dateStamp(now));
    final path = '/$bucket/$object';
    final query = {
      SigV4Signer.algorithmParam: SigV4Signer.algorithm,
      SigV4Signer.credentialParam: '${key['access_key_id']}/$scope',
      SigV4Signer.dateParam: amzDate,
      SigV4Signer.expiresParam: '600',
      SigV4Signer.signedHeadersParam: 'host',
    };
    final signature = SigV4Signer.signature(
      secret: key['secret_access_key'] as String,
      amzDate: amzDate,
      scope: scope,
      canonicalRequest: SigV4Signer.canonicalRequest(
        method: 'GET',
        path: path,
        query: query,
        headers: {'host': 'localhost:${server.port}'},
        signedHeaders: 'host',
        payloadHash: SigV4Signer.unsignedPayload,
      ),
    );
    return server
        .url(path)
        .replace(
          queryParameters: {...query, SigV4Signer.signatureParam: signature},
        );
  }

  String deleteXml(List<String> keys) =>
      '<Delete>${keys.map((k) => '<Object><Key>$k</Key></Object>').join()}'
      '</Delete>';

  var counter = 0;
  String unique(String prefix) => '$prefix-${counter++}';

  setUpAll(() async {
    await server.start();
    await server.putObject(other, 'seed.txt', 'other bucket');
  });
  tearDownAll(server.stop);

  group('Access keys - permission matrix on one bucket', () {
    /// Each S3 operation against [bucket], with the objects it needs created
    /// first by the root key.
    final operations =
        <
          String,
          Future<http.Response> Function(
            String bucket,
            Map<String, dynamic> key,
          )
        >{
          'ListObjectsV2': (bucket, key) =>
              signed('GET', '/$bucket', key, query: {'list-type': '2'}),
          'GetObject': (bucket, key) => signed('GET', '/$bucket/seed.txt', key),
          'HeadObject': (bucket, key) =>
              signed('HEAD', '/$bucket/seed.txt', key),
          'GetBucketLocation': (bucket, key) =>
              signed('GET', '/$bucket', key, query: {'location': ''}),
          'PutObject': (bucket, key) => signed(
            'PUT',
            '/$bucket/${unique('put')}.txt',
            key,
            body: utf8.encode('new'),
          ),
          'DeleteObject': (bucket, key) async {
            final object = '${unique('del')}.txt';
            await server.putObject(bucket, object, 'x');
            return signed('DELETE', '/$bucket/$object', key);
          },
          'DeleteObjects': (bucket, key) async {
            final object = '${unique('multi')}.txt';
            await server.putObject(bucket, object, 'x');
            return signed(
              'POST',
              '/$bucket',
              key,
              query: {'delete': ''},
              body: utf8.encode(deleteXml([object])),
            );
          },
          'CopyObject (same bucket)': (bucket, key) => signed(
            'PUT',
            '/$bucket/${unique('copy')}.txt',
            key,
            headers: {'x-amz-copy-source': '/$bucket/seed.txt'},
          ),
          'CreateMultipartUpload': (bucket, key) => signed(
            'POST',
            '/$bucket/${unique('mp')}.bin',
            key,
            query: {'uploads': ''},
          ),
          'ListMultipartUploads': (bucket, key) =>
              signed('GET', '/$bucket', key, query: {'uploads': ''}),
          'DeleteBucket': (bucket, key) => signed('DELETE', '/$bucket', key),
        };

    /// Expected status per level; anything not listed must be 403.
    const allowed = <String, Map<String, int>>{
      'readOnly': {
        'ListObjectsV2': 200,
        'GetObject': 200,
        'HeadObject': 200,
        'GetBucketLocation': 200,
      },
      'writeOnly': {
        'PutObject': 200,
        'DeleteObject': 204,
        'DeleteObjects': 200,
        'CreateMultipartUpload': 200,
      },
      'readWrite': {
        'ListObjectsV2': 200,
        'GetObject': 200,
        'HeadObject': 200,
        'GetBucketLocation': 200,
        'PutObject': 200,
        'DeleteObject': 204,
        'DeleteObjects': 200,
        'CopyObject (same bucket)': 200,
        'CreateMultipartUpload': 200,
        'ListMultipartUploads': 200,
      },
    };

    for (final level in allowed.keys) {
      group(level, () {
        final bucket = 'pm-${level.toLowerCase()}';
        late Map<String, dynamic> key;

        setUpAll(() async {
          await server.putObject(bucket, 'seed.txt', 'seed');
          key = await keyOn(bucket, level);
        });

        for (final MapEntry(key: name, value: run) in operations.entries) {
          final expected = allowed[level]![name] ?? 403;
          test('$name on its bucket answers $expected', () async {
            final response = await run(bucket, key);
            expect(response.statusCode, expected, reason: response.body);
          });

          test('$name on a bucket it has no grant for answers 403', () async {
            final response = await run(other, key);
            expect(response.statusCode, 403, reason: response.body);
          });
        }

        test('CreateBucket answers 403', () async {
          final response = await signed('PUT', '/${unique('pm-new')}', key);
          expect(response.statusCode, 403);
        });

        test('ListBuckets only shows its bucket', () async {
          final response = await signed('GET', '/', key);
          expect(response.statusCode, 200);
          expect(response.body, contains('<Name>$bucket</Name>'));
          expect(response.body, isNot(contains('<Name>$other</Name>')));
        });
      });
    }
  });

  group('Access keys - every bucket', () {
    test(
      'Read-only on every bucket reads all of them but writes nothing',
      () async {
        final key = await newKey({'name': 'All RO', 'all_buckets': 'readOnly'});
        expect((await signed('GET', '/$other/seed.txt', key)).statusCode, 200);
        final put = await signed(
          'PUT',
          '/$other/ro.txt',
          key,
          body: utf8.encode('x'),
        );
        expect(put.statusCode, 403);
        expect(
          (await signed('PUT', '/${unique('pm-ro')}', key)).statusCode,
          403,
        );
        final list = await signed('GET', '/', key);
        expect(list.body, contains('<Name>$other</Name>'));
      },
    );

    test(
      'Write-only on every bucket creates and deletes buckets, no reads',
      () async {
        final key = await newKey({
          'name': 'All WO',
          'all_buckets': 'writeOnly',
        });
        final bucket = unique('pm-wo');
        expect((await signed('PUT', '/$bucket', key)).statusCode, 200);
        final put = await signed(
          'PUT',
          '/$bucket/a.txt',
          key,
          body: utf8.encode('x'),
        );
        expect(put.statusCode, 200);
        expect((await signed('GET', '/$bucket/a.txt', key)).statusCode, 403);
        expect((await signed('DELETE', '/$bucket/a.txt', key)).statusCode, 204);
        expect((await signed('DELETE', '/$bucket', key)).statusCode, 204);
      },
    );

    test(
      'Read-write on every bucket reaches buckets created after it',
      () async {
        final key = await newKey({
          'name': 'All RW',
          'all_buckets': 'readWrite',
        });
        final bucket = unique('pm-later');
        await server.putObject(bucket, 'later.txt', 'later');
        expect((await signed('GET', '/$bucket/later.txt', key)).body, 'later');
      },
    );
  });

  group('Access keys - multipart and copies', () {
    test('A write-only key runs a whole multipart upload', () async {
      const bucket = 'pm-multipart';
      await server.createBucket(bucket);
      final key = await keyOn(bucket, 'writeOnly');

      final created = await signed(
        'POST',
        '/$bucket/big.bin',
        key,
        query: {'uploads': ''},
      );
      expect(created.statusCode, 200, reason: created.body);
      final uploadId = RegExp('<UploadId>(.*)</UploadId>')
          .firstMatch(created.body)!
          .group(1)!;

      final part = await signed(
        'PUT',
        '/$bucket/big.bin',
        key,
        query: {'partNumber': '1', 'uploadId': uploadId},
        body: utf8.encode('only part'),
      );
      expect(part.statusCode, 200, reason: part.body);
      final etag = part.headers['etag']!;

      final completed = await signed(
        'POST',
        '/$bucket/big.bin',
        key,
        query: {'uploadId': uploadId},
        body: utf8.encode(
          '<CompleteMultipartUpload><Part><PartNumber>1</PartNumber>'
          '<ETag>$etag</ETag></Part></CompleteMultipartUpload>',
        ),
      );
      expect(completed.statusCode, 200, reason: completed.body);

      final download = await http.get(
        server.url('/$bucket/big.bin'),
        headers: server.auth(),
      );
      expect(download.body, 'only part');

      final second = await signed(
        'POST',
        '/$bucket/aborted.bin',
        key,
        query: {'uploads': ''},
      );
      final secondId = RegExp('<UploadId>(.*)</UploadId>')
          .firstMatch(second.body)!
          .group(1)!;
      final abort = await signed(
        'DELETE',
        '/$bucket/aborted.bin',
        key,
        query: {'uploadId': secondId},
      );
      expect(abort.statusCode, 204, reason: abort.body);
    });

    test('A read-only key cannot upload parts to an upload', () async {
      const bucket = 'pm-multipart-ro';
      await server.createBucket(bucket);
      final reader = await keyOn(bucket, 'readOnly');
      final writer = await keyOn(bucket, 'readWrite');

      final created = await signed(
        'POST',
        '/$bucket/x.bin',
        writer,
        query: {'uploads': ''},
      );
      final uploadId = RegExp('<UploadId>(.*)</UploadId>')
          .firstMatch(created.body)!
          .group(1)!;

      final part = await signed(
        'PUT',
        '/$bucket/x.bin',
        reader,
        query: {'partNumber': '1', 'uploadId': uploadId},
        body: utf8.encode('nope'),
      );
      expect(part.statusCode, 403);
      final abort = await signed(
        'DELETE',
        '/$bucket/x.bin',
        reader,
        query: {'uploadId': uploadId},
      );
      expect(abort.statusCode, 403);
    });

    test('UploadPartCopy needs read access to the source bucket', () async {
      const bucket = 'pm-part-copy';
      await server.createBucket(bucket);
      final key = await keyOn(bucket, 'readWrite');

      final created = await signed(
        'POST',
        '/$bucket/copy.bin',
        key,
        query: {'uploads': ''},
      );
      final uploadId = RegExp('<UploadId>(.*)</UploadId>')
          .firstMatch(created.body)!
          .group(1)!;

      final response = await signed(
        'PUT',
        '/$bucket/copy.bin',
        key,
        query: {'partNumber': '1', 'uploadId': uploadId},
        headers: {'x-amz-copy-source': '/$other/seed.txt'},
      );
      expect(response.statusCode, 403);
      expect(response.body, contains('AccessDenied'));
    });
  });

  group('Access keys - presigned URLs', () {
    const bucket = 'pm-presign';

    setUpAll(() => server.putObject(bucket, 'doc.txt', 'presigned'));

    test('A URL signed with a read key downloads the object', () async {
      final key = await keyOn(bucket, 'readOnly');
      final response = await http.get(presigned(key, bucket, 'doc.txt'));
      expect(response.statusCode, 200, reason: response.body);
      expect(response.body, 'presigned');
    });

    test('A URL for a bucket outside the key answers 403', () async {
      final key = await keyOn(bucket, 'readOnly');
      final response = await http.get(presigned(key, other, 'seed.txt'));
      expect(response.statusCode, 403);
    });

    test('A URL signed with a write-only key answers 403', () async {
      final key = await keyOn(bucket, 'writeOnly');
      final response = await http.get(presigned(key, bucket, 'doc.txt'));
      expect(response.statusCode, 403);
    });

    test('A URL stops working when its key is disabled', () async {
      final key = await keyOn(bucket, 'readOnly');
      final url = presigned(key, bucket, 'doc.txt');
      expect((await http.get(url)).statusCode, 200);

      final update = await updateKey(key['access_key_id'], {
        'name': key['name'],
        'enabled': false,
        'buckets': key['buckets'],
      });
      expect(update.statusCode, 200);

      final response = await http.get(url);
      expect(response.statusCode, 403);
      expect(response.body, contains('InvalidAccessKeyId'));
    });

    test('A read key may override the response headers', () async {
      final key = await keyOn(bucket, 'readOnly');
      final response = await signed(
        'GET',
        '/$bucket/doc.txt',
        key,
        query: {'response-content-type': 'text/x-test'},
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'text/x-test');
    });
  });

  group('Access keys - changes take effect at once', () {
    test('Changing the level applies to the next request', () async {
      const bucket = 'pm-change';
      await server.putObject(bucket, 'seed.txt', 'seed');
      final key = await keyOn(bucket, 'readOnly');
      expect((await signed('GET', '/$bucket/seed.txt', key)).statusCode, 200);

      final update = await updateKey(key['access_key_id'], {
        'name': key['name'],
        'buckets': [
          {'bucket': bucket, 'access': 'writeOnly'},
        ],
      });
      expect(update.statusCode, 200);

      expect((await signed('GET', '/$bucket/seed.txt', key)).statusCode, 403);
      final put = await signed(
        'PUT',
        '/$bucket/now.txt',
        key,
        body: utf8.encode('x'),
      );
      expect(put.statusCode, 200);
    });

    test(
      'Moving a key from some buckets to every bucket opens the rest',
      () async {
        const bucket = 'pm-widen';
        await server.createBucket(bucket);
        final key = await keyOn(bucket, 'readOnly');
        expect((await signed('GET', '/$other/seed.txt', key)).statusCode, 403);

        final update = await updateKey(key['access_key_id'], {
          'name': key['name'],
          'all_buckets': 'readOnly',
        });
        expect(update.statusCode, 200);
        expect((await signed('GET', '/$other/seed.txt', key)).statusCode, 200);
      },
    );

    test('A disabled key works again once enabled', () async {
      final key = await newKey({'name': 'Toggle', 'all_buckets': 'readOnly'});
      Future<int> get() async =>
          (await signed('GET', '/$other/seed.txt', key)).statusCode;

      Future<void> setEnabled(bool enabled) async {
        final response = await updateKey(key['access_key_id'], {
          'name': 'Toggle',
          'enabled': enabled,
          'all_buckets': 'readOnly',
        });
        expect(response.statusCode, 200);
        expect(jsonDecode(response.body)['enabled'], enabled);
      }

      await setEnabled(false);
      expect(await get(), 403);
      await setEnabled(true);
      expect(await get(), 200);
    });

    test('Updating without "enabled" keeps the current state', () async {
      final key = await newKey({'name': 'Keep', 'all_buckets': 'readOnly'});
      await updateKey(key['access_key_id'], {
        'name': 'Keep',
        'enabled': false,
        'all_buckets': 'readOnly',
      });
      final response = await updateKey(key['access_key_id'], {
        'name': 'Kept',
        'all_buckets': 'readOnly',
      });
      expect(jsonDecode(response.body)['enabled'], isFalse);
    });

    test(
      'An expired key can be renamed but not moved to another past date',
      () async {
        final key = await newKey({
          'name': 'Old',
          'all_buckets': 'readOnly',
          'expires_at': DateTime.now()
              .add(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
        });
        // Expire it without waiting
        final past = DateTime.now().subtract(const Duration(days: 1));
        final db = di.find<AppDatabase>();
        await (db.update(db.accessKeyTable)
              ..where((t) => t.id.equals(key['access_key_id'])))
            .write(AccessKeyTableCompanion(expiresAt: Value(past)));
        final stored = await listedKey(key['access_key_id']);
        expect(stored['expired'], isTrue);
        expect((await signed('GET', '/$other/seed.txt', key)).statusCode, 403);

        final rename = await updateKey(key['access_key_id'], {
          'name': 'Old renamed',
          'all_buckets': 'readOnly',
          'expires_at': stored['expires_at'],
        });
        expect(rename.statusCode, 200, reason: rename.body);

        final otherPast = await updateKey(key['access_key_id'], {
          'name': 'Old renamed',
          'all_buckets': 'readOnly',
          'expires_at': '2020-01-01T00:00:00Z',
        });
        expect(otherPast.statusCode, 422);

        final extended = await updateKey(key['access_key_id'], {
          'name': 'Old renamed',
          'all_buckets': 'readOnly',
          'expires_at': null,
        });
        expect(extended.statusCode, 200);
        expect((await signed('GET', '/$other/seed.txt', key)).statusCode, 200);
      },
    );
  });

  group('Access keys - edge cases', () {
    test('Every admin endpoint requires the JWT (401)', () async {
      final requests = [
        http.get(server.url(keysPath())),
        http.post(server.url(keysPath()), body: '{}'),
        http.put(server.url(keysPath('/FIOKX')), body: '{}'),
        http.post(server.url(keysPath('/FIOKX/secret'))),
        http.delete(server.url(keysPath('/FIOKX'))),
      ];
      for (final response in await Future.wait(requests)) {
        expect(response.statusCode, 401, reason: response.request?.url.path);
      }
    });

    test('Regenerating or deleting an unknown key answers 404', () async {
      final regenerate = await http.post(
        server.url(keysPath('/FIOKNOPE/secret')),
        headers: server.auth(),
      );
      expect(regenerate.statusCode, 404);
      final delete = await http.delete(
        server.url(keysPath('/FIOKNOPE')),
        headers: server.auth(),
      );
      expect(delete.statusCode, 404);
    });

    test('An update is validated like a create (422)', () async {
      final key = await newKey({'name': 'Valid', 'all_buckets': 'readOnly'});
      final noScope = await updateKey(key['access_key_id'], {'name': 'x'});
      expect(noScope.statusCode, 422);
      final noName = await updateKey(key['access_key_id'], {
        'all_buckets': 'readOnly',
      });
      expect(noName.statusCode, 422);
      final blankName = await updateKey(key['access_key_id'], {
        'name': '   ',
        'all_buckets': 'readOnly',
      });
      expect(blankName.statusCode, 422);
    });

    test('A bucket name that is not valid is rejected (422)', () async {
      final response = await http.post(
        server.url(keysPath()),
        headers: jsonAuth(),
        body: jsonEncode({
          'name': 'Bad bucket',
          'buckets': [
            {'bucket': '../etc', 'access': 'readOnly'},
          ],
        }),
      );
      expect(response.statusCode, 422);
    });

    test('The name is trimmed and the buckets come sorted', () async {
      await server.createBucket('pm-b');
      await server.createBucket('pm-a');
      final key = await newKey({
        'name': '  Sorted  ',
        'buckets': [
          {'bucket': 'pm-b', 'access': 'readOnly'},
          {'bucket': 'pm-a', 'access': 'writeOnly'},
        ],
      });
      expect(key['name'], 'Sorted');
      expect((key['buckets'] as List).map((g) => g['bucket']), [
        'pm-a',
        'pm-b',
      ]);
    });

    test('Every key gets its own id and secret', () async {
      final a = await newKey({'name': 'A', 'all_buckets': 'readOnly'});
      final b = await newKey({'name': 'B', 'all_buckets': 'readOnly'});
      expect(a['access_key_id'], isNot(b['access_key_id']));
      expect(a['secret_access_key'], isNot(b['secret_access_key']));
      // A key's id with another key's secret does not sign
      final mixed = {...a, 'secret_access_key': b['secret_access_key']};
      final response = await signed('GET', '/$other/seed.txt', mixed);
      expect(response.statusCode, 403);
      expect(response.body, contains('SignatureDoesNotMatch'));
    });

    test('An unknown access key id answers InvalidAccessKeyId', () async {
      final response = await signed('GET', '/$other/seed.txt', {
        'access_key_id': 'FIOKDOESNOTEXIST0000',
        'secret_access_key': 'x' * 40,
      });
      expect(response.statusCode, 403);
      expect(response.body, contains('InvalidAccessKeyId'));
    });

    test(
      'A tampered secret in the database denies access, not a 500',
      () async {
        final key = await newKey({
          'name': 'Tampered',
          'all_buckets': 'readOnly',
        });
        final db = di.find<AppDatabase>();
        await (db.update(
          db.accessKeyTable,
        )..where((t) => t.id.equals(key['access_key_id']))).write(
          const AccessKeyTableCompanion(
            secretEncrypted: Value('bm90IGEgcmVhbCBzZWNyZXQgYXQgYWxsIQ=='),
          ),
        );
        final response = await signed('GET', '/$other/seed.txt', key);
        expect(response.statusCode, 403);
        expect(response.body, contains('AccessDenied'));
      },
    );

    test(
      'A key keeps no access to a bucket deleted and created again',
      () async {
        const bucket = 'pm-recreated';
        await server.createBucket(bucket);
        final key = await keyOn(bucket, 'readWrite');
        expect((await signed('GET', '/$bucket', key)).statusCode, 200);

        final delete = await http.delete(
          server.url('/$bucket'),
          headers: server.auth(),
        );
        expect(delete.statusCode, 204);
        await server.createBucket(bucket);

        expect((await signed('GET', '/$bucket', key)).statusCode, 403);
        expect((await listedKey(key['access_key_id']))['buckets'], isEmpty);
      },
    );

    test('A managed key cannot log in to the console', () async {
      final key = await newKey({
        'name': 'No console',
        'all_buckets': 'readWrite',
      });
      final response = await http.post(
        server.url('/${env.adminPrefix}/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'access': key['access_key_id'],
          'secret': key['secret_access_key'],
        }),
      );
      expect(response.statusCode, 403);
    });

    test('The root key still reaches everything with SigV4', () async {
      await newKey({'name': 'Irrelevant', 'all_buckets': 'readOnly'});
      final bucket = unique('pm-root');
      final create = await http.put(
        server.url('/$bucket'),
        headers: server.sigV4('PUT', '/$bucket'),
      );
      expect(create.statusCode, 200);
      final list = await http.get(
        server.url('/'),
        headers: server.sigV4('GET', '/'),
      );
      expect(list.body, contains('<Name>$bucket</Name>'));
      expect(list.body, contains('<Name>$other</Name>'));
    });

    test('last_used_at is written at most once a minute', () async {
      final key = await newKey({'name': 'Busy', 'all_buckets': 'readOnly'});
      await signed('GET', '/$other/seed.txt', key);
      final first = (await listedKey(key['access_key_id']))['last_used_at'];
      expect(first, isNotNull);
      await Future.delayed(const Duration(milliseconds: 1100));
      await signed('GET', '/$other/seed.txt', key);
      final second = (await listedKey(key['access_key_id']))['last_used_at'];
      expect(second, first);
    });
  });

  group('Access keys - anonymous rules also apply (as in AWS)', () {
    // A bucket no key below has a grant for, with a public read prefix and a
    // public drop box
    const bucket = 'pm-public';
    late Map<String, dynamic> stranger;

    setUpAll(() async {
      await server.putObject(bucket, 'public/a.txt', 'public');
      await server.putObject(bucket, 'private/b.txt', 'private');
      for (final (prefix, access) in [
        ('public/', 'readOnly'),
        ('inbox/', 'writeOnly'),
      ]) {
        final rule = await http.post(
          server.url('/${env.adminPrefix}/bucket/$bucket/anonymous-access'),
          headers: jsonAuth(),
          body: jsonEncode({'prefix': prefix, 'access': access}),
        );
        expect(rule.statusCode, 200);
      }
      stranger = await keyOn(other, 'readOnly');
    });

    test('A key without a grant reads a public prefix', () async {
      final get = await signed('GET', '/$bucket/public/a.txt', stranger);
      expect(get.statusCode, 200, reason: get.body);
      expect(get.body, 'public');
      final head = await signed('HEAD', '/$bucket/public/a.txt', stranger);
      expect(head.statusCode, 200);
    });

    test('... but nothing outside it', () async {
      final get = await signed('GET', '/$bucket/private/b.txt', stranger);
      expect(get.statusCode, 403);
      final put = await signed(
        'PUT',
        '/$bucket/public/new.txt',
        stranger,
        body: utf8.encode('x'),
      );
      expect(put.statusCode, 403);
    });

    test('It lists the public prefix but not the whole bucket', () async {
      final prefixed = await signed(
        'GET',
        '/$bucket',
        stranger,
        query: {'list-type': '2', 'prefix': 'public/'},
      );
      expect(prefixed.statusCode, 200, reason: prefixed.body);
      expect(prefixed.body, contains('<Key>public/a.txt</Key>'));
      expect(prefixed.body, isNot(contains('private/b.txt')));

      final whole = await signed(
        'GET',
        '/$bucket',
        stranger,
        query: {'list-type': '2'},
      );
      expect(whole.statusCode, 403);
    });

    test(
      'It drops files in a public write prefix without reading them',
      () async {
        final put = await signed(
          'PUT',
          '/$bucket/inbox/form.txt',
          stranger,
          body: utf8.encode('form'),
        );
        expect(put.statusCode, 200, reason: put.body);
        final get = await signed('GET', '/$bucket/inbox/form.txt', stranger);
        expect(get.statusCode, 403);
      },
    );

    test('The rule adds to the key own grant on that bucket', () async {
      final reader = await keyOn(bucket, 'readOnly');
      expect(
        (await signed('GET', '/$bucket/private/b.txt', reader)).statusCode,
        200,
      );
      final dropped = await signed(
        'PUT',
        '/$bucket/inbox/reader.txt',
        reader,
        body: utf8.encode('x'),
      );
      expect(dropped.statusCode, 200, reason: dropped.body);
      final elsewhere = await signed(
        'PUT',
        '/$bucket/private/reader.txt',
        reader,
        body: utf8.encode('x'),
      );
      expect(elsewhere.statusCode, 403);
    });

    test('The public bucket does not show up in its ListBuckets', () async {
      final response = await signed('GET', '/', stranger);
      expect(response.body, isNot(contains('<Name>$bucket</Name>')));
    });

    test('A signed request may override headers on a public object', () async {
      final response = await signed(
        'GET',
        '/$bucket/public/a.txt',
        stranger,
        query: {'response-content-type': 'text/x-public'},
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'text/x-public');
    });

    test('It copies from a public prefix into a bucket it can write', () async {
      final writer = await keyOn(other, 'readWrite');
      final allowed = await signed(
        'PUT',
        '/$other/copied-public.txt',
        writer,
        headers: {'x-amz-copy-source': '/$bucket/public/a.txt'},
      );
      expect(allowed.statusCode, 200, reason: allowed.body);

      final denied = await signed(
        'PUT',
        '/$other/copied-private.txt',
        writer,
        headers: {'x-amz-copy-source': '/$bucket/private/b.txt'},
      );
      expect(denied.statusCode, 403);
      expect(denied.body, contains('AccessDenied'));

      final dropBox = await signed(
        'PUT',
        '/$other/copied-inbox.txt',
        writer,
        headers: {'x-amz-copy-source': '/$bucket/inbox/form.txt'},
      );
      expect(dropBox.statusCode, 403);
    });

    test('Multipart and multi-delete stay closed in a public prefix', () async {
      final created = await signed(
        'POST',
        '/$bucket/inbox/big.bin',
        stranger,
        query: {'uploads': ''},
      );
      expect(created.statusCode, 403);

      final multiDelete = await signed(
        'POST',
        '/$bucket',
        stranger,
        query: {'delete': ''},
        body: utf8.encode(deleteXml(['inbox/form.txt'])),
      );
      expect(multiDelete.statusCode, 403);
    });

    test('A bad signature is rejected even on a public prefix', () async {
      final response = await signed('GET', '/$bucket/public/a.txt', {
        ...stranger,
        'secret_access_key': 'x' * 40,
      });
      expect(response.statusCode, 403);
      expect(response.body, contains('SignatureDoesNotMatch'));
    });

    test('A disabled key is rejected even on a public prefix', () async {
      final key = await keyOn(other, 'readOnly');
      final update = await updateKey(key['access_key_id'], {
        'name': key['name'],
        'enabled': false,
        'buckets': key['buckets'],
      });
      expect(update.statusCode, 200);
      final response = await signed('GET', '/$bucket/public/a.txt', key);
      expect(response.statusCode, 403);
      expect(response.body, contains('InvalidAccessKeyId'));
    });
  });
}
