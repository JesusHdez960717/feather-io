import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockClient extends Mock implements BrowserClient {}

void main() {
  late _MockClient client;
  late BrowserRepo repo;

  setUpAll(() => registerFallbackValue(Duration.zero));

  setUp(() {
    client = _MockClient();
    repo = BrowserRepo(client);
    when(
      () => client.deleteObjects(
        token: any(named: 'token'),
        bucket: any(named: 'bucket'),
        keys: any(named: 'keys'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => client.deleteFolder(
        token: any(named: 'token'),
        bucket: any(named: 'bucket'),
        prefix: any(named: 'prefix'),
      ),
    ).thenAnswer((_) async {});
  });

  test('Maps a listing page with its paging fields', () async {
    when(
      () => client.listObjects(
        token: any(named: 'token'),
        bucket: any(named: 'bucket'),
        prefix: any(named: 'prefix'),
        delimiter: any(named: 'delimiter'),
        maxKeys: any(named: 'maxKeys'),
        continuationToken: any(named: 'continuationToken'),
      ),
    ).thenAnswer(
      (_) async => ListObjectsResponse.fromJson({
        'name': 'media',
        'prefix': 'photos/',
        'delimiter': '/',
        'contents': [
          {
            'key': 'photos/a.jpg',
            'size_bytes': 10,
            'last_modified': '2026-10-01T10:00:00.000Z',
          },
        ],
        'common_prefixes': ['photos/2026/'],
        'is_truncated': true,
        'next_continuation_token': 't1',
        'total_keys': 120,
      }),
    );

    final page = await repo.listObjects(bucket: 'media', prefix: 'photos/');

    expect(page.objects.single.key, 'photos/a.jpg');
    expect(page.objects.single.sizeBytes, 10);
    expect(page.commonPrefixes, ['photos/2026/']);
    expect(page.isTruncated, isTrue);
    expect(page.nextContinuationToken, 't1');
    expect(page.totalKeys, 120);
  });

  test(
    'Objects go to the multi-delete, folders to the folder delete',
    () async {
      await repo.deleteObjects(
        bucket: 'media',
        keys: ['a.jpg', 'photos/', 'b.jpg', 'docs/'],
        token: 'jwt',
      );

      verify(
        () => client.deleteObjects(
          token: 'jwt',
          bucket: 'media',
          keys: ['a.jpg', 'b.jpg'],
        ),
      ).called(1);
      verify(
        () => client.deleteFolder(
          token: 'jwt',
          bucket: 'media',
          prefix: 'photos/',
        ),
      ).called(1);
      verify(
        () =>
            client.deleteFolder(token: 'jwt', bucket: 'media', prefix: 'docs/'),
      ).called(1);
    },
  );

  test('Only folders: no multi-delete', () async {
    await repo.deleteObjects(bucket: 'media', keys: ['photos/']);

    verifyNever(
      () => client.deleteObjects(
        token: any(named: 'token'),
        bucket: any(named: 'bucket'),
        keys: any(named: 'keys'),
      ),
    );
  });

  test('A shared link expires in local time', () async {
    when(
      () => client.presign(
        bucket: any(named: 'bucket'),
        key: any(named: 'key'),
        expiresIn: any(named: 'expiresIn'),
        token: any(named: 'token'),
      ),
    ).thenAnswer(
      (_) async => PresignResponse.fromJson({
        'url': 'http://localhost:8080/media/a.jpg?X-Amz-Signature=x',
        'expires_at': '2026-10-06T10:00:00.000Z',
      }),
    );

    final link = await repo.presign(
      bucket: 'media',
      key: 'a.jpg',
      expiresIn: const Duration(days: 1),
    );

    expect(link.expiresAt.isUtc, isFalse);
    expect(
      link.expiresAt.isAtSameMomentAs(DateTime.utc(2026, 10, 6, 10)),
      isTrue,
    );
  });

  test('An API error arrives with the service message', () async {
    when(
      () => client.createFolder(
        bucket: any(named: 'bucket'),
        key: any(named: 'key'),
        token: any(named: 'token'),
      ),
    ).thenThrow(
      httpError(404, {
        'code': 'NoSuchBucket',
        'message': 'The bucket "media" does not exist.',
      }),
    );

    await expectLater(
      () => repo.createFolder(bucket: 'media', key: 'photos/'),
      throwsA(
        isA<GlobalException>().having(
          (e) => e.message,
          'message',
          'The bucket "media" does not exist.',
        ),
      ),
    );
  });
}
