import 'package:bloc_test/bloc_test.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements BrowserRepo {}

class _MockAuth extends Mock implements AuthCubit {}

/// A page of [keys]; with [next], more pages follow
ListObjectsModel _page(
  List<String> keys, {
  String? next,
  int total = 0,
  List<String> folders = const [],
}) {
  return ListObjectsModel(
    bucketName: 'media',
    objects: [
      for (final key in keys)
        BrowserObjectModel(
          key: key,
          sizeBytes: 1,
          lastModified: DateTime(2026, 10, 1),
        ),
    ],
    commonPrefixes: folders,
    isTruncated: next != null,
    nextContinuationToken: next,
    totalKeys: total,
  );
}

void main() {
  late _MockRepo repo;
  late _MockAuth auth;

  final media = bucket('media');

  /// The folder `photos/` has two pages: a.jpg + b.jpg, then c.jpg
  void twoPages() {
    when(
      () => repo.listObjects(
        bucket: any(named: 'bucket'),
        token: any(named: 'token'),
        prefix: any(named: 'prefix'),
        delimiter: any(named: 'delimiter'),
        maxKeys: any(named: 'maxKeys'),
        continuationToken: null,
      ),
    ).thenAnswer((_) async => _page(['a.jpg', 'b.jpg'], next: 't1', total: 3));
    when(
      () => repo.listObjects(
        bucket: any(named: 'bucket'),
        token: any(named: 'token'),
        prefix: any(named: 'prefix'),
        delimiter: any(named: 'delimiter'),
        maxKeys: any(named: 'maxKeys'),
        continuationToken: 't1',
      ),
    ).thenAnswer((_) async => _page(['c.jpg'], total: 3));
  }

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    when(() => auth.auth).thenReturn(session());
    twoPages();
    when(
      () => repo.deleteObjects(
        bucket: any(named: 'bucket'),
        keys: any(named: 'keys'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
  });

  BrowserCubit build() => BrowserCubit(auth: auth, repo: repo);

  List<String> shown(BrowserState state) => [
    for (final o in (state as BrowserSearchState).objects?.objects ?? []) o.key,
  ];

  group('open', () {
    blocTest<BrowserCubit, BrowserState>(
      'Lists the first page of the folder',
      build: build,
      act: (cubit) => cubit.open(bucket: media, prefix: 'photos/'),
      expect: () => [
        isA<BrowserLoadingInProgressState>()
            .having((s) => s.prefix, 'prefix', 'photos/')
            .having((s) => s.pages, 'pages', isEmpty),
        isA<BrowserLoadingSuccessState>()
            .having(shown, 'objects', ['a.jpg', 'b.jpg'])
            .having((s) => s.canGoNext, 'canGoNext', isTrue)
            .having((s) => s.canGoPrevious, 'canGoPrevious', isFalse)
            .having((s) => s.totalPages, 'totalPages', 1),
      ],
      verify: (_) => verify(
        () => repo.listObjects(
          bucket: 'media',
          token: 'jwt',
          prefix: 'photos/',
          delimiter: '/',
          maxKeys: BrowserPagination.defaultPageSize,
          continuationToken: null,
        ),
      ).called(1),
    );

    blocTest<BrowserCubit, BrowserState>(
      'Opening what is already shown does nothing',
      build: build,
      act: (cubit) async {
        await cubit.open(bucket: media, prefix: 'photos/');
        await cubit.open(bucket: media, prefix: 'photos/');
      },
      skip: 2,
      expect: () => const <BrowserState>[],
    );

    blocTest<BrowserCubit, BrowserState>(
      'A failure keeps the folder it was going to',
      build: build,
      setUp: () => when(
        () => repo.listObjects(
          bucket: any(named: 'bucket'),
          token: any(named: 'token'),
          prefix: any(named: 'prefix'),
          delimiter: any(named: 'delimiter'),
          maxKeys: any(named: 'maxKeys'),
          continuationToken: any(named: 'continuationToken'),
        ),
      ).thenThrow(apiError('down')),
      act: (cubit) => cubit.open(bucket: media, prefix: 'photos/'),
      expect: () => [
        isA<BrowserLoadingInProgressState>(),
        isA<BrowserLoadingErrorState>()
            .having((s) => s.exception.message, 'message', 'down')
            .having((s) => s.prefix, 'prefix', 'photos/')
            .having((s) => s.selectedBucket?.name, 'bucket', 'media'),
      ],
    );
  });

  group('pages', () {
    blocTest<BrowserCubit, BrowserState>(
      'The next page is requested with the token of the last one',
      build: build,
      act: (cubit) async {
        await cubit.open(bucket: media, prefix: 'photos/');
        await cubit.nextPage();
      },
      skip: 2,
      expect: () => [
        isA<BrowserLoadingInProgressState>(),
        isA<BrowserLoadingSuccessState>()
            .having(shown, 'objects', ['c.jpg'])
            .having((s) => s.pageIndex, 'pageIndex', 1)
            .having((s) => s.canGoNext, 'canGoNext', isFalse)
            .having((s) => s.loadedObjects.map((o) => o.key), 'loaded', [
              'a.jpg',
              'b.jpg',
              'c.jpg',
            ]),
      ],
    );

    blocTest<BrowserCubit, BrowserState>(
      'Pages already loaded are not requested again',
      build: build,
      act: (cubit) async {
        await cubit.open(bucket: media, prefix: 'photos/');
        await cubit.nextPage();
        cubit.previousPage();
        await cubit.nextPage();
      },
      skip: 4,
      expect: () => [
        isA<BrowserLoadingSuccessState>().having(shown, 'objects', [
          'a.jpg',
          'b.jpg',
        ]),
        isA<BrowserLoadingSuccessState>().having(shown, 'objects', ['c.jpg']),
      ],
      verify: (_) => verify(
        () => repo.listObjects(
          bucket: any(named: 'bucket'),
          token: any(named: 'token'),
          prefix: any(named: 'prefix'),
          delimiter: any(named: 'delimiter'),
          maxKeys: any(named: 'maxKeys'),
          continuationToken: any(named: 'continuationToken'),
        ),
      ).called(2),
    );

    blocTest<BrowserCubit, BrowserState>(
      'Refreshing loads every page up to the one shown',
      build: build,
      act: (cubit) async {
        await cubit.open(bucket: media, prefix: 'photos/');
        await cubit.nextPage();
        await cubit.refresh();
      },
      skip: 4,
      expect: () => [
        isA<BrowserLoadingInProgressState>().having(
          (s) => s.pageIndex,
          'keeps the page while loading',
          1,
        ),
        isA<BrowserLoadingSuccessState>()
            .having((s) => s.pageIndex, 'pageIndex', 1)
            .having((s) => s.pages.length, 'pages', 2),
      ],
    );

    blocTest<BrowserCubit, BrowserState>(
      'Changing the page size goes back to the first page',
      build: build,
      act: (cubit) async {
        await cubit.open(bucket: media, prefix: 'photos/');
        await cubit.nextPage();
        await cubit.changePageSize(100);
      },
      skip: 4,
      expect: () => [
        isA<BrowserLoadingInProgressState>(),
        isA<BrowserLoadingSuccessState>()
            .having((s) => s.pageIndex, 'pageIndex', 0)
            .having((s) => s.pageSize, 'pageSize', 100),
      ],
      verify: (_) => verify(
        () => repo.listObjects(
          bucket: any(named: 'bucket'),
          token: any(named: 'token'),
          prefix: any(named: 'prefix'),
          delimiter: any(named: 'delimiter'),
          maxKeys: 100,
          continuationToken: null,
        ),
      ).called(1),
    );
  });

  group('up and forward', () {
    test('Up leads to the parent folder and forward comes back', () async {
      final cubit = build();
      await cubit.open(bucket: media, prefix: 'photos/2026/');

      expect(cubit.goUp(), 'photos/');
      await cubit.open(bucket: media, prefix: 'photos/');
      expect((cubit.state as BrowserSearchState).canGoForward, isTrue);

      expect(cubit.goForward(), 'photos/2026/');
      await cubit.open(bucket: media, prefix: 'photos/2026/');
      expect(cubit.goForward(), isNull);
      await cubit.close();
    });

    test('Up from the root of a folder leads to the bucket root', () async {
      final cubit = build();
      await cubit.open(bucket: media, prefix: 'photos/');
      expect(cubit.goUp(), '');
      await cubit.close();
    });

    test('Up at the bucket root leaves the bucket (null)', () async {
      final cubit = build();
      await cubit.open(bucket: media, prefix: '');
      expect(cubit.goUp(), isNull);
      await cubit.close();
    });

    test('Any other navigation forgets the forward folders', () async {
      final cubit = build();
      await cubit.open(bucket: media, prefix: 'photos/2026/');
      cubit.goUp();
      await cubit.open(bucket: media, prefix: 'photos/');
      await cubit.open(bucket: media, prefix: 'docs/');
      expect(cubit.goForward(), isNull);
      expect((cubit.state as BrowserSearchState).canGoForward, isFalse);
      await cubit.close();
    });
  });

  group('delete', () {
    late List<BucketChangedEvent> events;

    blocTest<BrowserCubit, BrowserState>(
      'Deletes, lists the folder again and tells the other sections',
      build: build,
      act: (cubit) async {
        events = [];
        final other = GlobalEventBus().on<BucketChangedEvent>().listen(
          events.add,
        );
        await cubit.open(bucket: media, prefix: 'photos/');
        await cubit.deleteObjects(bucket: media, keys: ['photos/a.jpg']);
        await busDelivered();
        await other.cancel();
      },
      skip: 2,
      expect: () => [
        isA<BrowserProcessInProgressState>(),
        isA<BrowserLoadingInProgressState>(),
        isA<BrowserLoadingSuccessState>(),
      ],
      verify: (cubit) {
        verify(
          () => repo.deleteObjects(
            bucket: 'media',
            keys: ['photos/a.jpg'],
            token: 'jwt',
          ),
        );
        expect(events.single.change, BucketChange.objectsChanged);
        expect(events.single.source, same(cubit));
      },
    );

    blocTest<BrowserCubit, BrowserState>(
      'A failure keeps the content and still tells the others',
      build: build,
      act: (cubit) async {
        events = [];
        final other = GlobalEventBus().on<BucketChangedEvent>().listen(
          events.add,
        );
        await cubit.open(bucket: media, prefix: 'photos/');
        when(
          () => repo.deleteObjects(
            bucket: any(named: 'bucket'),
            keys: any(named: 'keys'),
            token: any(named: 'token'),
          ),
        ).thenThrow(apiError('down'));
        await cubit.deleteObjects(bucket: media, keys: ['photos/a.jpg']);
        await busDelivered();
        await other.cancel();
      },
      skip: 2,
      expect: () => [
        isA<BrowserProcessInProgressState>(),
        isA<BrowserLoadingErrorState>()
            .having((s) => s.exception.message, 'message', 'down')
            .having(shown, 'objects', ['a.jpg', 'b.jpg']),
      ],
      verify: (_) => expect(events, hasLength(1)),
    );
  });

  group('changes from other sections', () {
    Future<void> changed(
      BucketChange change, {
      String name = 'media',
      BucketModel? bucket,
    }) async {
      GlobalEventBus().fire(
        BucketChangedEvent(
          source: Object(),
          change: change,
          bucketName: name,
          bucket: bucket,
        ),
      );
      await busDelivered();
    }

    blocTest<BrowserCubit, BrowserState>(
      'Lists the folder again when the open bucket gets new objects',
      build: build,
      act: (cubit) async {
        await cubit.open(bucket: media, prefix: 'photos/');
        await changed(BucketChange.objectsChanged);
      },
      skip: 2,
      expect: () => [
        isA<BrowserLoadingInProgressState>(),
        isA<BrowserLoadingSuccessState>(),
      ],
    );

    blocTest<BrowserCubit, BrowserState>(
      'Takes the new metadata of the open bucket',
      build: build,
      act: (cubit) async {
        await cubit.open(bucket: media, prefix: 'photos/');
        await changed(
          BucketChange.updated,
          bucket: BucketModel(
            name: 'media',
            description: 'Photos',
            objectCount: 0,
            sizeBytes: 0,
            creationDate: DateTime(2026, 10, 1),
          ),
        );
      },
      skip: 2,
      expect: () => [
        isA<BrowserLoadingSuccessState>().having(
          (s) => s.selectedBucket?.description,
          'description',
          'Photos',
        ),
      ],
    );

    blocTest<BrowserCubit, BrowserState>(
      'Ignores the changes of other buckets',
      build: build,
      act: (cubit) async {
        await cubit.open(bucket: media, prefix: 'photos/');
        await changed(BucketChange.objectsChanged, name: 'backups');
      },
      skip: 2,
      expect: () => const <BrowserState>[],
    );
  });
}
