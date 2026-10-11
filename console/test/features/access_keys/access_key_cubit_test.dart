import 'package:bloc_test/bloc_test.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements AccessKeyRepo {}

class _MockAuth extends Mock implements AuthCubit {}

void main() {
  late _MockRepo repo;
  late _MockAuth auth;

  final reader = accessKey(
    id: 'FIOKREADER',
    name: 'Web CDN',
    grants: [grant('media', AccessKeyLevel.readOnly)],
  );
  final backups = accessKey(
    id: 'FIOKBACKUP',
    name: 'Backups NAS',
    grants: [grant('backups', AccessKeyLevel.readWrite)],
  );
  final list = AccessKeyListModel(
    rootAccessKeyId: 'root',
    keys: [reader, backups],
  );

  setUpAll(() {
    registerFallbackValue(AccessKeyDraft.of(reader));
  });

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    when(() => auth.auth)
        .thenReturn(AuthModel(accessToken: 'jwt', expireAt: DateTime(2100)));
    when(() => repo.listKeys(token: any(named: 'token')))
        .thenAnswer((_) async => list);
  });

  AccessKeyCubit build() => AccessKeyCubit(repo, auth);

  List<String> visible(AccessKeyState state) =>
      state.data.visibleKeys.map((k) => k.name).toList();

  group('load', () {
    blocTest<AccessKeyCubit, AccessKeyState>(
      'Loads the keys with the JWT of the session',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AccessKeyLoadingInProgressState>(),
        isA<AccessKeyLoadingSuccessState>()
            .having((s) => s.data.loaded, 'loaded', isTrue)
            .having((s) => s.data.rootAccessKeyId, 'root', 'root')
            .having(visible, 'visible', ['Web CDN', 'Backups NAS']),
      ],
      verify: (_) => verify(() => repo.listKeys(token: 'jwt')).called(1),
    );

    blocTest<AccessKeyCubit, AccessKeyState>(
      'A failure keeps what was loaded and carries the error',
      build: build,
      setUp: () =>
          when(() => repo.listKeys(token: any(named: 'token')))
              .thenThrow(apiError('down')),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AccessKeyLoadingInProgressState>(),
        isA<AccessKeyLoadingErrorState>()
            .having((s) => s.exception.message, 'message', 'down')
            .having((s) => s.data.loaded, 'loaded', isFalse),
      ],
    );
  });

  group('search and filters', () {
    blocTest<AccessKeyCubit, AccessKeyState>(
      'Search matches the name or the id, ignoring case',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.search('backups');
        cubit.search('fiokreader');
        cubit.search('');
      },
      skip: 2,
      expect: () => [
        isA<AccessKeyState>().having(visible, 'by name', ['Backups NAS']),
        isA<AccessKeyState>().having(visible, 'by id', ['Web CDN']),
        isA<AccessKeyState>().having(visible, 'cleared', [
          'Web CDN',
          'Backups NAS',
        ]),
      ],
    );

    blocTest<AccessKeyCubit, AccessKeyState>(
      'Filters combine with the search and survive a reload',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.applyFilter(const AccessKeyFilter(buckets: {'backups'}));
        cubit.search('web');
        await cubit.load();
      },
      skip: 2,
      expect: () => [
        isA<AccessKeyState>().having(visible, 'filtered', ['Backups NAS']),
        isA<AccessKeyState>().having(visible, 'filtered + search', isEmpty),
        isA<AccessKeyLoadingInProgressState>(),
        isA<AccessKeyLoadingSuccessState>()
            .having((s) => s.data.filter.buckets, 'filter kept', {'backups'})
            .having((s) => s.data.query, 'query kept', 'web')
            .having(visible, 'visible', isEmpty),
      ],
    );
  });

  group('row actions', () {
    blocTest<AccessKeyCubit, AccessKeyState>(
      'Disabling sends the same key with enabled false, then reloads',
      build: build,
      setUp: () => when(
        () => repo.updateKey(
          id: any(named: 'id'),
          draft: any(named: 'draft'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => reader),
      act: (cubit) => cubit.setEnabled(reader, enabled: false),
      expect: () => [
        isA<AccessKeyProcessInProgressState>(),
        isA<AccessKeyProcessingOKState>().having(
          (s) => s.action,
          'action',
          AccessKeyAction.disabled,
        ),
        isA<AccessKeyLoadingInProgressState>(),
        isA<AccessKeyLoadingSuccessState>(),
      ],
      verify: (_) {
        final draft =
            verify(
                  () => repo.updateKey(
                    id: 'FIOKREADER',
                    draft: captureAny(named: 'draft'),
                    token: 'jwt',
                  ),
                ).captured.single
                as AccessKeyDraft;
        expect(draft.enabled, isFalse);
        expect(draft.name, 'Web CDN');
        expect(draft.grants.single.bucket, 'media');
      },
    );

    blocTest<AccessKeyCubit, AccessKeyState>(
      'Regenerating hands the new secret to the view',
      build: build,
      setUp: () => when(
        () => repo.regenerateSecret(
          id: any(named: 'id'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => accessKey(id: 'FIOKREADER', secret: 's3cr3t')),
      act: (cubit) => cubit.regenerateSecret(reader),
      expect: () => [
        isA<AccessKeyProcessInProgressState>(),
        isA<AccessKeyProcessingOKState>()
            .having(
              (s) => s.action,
              'action',
              AccessKeyAction.secretRegenerated,
            )
            .having((s) => s.key.secret, 'secret', 's3cr3t'),
        isA<AccessKeyLoadingInProgressState>(),
        isA<AccessKeyLoadingSuccessState>(),
      ],
    );

    blocTest<AccessKeyCubit, AccessKeyState>(
      'A failed delete reports the message and does not reload',
      build: build,
      setUp: () => when(
        () => repo.deleteKey(
          id: any(named: 'id'),
          token: any(named: 'token'),
        ),
      ).thenThrow(apiError('Access key not found')),
      act: (cubit) => cubit.delete(reader),
      expect: () => [
        isA<AccessKeyProcessInProgressState>(),
        isA<AccessKeyProcessingErrorState>().having(
          (s) => s.message,
          'message',
          'Access key not found',
        ),
      ],
      verify: (_) =>
          verifyNever(() => repo.listKeys(token: any(named: 'token'))),
    );
  });

  group('bucket deleted elsewhere', () {
    Future<void> deleted(String bucket) async {
      GlobalEventBus().fire(
        BucketChangedEvent(
          source: Object(),
          change: BucketChange.deleted,
          bucketName: bucket,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }

    blocTest<AccessKeyCubit, AccessKeyState>(
      'Reloads when a key had that bucket, and drops it from the filter',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.applyFilter(const AccessKeyFilter(buckets: {'backups', 'media'}));
        await deleted('backups');
      },
      skip: 3,
      expect: () => [
        isA<AccessKeyState>().having((s) => s.data.filter.buckets, 'filter', {
          'media',
        }),
        isA<AccessKeyLoadingInProgressState>(),
        isA<AccessKeyLoadingSuccessState>(),
      ],
      verify: (_) =>
          verify(() => repo.listKeys(token: any(named: 'token'))).called(2),
    );

    blocTest<AccessKeyCubit, AccessKeyState>(
      'Ignores buckets no key had, and other changes',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await deleted('unrelated');
        GlobalEventBus().fire(
          const BucketChangedEvent(
            source: Object(),
            change: BucketChange.updated,
            bucketName: 'media',
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) =>
          verify(() => repo.listKeys(token: any(named: 'token'))).called(1),
    );
  });
}
