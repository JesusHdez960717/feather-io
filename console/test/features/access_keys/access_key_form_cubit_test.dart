import 'package:bloc_test/bloc_test.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements AccessKeyRepo {}

class _MockAuth extends Mock implements AuthCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepo repo;
  late _MockAuth auth;

  final draft = AccessKeyDraft.of(
    accessKey(name: 'CI', allBuckets: AccessKeyLevel.readWrite),
  );

  setUpAll(() => registerFallbackValue(draft));

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    when(() => auth.auth).thenReturn(session());
  });

  AccessKeyFormCubit build() => AccessKeyFormCubit(repo, auth);

  When<Future<AccessKeyModel>> whenCreate() => when(
    () => repo.createKey(
      draft: any(named: 'draft'),
      token: any(named: 'token'),
    ),
  );

  blocTest<AccessKeyFormCubit, AccessKeyFormState>(
    'Creating returns the key with its secret',
    build: build,
    setUp: () => whenCreate().thenAnswer(
      (_) async => accessKey(name: 'CI', secret: 'shown-once'),
    ),
    act: (cubit) => cubit.save(draft: draft),
    expect: () => [
      isA<AccessKeyFormProcessInProgressState>(),
      isA<AccessKeyFormProcessingOKState>()
          .having((s) => s.created, 'created', isTrue)
          .having((s) => s.key.secret, 'secret', 'shown-once'),
    ],
    verify: (_) => verify(() => repo.createKey(draft: draft, token: 'jwt')),
  );

  blocTest<AccessKeyFormCubit, AccessKeyFormState>(
    'With an id it updates that key',
    build: build,
    setUp: () => when(
      () => repo.updateKey(
        id: any(named: 'id'),
        draft: any(named: 'draft'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => accessKey(name: 'CI')),
    act: (cubit) => cubit.save(draft: draft, id: 'FIOKAAAA'),
    expect: () => [
      isA<AccessKeyFormProcessInProgressState>(),
      isA<AccessKeyFormProcessingOKState>().having(
        (s) => s.created,
        'created',
        isFalse,
      ),
    ],
    verify: (_) => verify(
      () => repo.updateKey(id: 'FIOKAAAA', draft: draft, token: 'jwt'),
    ),
  );

  blocTest<AccessKeyFormCubit, AccessKeyFormState>(
    'A 422 goes to the fields that failed',
    build: build,
    setUp: () => whenCreate().thenThrow(
      ExceptionConverter.parse(
        httpError(422, [
          {'fieldName': 'name', 'value': '', 'message': 'Too short'},
        ]),
      ),
    ),
    act: (cubit) => cubit.save(draft: draft),
    expect: () => [
      isA<AccessKeyFormProcessInProgressState>(),
      isA<AccessKeyFormProcessingErrorState>().having(
        (s) => s.fieldErrors,
        'fieldErrors',
        {AccessKeyFormField.name: 'Too short'},
      ),
    ],
  );

  blocTest<AccessKeyFormCubit, AccessKeyFormState>(
    'Any other error belongs to the whole form',
    build: build,
    setUp: () => whenCreate().thenThrow(apiError('down')),
    act: (cubit) => cubit.save(draft: draft),
    expect: () => [
      isA<AccessKeyFormProcessInProgressState>(),
      isA<AccessKeyFormProcessingErrorState>()
          .having((s) => s.exception.message, 'message', 'down')
          .having((s) => s.fieldErrors, 'fieldErrors', isEmpty),
    ],
  );
}
