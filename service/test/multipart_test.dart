@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:service/feather.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

void main() {
  final server = TestServer(port: 8101, name: 'multipart');
  const bucket = 'mp-bucket';
  const mb = 1024 * 1024;

  final part1 = List<int>.filled(5 * mb, 1);
  final part2 = List<int>.filled(1234, 2);

  setUpAll(() async {
    await server.start();
    await server.putObject(bucket, 'other.txt', 'x');
  });
  tearDownAll(server.stop);

  String? xmlTag(String xml, String name) =>
      RegExp('<$name>(.*?)</$name>', dotAll: true).firstMatch(xml)?.group(1);

  Future<http.Response> create(String key, {bool json = false}) => http.post(
    server.url('/$bucket/$key?uploads'),
    headers: server.auth(json: json),
  );

  Future<String> createId(String key) async {
    final response = await create(key, json: true);
    expect(response.statusCode, 200, reason: response.body);
    return jsonDecode(response.body)['upload_id'] as String;
  }

  Future<http.Response> uploadPart(
    String key,
    String uploadId,
    int number,
    List<int> body, {
    Map<String, String> extra = const {},
  }) => http.put(
    server.url('/$bucket/$key?partNumber=$number&uploadId=$uploadId'),
    headers: {...server.auth(), ...extra},
    body: body,
  );

  Future<http.Response> completeXml(
    String key,
    String uploadId,
    List<(int, String)> parts,
  ) {
    final xml = StringBuffer('<CompleteMultipartUpload>');
    for (final (number, etag) in parts) {
      xml.write(
        '<Part><PartNumber>$number</PartNumber><ETag>$etag</ETag></Part>',
      );
    }
    xml.write('</CompleteMultipartUpload>');
    return http.post(
      server.url('/$bucket/$key?uploadId=$uploadId'),
      headers: {...server.auth(), 'content-type': 'application/xml'},
      body: xml.toString(),
    );
  }

  Future<http.Response> completeJson(
    String key,
    String uploadId,
    List<(int, String)> parts,
  ) => http.post(
    server.url('/$bucket/$key?uploadId=$uploadId'),
    headers: {...server.auth(json: true), 'content-type': 'application/json'},
    body: jsonEncode({
      'parts': [
        for (final (number, etag) in parts)
          {'part_number': number, 'etag': etag},
      ],
    }),
  );

  /// Uploads the two test parts and returns their ETags.
  Future<List<String>> uploadBoth(String key, String uploadId) async {
    final etags = <String>[];
    for (final (number, body) in [(1, part1), (2, part2)]) {
      final response = await uploadPart(key, uploadId, number, body);
      expect(response.statusCode, 200, reason: response.body);
      etags.add(response.headers['etag']!);
    }
    return etags;
  }

  group('S3Controller - multipart upload', () {
    test('Should create, upload parts and complete (XML)', () async {
      const key = 'videos/big.bin';
      final created = await create(key);
      expect(created.statusCode, 200);
      expect(created.headers['content-type'], contains('application/xml'));
      expect(xmlTag(created.body, 'Bucket'), bucket);
      expect(xmlTag(created.body, 'Key'), key);
      final uploadId = xmlTag(created.body, 'UploadId')!;
      expect(uploadId, matches(RegExp(r'^[0-9a-f]{32}$')));

      final etags = await uploadBoth(key, uploadId);
      expect(etags[0], '"${md5.convert(part1)}"');

      final completed = await completeXml(key, uploadId, [
        (1, etags[0].replaceAll('"', '&quot;')),
        (2, etags[1]),
      ]);
      expect(completed.statusCode, 200, reason: completed.body);
      final expectedEtag =
          '${md5.convert([...md5.convert(part1).bytes, ...md5.convert(part2).bytes])}-2';
      expect(xmlTag(completed.body, 'ETag'), '&quot;$expectedEtag&quot;');
      expect(xmlTag(completed.body, 'Key'), key);

      final object = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(object.statusCode, 200);
      expect(object.bodyBytes.length, part1.length + part2.length);
      expect(object.bodyBytes.last, 2);
      expect(object.headers['etag'], '"$expectedEtag"');

      // The upload no longer exists
      final again = await uploadPart(key, uploadId, 3, [1]);
      expect(again.statusCode, 404);
      expect(again.body, contains('<Code>NoSuchUpload</Code>'));
    });

    test('Should create and complete with JSON (console)', () async {
      const key = 'consola.bin';
      final uploadId = await createId(key);
      final etags = await uploadBoth(key, uploadId);
      final completed = await completeJson(key, uploadId, [
        (1, etags[0]),
        (2, etags[1]),
      ]);
      expect(completed.statusCode, 200, reason: completed.body);
      final body = jsonDecode(completed.body);
      expect(body['key'], key);
      expect(body['size_bytes'], part1.length + part2.length);
      expect(body['etag'], endsWith('-2'));
    });

    test('Should use the last upload of a repeated part', () async {
      const key = 'repetida.bin';
      final uploadId = await createId(key);
      await uploadPart(key, uploadId, 1, List<int>.filled(5 * mb, 9));
      final etags = await uploadBoth(key, uploadId);
      final completed = await completeJson(key, uploadId, [
        (1, etags[0]),
        (2, etags[1]),
      ]);
      expect(completed.statusCode, 200);
      final object = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(object.bodyBytes.first, 1);
    });

    test('Should allow a single small part', () async {
      const key = 'pequena.txt';
      final uploadId = await createId(key);
      final part = await uploadPart(key, uploadId, 1, utf8.encode('hello'));
      final completed = await completeJson(key, uploadId, [
        (1, part.headers['etag']!),
      ]);
      expect(completed.statusCode, 200);
      final object = await http.get(
        server.url('/$bucket/$key'),
        headers: server.auth(),
      );
      expect(object.body, 'hello');
    });

    test('Should abort and remove the parts', () async {
      const key = 'abortada.bin';
      final uploadId = await createId(key);
      await uploadPart(key, uploadId, 1, part2);
      final dir = Directory(
        '${server.storagePath}/${MultipartService.folderName}/$uploadId',
      );
      expect(dir.existsSync(), isTrue);

      final aborted = await http.delete(
        server.url('/$bucket/$key?uploadId=$uploadId'),
        headers: server.auth(),
      );
      expect(aborted.statusCode, 204);
      expect(dir.existsSync(), isFalse);

      final part = await uploadPart(key, uploadId, 2, part2);
      expect(part.statusCode, 404);
    });

    test('Should not list the pending uploads as a bucket', () async {
      await createId('pendiente.bin');
      final response = await http.get(
        server.url('/'),
        headers: server.auth(json: true),
      );
      final names = [
        for (final b in jsonDecode(response.body) as List) b['name'],
      ];
      expect(names, isNot(contains(MultipartService.folderName)));
    });

    test('Should expose the ETag header to the browser (CORS)', () async {
      const key = 'cors.bin';
      final uploadId = await createId(key);
      final response = await uploadPart(
        key,
        uploadId,
        1,
        part2,
        extra: {'origin': 'http://localhost:8081'},
      );
      expect(
        response.headers['access-control-expose-headers']?.toLowerCase(),
        contains('etag'),
      );
    });
  });

  group('S3Controller - multipart errors', () {
    test('Should reject a small part that is not the last one', () async {
      const key = 'corta.bin';
      final uploadId = await createId(key);
      final a = await uploadPart(key, uploadId, 1, part2);
      final b = await uploadPart(key, uploadId, 2, part2);
      final completed = await completeXml(key, uploadId, [
        (1, a.headers['etag']!),
        (2, b.headers['etag']!),
      ]);
      expect(completed.statusCode, 400);
      expect(completed.body, contains('<Code>EntityTooSmall</Code>'));
    });

    test('Should reject parts out of order', () async {
      const key = 'desordenada.bin';
      final uploadId = await createId(key);
      final etags = await uploadBoth(key, uploadId);
      final completed = await completeXml(key, uploadId, [
        (2, etags[1]),
        (1, etags[0]),
      ]);
      expect(completed.statusCode, 400);
      expect(completed.body, contains('<Code>InvalidPartOrder</Code>'));
    });

    test('Should reject a missing part or a wrong ETag', () async {
      const key = 'incompleta.bin';
      final uploadId = await createId(key);
      final etags = await uploadBoth(key, uploadId);

      final missing = await completeXml(key, uploadId, [
        (1, etags[0]),
        (3, etags[1]),
      ]);
      expect(missing.statusCode, 400);
      expect(missing.body, contains('<Code>InvalidPart</Code>'));

      final wrong = await completeXml(key, uploadId, [
        (1, etags[1]),
        (2, etags[1]),
      ]);
      expect(wrong.statusCode, 400);
      expect(wrong.body, contains('<Code>InvalidPart</Code>'));
    });

    test('Should reject a malformed part list', () async {
      const key = 'bad.bin';
      final uploadId = await createId(key);
      final response = await http.post(
        server.url('/$bucket/$key?uploadId=$uploadId'),
        headers: {...server.auth(), 'content-type': 'application/xml'},
        body: '<CompleteMultipartUpload></CompleteMultipartUpload>',
      );
      expect(response.statusCode, 400);
      expect(response.body, contains('<Code>MalformedXML</Code>'));
    });

    test('Should answer NoSuchUpload for unknown or foreign ids', () async {
      final uploadId = await createId('propia.bin');

      for (final (key, id) in [
        ('propia.bin', '0' * 32),
        ('propia.bin', '..%2F..%2Fotro'),
        ('ajena.bin', uploadId),
      ]) {
        final response = await uploadPart(key, id, 1, part2);
        expect(response.statusCode, 404, reason: '$key $id');
        expect(response.body, contains('<Code>NoSuchUpload</Code>'));
      }
    });

    test('Should reject an invalid part number', () async {
      const key = 'numero.bin';
      final uploadId = await createId(key);
      for (final number in [0, 10001]) {
        final response = await uploadPart(key, uploadId, number, part2);
        expect(response.statusCode, 400, reason: '$number');
        expect(response.body, contains('<Code>InvalidArgument</Code>'));
      }
    });

    test('Should fail on a missing bucket or a folder key', () async {
      final noBucket = await http.post(
        server.url('/no-existe/a.bin?uploads'),
        headers: server.auth(),
      );
      expect(noBucket.statusCode, 404);
      expect(noBucket.body, contains('<Code>NoSuchBucket</Code>'));

      final folder = await create('folder/');
      expect(folder.statusCode, 400);
    });

    test(
      'Should reject POST on an object without ?uploads/?uploadId',
      () async {
        final response = await http.post(
          server.url('/$bucket/other.txt'),
          headers: server.auth(),
        );
        expect(response.statusCode, 400);
        expect(response.body, contains('<Code>InvalidRequest</Code>'));
      },
    );

    test('Should fail without auth (401)', () async {
      final response = await http.post(server.url('/$bucket/a.bin?uploads'));
      expect(response.statusCode, 401);
    });
  });

  group('S3Controller - multipart with SigV4', () {
    test('Should create an upload signed with the service keys', () async {
      final response = await http.post(
        server.url('/$bucket/signed.bin?uploads'),
        headers: server.sigV4(
          'POST',
          '/$bucket/signed.bin',
          query: const {'uploads': ''},
        ),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(xmlTag(response.body, 'UploadId'), isNotNull);
    });
  });

  group('BucketService - multipart cleanup', () {
    test('Should abort the pending uploads when a bucket is deleted', () async {
      const other = 'mp-temp';
      final created = await http.put(
        server.url('/$other'),
        headers: server.auth(),
      );
      expect(created.statusCode, 200);
      final start = await http.post(
        server.url('/$other/a.bin?uploads'),
        headers: server.auth(json: true),
      );
      final uploadId = jsonDecode(start.body)['upload_id'] as String;

      final deleted = await http.delete(
        server.url('/$other'),
        headers: server.auth(),
      );
      expect(deleted.statusCode, 204);
      expect(
        Directory(
          '${server.storagePath}/${MultipartService.folderName}/$uploadId',
        ).existsSync(),
        isFalse,
      );
    });
  });

  group('S3Controller - ListMultipartUploads (GET ?uploads)', () {
    const listBucket = 'mp-list';

    setUpAll(() => server.createBucket(listBucket));

    Future<String> start(String key) async {
      final created = await http.post(
        server.url('/$listBucket/$key?uploads'),
        headers: server.auth(json: true),
      );
      return jsonDecode(created.body)['upload_id'] as String;
    }

    test('Should list the pending uploads of the bucket in XML', () async {
      final first = await start('b/one.bin');
      final second = await start('a/two.bin');

      final response = await http.get(
        server.url('/$listBucket?uploads'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(response.body, contains('<ListMultipartUploadsResult'));
      final keys = RegExp(r'<Key>(.*?)</Key>')
          .allMatches(response.body)
          .map((m) => m.group(1));
      expect(keys, ['a/two.bin', 'b/one.bin']);
      expect(response.body, contains('<UploadId>$first</UploadId>'));
      expect(response.body, contains('<UploadId>$second</UploadId>'));
      expect(response.body, contains('<Initiated>'));
    });

    test('Should filter by prefix and answer JSON', () async {
      final response = await http.get(
        server.url('/$listBucket?uploads&prefix=a/'),
        headers: server.auth(json: true),
      );
      final uploads = jsonDecode(response.body) as List;
      expect(uploads.map((u) => u['key']), ['a/two.bin']);
    });

    test('Should not list the uploads of other buckets nor the finished ones', () async {
      final response = await http.get(
        server.url('/$bucket?uploads'),
        headers: server.auth(json: true),
      );
      final keys = (jsonDecode(response.body) as List).map((u) => u['key']);
      expect(keys, isNot(contains('b/one.bin')));
    });

    test('Should return 404 for a missing bucket', () async {
      final response = await http.get(
        server.url('/no-existe?uploads'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
    });
  });

  group('S3Controller - UploadPartCopy', () {
    const copyBucket = 'mp-copy';

    setUpAll(() => server.putObject(copyBucket, 'source.txt', 'abcdefghij'));

    Future<String> start(String key) async {
      final created = await http.post(
        server.url('/$copyBucket/$key?uploads'),
        headers: server.auth(json: true),
      );
      return jsonDecode(created.body)['upload_id'] as String;
    }

    Future<http.Response> copyPart(
      String key,
      String uploadId,
      int number, {
      String? range,
      Map<String, String> headers = const {},
    }) => http.put(
      server.url('/$copyBucket/$key?partNumber=$number&uploadId=$uploadId'),
      headers: {
        ...server.auth(),
        'x-amz-copy-source': '/$copyBucket/source.txt',
        'x-amz-copy-source-range': ?range,
        ...headers,
      },
    );

    test('Should copy a whole object as a part', () async {
      final uploadId = await start('whole.txt');
      final response = await copyPart('whole.txt', uploadId, 1);
      expect(response.statusCode, 200, reason: response.body);
      expect(response.body, contains('<CopyPartResult'));
      expect(
        response.body,
        contains('<ETag>&quot;${md5.convert(utf8.encode('abcdefghij'))}&quot;</ETag>'),
      );
    });

    test('Should copy ranges and complete the object with them', () async {
      const key = 'ranges.txt';
      final uploadId = await start(key);
      final first = await copyPart(key, uploadId, 1, range: 'bytes=0-2');
      final second = await copyPart(key, uploadId, 2, range: 'bytes=7-9');
      expect(first.statusCode, 200, reason: first.body);
      expect(second.statusCode, 200, reason: second.body);

      String etag(http.Response r) =>
          RegExp(r'<ETag>(.*?)</ETag>').firstMatch(r.body)!.group(1)!;
      // The first part is under 5 MiB: it is only valid as the single part,
      // so the upload is completed with the second one to check its content
      final completed = await http.post(
        server.url('/$copyBucket/$key?uploadId=$uploadId'),
        headers: server.auth(),
        body: '<CompleteMultipartUpload><Part><PartNumber>2</PartNumber>'
            '<ETag>${etag(second)}</ETag></Part></CompleteMultipartUpload>',
      );
      expect(completed.statusCode, 200, reason: completed.body);
      expect(
        await File('${server.storagePath}/$copyBucket/$key').readAsString(),
        'hij',
      );
    });

    test('Should reject a range outside the source (416)', () async {
      final uploadId = await start('outside.txt');
      final response = await copyPart('outside.txt', uploadId, 1, range: 'bytes=5-20');
      expect(response.statusCode, 416);
      expect(response.body, contains('<Code>InvalidRange</Code>'));
    });

    test('Should reject a malformed range (400)', () async {
      final uploadId = await start('bad.txt');
      final response = await copyPart('bad.txt', uploadId, 1, range: 'bytes=5-');
      expect(response.statusCode, 400);
    });

    test('Should check the copy conditions (412)', () async {
      final uploadId = await start('condition.txt');
      final response = await copyPart(
        'condition.txt',
        uploadId,
        1,
        headers: {'x-amz-copy-source-if-match': '"other-etag"'},
      );
      expect(response.statusCode, 412);
      expect(response.body, contains('<Code>PreconditionFailed</Code>'));
    });
  });

  group('S3Controller - ListParts (GET ?uploadId)', () {
    const partsBucket = 'mp-parts';

    setUpAll(() => server.createBucket(partsBucket));

    Future<String> startWithParts(String key, List<int> numbers) async {
      final created = await http.post(
        server.url('/$partsBucket/$key?uploads'),
        headers: server.auth(json: true),
      );
      final uploadId = jsonDecode(created.body)['upload_id'] as String;
      for (final number in numbers) {
        await http.put(
          server.url('/$partsBucket/$key?partNumber=$number&uploadId=$uploadId'),
          headers: server.auth(),
          body: List<int>.filled(number, number),
        );
      }
      return uploadId;
    }

    test('Should list the uploaded parts in order (XML)', () async {
      final uploadId = await startWithParts('parts.bin', [3, 1, 2]);
      final response = await http.get(
        server.url('/$partsBucket/parts.bin?uploadId=$uploadId'),
        headers: server.auth(),
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(response.body, contains('<ListPartsResult'));
      final numbers = RegExp(r'<PartNumber>(\d+)</PartNumber>')
          .allMatches(response.body)
          .map((m) => m.group(1));
      expect(numbers, ['1', '2', '3']);
      expect(response.body, contains('<Size>3</Size>'));
      expect(
        response.body,
        contains('<ETag>&quot;${md5.convert([1])}&quot;</ETag>'),
      );
      expect(response.body, contains('<IsTruncated>false</IsTruncated>'));
    });

    test('Should page with part-number-marker and max-parts (JSON)', () async {
      final uploadId = await startWithParts('paginas.bin', [1, 2, 3]);
      final response = await http.get(
        server.url(
          '/$partsBucket/paginas.bin?uploadId=$uploadId'
          '&part-number-marker=1&max-parts=1',
        ),
        headers: server.auth(json: true),
      );
      final parts = jsonDecode(response.body) as List;
      expect(parts.map((p) => p['part_number']), [2]);
    });

    test('Should answer NoSuchUpload for an unknown upload', () async {
      final response = await http.get(
        server.url('/$partsBucket/x.bin?uploadId=${'0' * 32}'),
        headers: server.auth(),
      );
      expect(response.statusCode, 404);
      expect(response.body, contains('<Code>NoSuchUpload</Code>'));
    });

    test('Should not let an anonymous reader list the parts (403)', () async {
      final uploadId = await startWithParts('anonymous.bin', [1]);
      final rule = await http.post(
        server.url('/_admin/bucket/$partsBucket/anonymous-access'),
        headers: {...server.auth(json: true), 'content-type': 'application/json'},
        body: jsonEncode({'prefix': '*', 'access': 'readOnly'}),
      );
      expect(rule.statusCode, anyOf(200, 201), reason: rule.body);

      final response = await http.get(
        server.url('/$partsBucket/anonymous.bin?uploadId=$uploadId'),
      );
      expect(response.statusCode, 403);
    });
  });
}
