import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements BrowserRepo {}

class _MockAuth extends Mock implements AuthCubit {}

void main() {
  late _MockRepo repo;
  late _MockAuth auth;

  setUpAll(() => registerFallbackValue(Duration.zero));

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    when(() => auth.auth).thenReturn(session());
  });

  group('MoveTargetCubit', () {
    When<Future<ListObjectsModel>> whenList({String? prefix}) => when(
      () => repo.listObjects(
        bucket: any(named: 'bucket'),
        token: any(named: 'token'),
        prefix: prefix ?? any(named: 'prefix'),
        delimiter: any(named: 'delimiter'),
        maxKeys: any(named: 'maxKeys'),
        continuationToken: any(named: 'continuationToken'),
      ),
    );

    ListObjectsModel folders(List<String> prefixes) => ListObjectsModel(
      bucketName: 'media',
      objects: const [],
      commonPrefixes: prefixes,
    );

    blocTest<MoveTargetCubit, MoveTargetState>(
      'Lists the subfolders of the open folder',
      build: () => MoveTargetCubit(repo, auth),
      setUp: () => whenList().thenAnswer(
        (_) async => folders(['photos/2025/', 'photos/2026/']),
      ),
      act: (cubit) => cubit.open(bucket: 'media', prefix: 'photos/'),
      expect: () => [
        isA<MoveTargetLoadingInProgressState>().having(
          (s) => s.prefix,
          'prefix',
          'photos/',
        ),
        isA<MoveTargetLoadingSuccessState>().having(
          (s) => s.folders,
          'folders',
          ['photos/2025/', 'photos/2026/'],
        ),
      ],
      verify: (_) => verify(
        () => repo.listObjects(
          bucket: 'media',
          token: 'jwt',
          prefix: 'photos/',
          delimiter: '/',
          maxKeys: 1000,
        ),
      ),
    );

    blocTest<MoveTargetCubit, MoveTargetState>(
      'A late listing of a folder no longer open is dropped',
      build: () => MoveTargetCubit(repo, auth),
      act: (cubit) async {
        final slow = Completer<ListObjectsModel>();
        whenList(prefix: 'photos/').thenAnswer((_) => slow.future);
        whenList(prefix: 'docs/').thenAnswer((_) async => folders(['docs/a/']));
        final first = cubit.open(bucket: 'media', prefix: 'photos/');
        await cubit.open(bucket: 'media', prefix: 'docs/');
        slow.complete(folders(['photos/2026/']));
        await first;
      },
      expect: () => [
        isA<MoveTargetLoadingInProgressState>(),
        isA<MoveTargetLoadingInProgressState>(),
        isA<MoveTargetLoadingSuccessState>()
            .having((s) => s.prefix, 'prefix', 'docs/')
            .having((s) => s.folders, 'folders', ['docs/a/']),
      ],
    );
  });

  group('ObjectDetailsCubit', () {
    void head(String? contentType) =>
        when(
          () => repo.headObject(
            bucket: any(named: 'bucket'),
            key: any(named: 'key'),
            token: any(named: 'token'),
          ),
        ).thenAnswer(
          (_) async => ObjectInfoModel(contentType: contentType, sizeBytes: 3),
        );

    setUp(
      () => when(
        () => repo.getObject(
          bucket: any(named: 'bucket'),
          key: any(named: 'key'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => ObjectDataModel(bytes: [1, 2, 3])),
    );

    blocTest<ObjectDetailsCubit, ObjectDetailsState>(
      'A small image brings its bytes for the thumbnail',
      build: () => ObjectDetailsCubit(repo, auth),
      setUp: () => head('image/png'),
      act: (cubit) =>
          cubit.load(bucket: 'media', key: 'photos/a.png', sizeBytes: 3),
      expect: () => [
        isA<ObjectDetailsLoadingInProgressState>(),
        isA<ObjectDetailsLoadingSuccessState>()
            .having((s) => s.info.contentType, 'type', 'image/png')
            .having((s) => s.thumbnail, 'thumbnail', [1, 2, 3])
            .having((s) => s.thumbnailIsSvg, 'svg', isFalse),
      ],
    );

    blocTest<ObjectDetailsCubit, ObjectDetailsState>(
      'An SVG brings its bytes marked as SVG',
      build: () => ObjectDetailsCubit(repo, auth),
      setUp: () => head('image/svg+xml'),
      act: (cubit) =>
          cubit.load(bucket: 'media', key: 'icons/a.svg', sizeBytes: 3),
      skip: 1,
      expect: () => [
        isA<ObjectDetailsLoadingSuccessState>()
            .having((s) => s.thumbnail, 'thumbnail', [1, 2, 3])
            .having((s) => s.thumbnailIsSvg, 'svg', isTrue),
      ],
    );

    blocTest<ObjectDetailsCubit, ObjectDetailsState>(
      'Without a stored type, an .svg key is an SVG',
      build: () => ObjectDetailsCubit(repo, auth),
      setUp: () => head(null),
      act: (cubit) =>
          cubit.load(bucket: 'media', key: 'icons/a.svg', sizeBytes: 3),
      skip: 1,
      expect: () => [
        isA<ObjectDetailsLoadingSuccessState>()
            .having((s) => s.thumbnail, 'thumbnail', isNotNull)
            .having((s) => s.thumbnailIsSvg, 'svg', isTrue),
      ],
    );

    blocTest<ObjectDetailsCubit, ObjectDetailsState>(
      'A big image is not downloaded',
      build: () => ObjectDetailsCubit(repo, auth),
      setUp: () => head('image/png'),
      act: (cubit) => cubit.load(
        bucket: 'media',
        key: 'photos/a.png',
        sizeBytes: ObjectDetailsCubit.maxThumbnailBytes + 1,
      ),
      skip: 1,
      expect: () => [
        isA<ObjectDetailsLoadingSuccessState>().having(
          (s) => s.thumbnail,
          'thumbnail',
          isNull,
        ),
      ],
      verify: (_) => verifyNever(
        () => repo.getObject(
          bucket: any(named: 'bucket'),
          key: any(named: 'key'),
          token: any(named: 'token'),
        ),
      ),
    );

    blocTest<ObjectDetailsCubit, ObjectDetailsState>(
      'Without a stored type, the extension decides if it is an image',
      build: () => ObjectDetailsCubit(repo, auth),
      setUp: () => head(null),
      act: (cubit) =>
          cubit.load(bucket: 'media', key: 'photos/a.jpg', sizeBytes: 3),
      skip: 1,
      expect: () => [
        isA<ObjectDetailsLoadingSuccessState>().having(
          (s) => s.thumbnail,
          'thumbnail',
          isNotNull,
        ),
      ],
    );

    blocTest<ObjectDetailsCubit, ObjectDetailsState>(
      'Another type has no thumbnail',
      build: () => ObjectDetailsCubit(repo, auth),
      setUp: () => head('application/pdf'),
      act: (cubit) =>
          cubit.load(bucket: 'media', key: 'docs/a.pdf', sizeBytes: 3),
      skip: 1,
      expect: () => [
        isA<ObjectDetailsLoadingSuccessState>().having(
          (s) => s.thumbnail,
          'thumbnail',
          isNull,
        ),
      ],
    );
  });

  group('ShareLinkCubit', () {
    final link = SharedLinkModel(
      url: 'http://localhost:8080/media/a.jpg?X-Amz-Signature=x',
      expiresAt: DateTime(2026, 10, 6),
    );

    When<Future<SharedLinkModel>> whenPresign({Duration? expiresIn}) => when(
      () => repo.presign(
        bucket: any(named: 'bucket'),
        key: any(named: 'key'),
        expiresIn: expiresIn ?? any(named: 'expiresIn'),
        token: any(named: 'token'),
      ),
    );

    blocTest<ShareLinkCubit, ShareLinkState>(
      'Asks the service for a link with the chosen expiry',
      build: () => ShareLinkCubit(repo, auth),
      setUp: () => whenPresign().thenAnswer((_) async => link),
      act: (cubit) => cubit.generate(
        bucket: 'media',
        key: 'a.jpg',
        expiration: ShareLinkExpiration.week,
      ),
      expect: () => [
        isA<ShareLinkLoadingInProgressState>(),
        isA<ShareLinkLoadingSuccessState>()
            .having((s) => s.link.url, 'url', link.url)
            .having(
              (s) => s.expiration,
              'expiration',
              ShareLinkExpiration.week,
            ),
      ],
      verify: (_) => verify(
        () => repo.presign(
          bucket: 'media',
          key: 'a.jpg',
          expiresIn: const Duration(days: 7),
          token: 'jwt',
        ),
      ),
    );

    blocTest<ShareLinkCubit, ShareLinkState>(
      'A link of an expiry no longer chosen is dropped',
      build: () => ShareLinkCubit(repo, auth),
      act: (cubit) async {
        final slow = Completer<SharedLinkModel>();
        whenPresign(expiresIn: ShareLinkExpiration.hour.duration)
            .thenAnswer((_) => slow.future);
        whenPresign(expiresIn: ShareLinkExpiration.week.duration)
            .thenAnswer((_) async => link);
        final first = cubit.generate(
          bucket: 'media',
          key: 'a.jpg',
          expiration: ShareLinkExpiration.hour,
        );
        await cubit.generate(
          bucket: 'media',
          key: 'a.jpg',
          expiration: ShareLinkExpiration.week,
        );
        slow.complete(link);
        await first;
      },
      expect: () => [
        isA<ShareLinkLoadingInProgressState>(),
        isA<ShareLinkLoadingInProgressState>(),
        isA<ShareLinkLoadingSuccessState>().having(
          (s) => s.expiration,
          'expiration',
          ShareLinkExpiration.week,
        ),
      ],
    );

    blocTest<ShareLinkCubit, ShareLinkState>(
      'A failure carries the error',
      build: () => ShareLinkCubit(repo, auth),
      setUp: () => whenPresign().thenThrow(apiError('down')),
      act: (cubit) => cubit.generate(
        bucket: 'media',
        key: 'a.jpg',
        expiration: ShareLinkExpiration.day,
      ),
      expect: () => [
        isA<ShareLinkLoadingInProgressState>(),
        isA<ShareLinkLoadingErrorState>().having(
          (s) => s.exception.message,
          'message',
          'down',
        ),
      ],
    );
  });
}
