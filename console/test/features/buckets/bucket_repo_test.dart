import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockClient extends Mock implements BucketClient {}

void main() {
  late _MockClient client;
  late BucketRepo repo;

  setUpAll(() {
    registerFallbackValue(BucketCreateRequest());
    registerFallbackValue(BucketUpdateRequest());
  });

  setUp(() {
    client = _MockClient();
    repo = BucketRepo(client);
  });

  test('Maps the API buckets to models', () async {
    when(() => client.listBuckets(token: any(named: 'token'))).thenAnswer(
      (_) async => [
        BucketResponse.fromJson({
          'name': 'media',
          'description': 'Photos',
          'color': 0xFF2196F3,
          'object_count': 3,
          'size_bytes': 1024,
          'creation_date': '2026-10-01T10:00:00.000Z',
          'last_modified': null,
        }),
      ],
    );

    final media = (await repo.listBuckets(token: 'jwt')).single;

    expect(media.name, 'media');
    expect(media.description, 'Photos');
    expect(media.color, 0xFF2196F3);
    expect(media.objectCount, 3);
    expect(media.sizeBytes, 1024);
    expect(media.creationDate, DateTime.utc(2026, 10, 1, 10));
    expect(media.lastModified, isNull);
    verify(() => client.listBuckets(token: 'jwt'));
  });

  test('A new bucket sends only the metadata it has', () async {
    when(
      () => client.createBucket(
        name: any(named: 'name'),
        request: any(named: 'request'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});

    await repo.createBucket(name: 'media', description: 'Photos');

    final request =
        verify(
              () => client.createBucket(
                name: 'media',
                request: captureAny(named: 'request'),
                token: any(named: 'token'),
              ),
            ).captured.single
            as BucketCreateRequest;
    expect(request.toJson(), {'description': 'Photos'});
  });

  test('Editing sends every field, so a cleared one is deleted', () async {
    when(
      () => client.updateBucket(
        name: any(named: 'name'),
        request: any(named: 'request'),
        token: any(named: 'token'),
      ),
    ).thenAnswer(
      (_) async => BucketResponse.fromJson({
        'name': 'media',
        'object_count': 0,
        'size_bytes': 0,
        'creation_date': '2026-10-01T10:00:00.000Z',
      }),
    );

    final updated = await repo.updateBucket(name: 'media', color: 1);

    expect(updated.name, 'media');
    final request =
        verify(
              () => client.updateBucket(
                name: 'media',
                request: captureAny(named: 'request'),
                token: any(named: 'token'),
              ),
            ).captured.single
            as BucketUpdateRequest;
    expect(request.toJson(), {'description': null, 'color': 1});
  });

  test('An API error arrives with the service message', () async {
    when(
      () => client.deleteBucket(
        name: any(named: 'name'),
        token: any(named: 'token'),
      ),
    ).thenThrow(
      httpError(409, {
        'code': 'BucketNotEmpty',
        'detail': 'The bucket "media" is not empty and cannot be deleted.',
      }),
    );

    await expectLater(
      () => repo.deleteBucket(name: 'media'),
      throwsA(
        isA<GlobalException>()
            .having((e) => e.type, 'type', GlobalExceptionType.conflict)
            .having((e) => e.message, 'message', contains('is not empty')),
      ),
    );
  });
}
