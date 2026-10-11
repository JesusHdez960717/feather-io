import 'package:bloc_test/bloc_test.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements BrowserRepo {}

class _MockAuth extends Mock implements AuthCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepo repo;
  late _MockAuth auth;
  late List<BucketChangedEvent> events;

  When<Future<void>> whenCopy({String? sourceKey}) => when(
    () => repo.copyObject(
      sourceBucket: any(named: 'sourceBucket'),
      sourceKey: sourceKey ?? any(named: 'sourceKey'),
      bucket: any(named: 'bucket'),
      key: any(named: 'key'),
      token: any(named: 'token'),
    ),
  );

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    events = [];
    when(() => auth.auth).thenReturn(session());
    when(
      () => repo.createFolder(
        bucket: any(named: 'bucket'),
        key: any(named: 'key'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
    whenCopy().thenAnswer((_) async {});
    when(
      () => repo.deleteObjects(
        bucket: any(named: 'bucket'),
        keys: any(named: 'keys'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
  });

  ObjectActionCubit build() => ObjectActionCubit(repo, auth);

  /// Runs [action] collecting what the cubit announces on the bus
  Future<void> listening(Future<void> Function() action) async {
    final sub = GlobalEventBus().on<BucketChangedEvent>().listen(events.add);
    await action();
    await busDelivered();
    await sub.cancel();
  }

  Set<String> announced() => {for (final e in events) e.bucketName};

  blocTest<ObjectActionCubit, ObjectActionState>(
    'Creates the folder inside the open one',
    build: build,
    act: (cubit) => listening(
      () =>
          cubit.createFolder(bucket: 'media', prefix: 'photos/', name: '2026'),
    ),
    expect: () => [
      isA<ObjectActionProcessInProgressState>(),
      isA<ObjectActionProcessingOKState>(),
    ],
    verify: (_) {
      verify(
        () => repo.createFolder(
          bucket: 'media',
          key: 'photos/2026/',
          token: 'jwt',
        ),
      );
      expect(announced(), {'media'});
    },
  );

  blocTest<ObjectActionCubit, ObjectActionState>(
    'Renaming copies into the same folder and deletes the original',
    build: build,
    act: (cubit) => cubit.rename(
      bucket: 'media',
      key: 'photos/a.jpg',
      newName: 'beach.jpg',
    ),
    expect: () => [
      isA<ObjectActionProcessInProgressState>(),
      isA<ObjectActionProcessingOKState>(),
    ],
    verify: (_) => verifyInOrder([
      () => repo.copyObject(
        sourceBucket: 'media',
        sourceKey: 'photos/a.jpg',
        bucket: 'media',
        key: 'photos/beach.jpg',
        token: 'jwt',
      ),
      () => repo.deleteObjects(
        bucket: 'media',
        keys: ['photos/a.jpg'],
        token: 'jwt',
      ),
    ]),
  );

  blocTest<ObjectActionCubit, ObjectActionState>(
    'Moving copies each object to the target and deletes the originals',
    build: build,
    act: (cubit) => listening(
      () => cubit.move(
        bucket: 'media',
        keys: ['photos/a.jpg', 'photos/b.jpg'],
        targetBucket: 'archive',
        targetPrefix: '2026/',
      ),
    ),
    expect: () => [
      isA<ObjectActionProcessInProgressState>(),
      isA<ObjectActionProcessingOKState>(),
    ],
    verify: (_) {
      verify(
        () => repo.copyObject(
          sourceBucket: 'media',
          sourceKey: 'photos/b.jpg',
          bucket: 'archive',
          key: '2026/b.jpg',
          token: 'jwt',
        ),
      );
      verify(
        () => repo.deleteObjects(
          bucket: 'media',
          keys: ['photos/a.jpg', 'photos/b.jpg'],
          token: 'jwt',
        ),
      );
      expect(announced(), {'media', 'archive'});
    },
  );

  blocTest<ObjectActionCubit, ObjectActionState>(
    'A move that fails halfway deletes only what was copied and says so',
    build: build,
    setUp: () => whenCopy(sourceKey: 'photos/b.jpg').thenThrow(apiError()),
    act: (cubit) => listening(
      () => cubit.move(
        bucket: 'media',
        keys: ['photos/a.jpg', 'photos/b.jpg'],
        targetBucket: 'archive',
        targetPrefix: '',
      ),
    ),
    expect: () => [
      isA<ObjectActionProcessInProgressState>(),
      isA<ObjectActionProcessingErrorState>().having(
        (s) => s.exception.message,
        'message',
        app.intl.objectsMovePartial(1, 2),
      ),
    ],
    verify: (_) {
      verify(
        () => repo.deleteObjects(
          bucket: 'media',
          keys: ['photos/a.jpg'],
          token: 'jwt',
        ),
      ).called(1);
      // what was moved changed both buckets, even if it failed
      expect(announced(), {'media', 'archive'});
    },
  );

  blocTest<ObjectActionCubit, ObjectActionState>(
    'A move that copies nothing keeps the service error and deletes nothing',
    build: build,
    setUp: () => whenCopy().thenThrow(apiError('Access denied')),
    act: (cubit) => cubit.move(
      bucket: 'media',
      keys: ['photos/a.jpg'],
      targetBucket: 'archive',
      targetPrefix: '',
    ),
    expect: () => [
      isA<ObjectActionProcessInProgressState>(),
      isA<ObjectActionProcessingErrorState>().having(
        (s) => s.exception.message,
        'message',
        'Access denied',
      ),
    ],
    verify: (_) => verifyNever(
      () => repo.deleteObjects(
        bucket: any(named: 'bucket'),
        keys: any(named: 'keys'),
        token: any(named: 'token'),
      ),
    ),
  );
}
