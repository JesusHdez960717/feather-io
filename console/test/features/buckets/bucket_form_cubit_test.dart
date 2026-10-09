import 'package:bloc_test/bloc_test.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements BucketRepo {}

class _MockAuth extends Mock implements AuthCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepo repo;
  late _MockAuth auth;

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    when(() => auth.auth).thenReturn(session());
  });

  BucketFormCubit build() => BucketFormCubit(repo, auth);

  When<Future<void>> whenCreate() => when(
    () => repo.createBucket(
      name: any(named: 'name'),
      description: any(named: 'description'),
      color: any(named: 'color'),
      token: any(named: 'token'),
    ),
  );

  blocTest<BucketFormCubit, BucketFormState>(
    'Creates the bucket with its metadata',
    build: build,
    setUp: () => whenCreate().thenAnswer((_) async {}),
    act: (cubit) =>
        cubit.create(name: 'media', description: 'Photos', color: 0xFF2196F3),
    expect: () => [
      isA<BucketFormProcessInProgressState>(),
      isA<BucketFormProcessingOKState>()
          .having((s) => s.name, 'name', 'media')
          .having((s) => s.change, 'change', BucketChange.created)
          .having((s) => s.bucket, 'bucket', isNull),
    ],
    verify: (_) => verify(
      () => repo.createBucket(
        name: 'media',
        description: 'Photos',
        color: 0xFF2196F3,
        token: 'jwt',
      ),
    ),
  );

  blocTest<BucketFormCubit, BucketFormState>(
    'Editing returns the updated bucket',
    build: build,
    setUp: () => when(
      () => repo.updateBucket(
        name: any(named: 'name'),
        description: any(named: 'description'),
        color: any(named: 'color'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => bucket('media')),
    act: (cubit) => cubit.update(name: 'media', description: 'New'),
    expect: () => [
      isA<BucketFormProcessInProgressState>(),
      isA<BucketFormProcessingOKState>()
          .having((s) => s.change, 'change', BucketChange.updated)
          .having((s) => s.bucket?.name, 'bucket', 'media'),
    ],
  );

  blocTest<BucketFormCubit, BucketFormState>(
    'A 422 goes to the fields that failed',
    build: build,
    setUp: () => whenCreate().thenThrow(
      ExceptionConverter.parse(
        httpError(422, {
          'status': 422,
          'violations': [
            {
              'fieldName': 'description',
              'message': 'Too long',
              'code': 'size.max',
            },
          ],
        }),
      ),
    ),
    act: (cubit) => cubit.create(name: 'media'),
    expect: () => [
      isA<BucketFormProcessInProgressState>(),
      isA<BucketFormProcessingErrorState>().having(
        (s) => s.fieldErrors,
        'fieldErrors',
        {BucketFormField.description: 'Too long'},
      ),
    ],
  );

  blocTest<BucketFormCubit, BucketFormState>(
    'A 409 (the bucket already exists) goes to the name',
    build: build,
    setUp: () => whenCreate().thenThrow(
      ExceptionConverter.parse(
        httpError(409, {'code': 'BucketAlreadyExists', 'detail': 'Exists'}),
      ),
    ),
    act: (cubit) => cubit.create(name: 'media'),
    expect: () => [
      isA<BucketFormProcessInProgressState>(),
      isA<BucketFormProcessingErrorState>().having(
        (s) => s.fieldErrors.keys,
        'fields',
        [BucketFormField.name],
      ),
    ],
  );

  blocTest<BucketFormCubit, BucketFormState>(
    'Any other error belongs to the whole form',
    build: build,
    setUp: () => whenCreate().thenThrow(apiError('down')),
    act: (cubit) => cubit.create(name: 'media'),
    expect: () => [
      isA<BucketFormProcessInProgressState>(),
      isA<BucketFormProcessingErrorState>()
          .having((s) => s.exception.message, 'message', 'down')
          .having((s) => s.fieldErrors, 'fieldErrors', isEmpty),
    ],
  );
}
