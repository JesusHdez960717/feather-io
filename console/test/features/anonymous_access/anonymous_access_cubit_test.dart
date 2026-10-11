import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockRepo extends Mock implements AnonymousAccessRepo {}

class _MockAuth extends Mock implements AuthCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepo repo;
  late _MockAuth auth;

  final photos = AnonymousRuleModel(
    prefix: 'photos/',
    access: AnonymousAccessType.readOnly,
  );
  final inbox = AnonymousRuleModel(
    prefix: 'inbox/*.pdf',
    access: AnonymousAccessType.writeOnly,
  );

  setUpAll(() => registerFallbackValue(photos));

  setUp(() {
    repo = _MockRepo();
    auth = _MockAuth();
    when(() => auth.auth).thenReturn(session());
    when(
      () => repo.getRules(
        bucket: any(named: 'bucket'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => [photos, inbox]);
    when(
      () => repo.deleteRule(
        bucket: any(named: 'bucket'),
        prefix: any(named: 'prefix'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
  });

  List<String> prefixes(AnonymousAccessState state) =>
      state.rules.map((r) => r.prefix).toList();

  group('AnonymousAccessCubit', () {
    AnonymousAccessCubit build() => AnonymousAccessCubit(repo, auth);

    blocTest<AnonymousAccessCubit, AnonymousAccessState>(
      'Loads the rules of the bucket',
      build: build,
      act: (cubit) => cubit.load(bucket: 'media'),
      expect: () => [
        isA<AnonymousAccessLoadingInProgressState>()
            .having((s) => s.bucket, 'bucket', 'media')
            .having(prefixes, 'rules', isEmpty),
        isA<AnonymousAccessLoadingSuccessState>().having(prefixes, 'rules', [
          'photos/',
          'inbox/*.pdf',
        ]),
      ],
      verify: (_) => verify(() => repo.getRules(bucket: 'media', token: 'jwt')),
    );

    blocTest<AnonymousAccessCubit, AnonymousAccessState>(
      "Another bucket doesn't show the previous one's rules while loading",
      build: build,
      act: (cubit) async {
        await cubit.load(bucket: 'media');
        await cubit.load(bucket: 'backups');
      },
      skip: 2,
      expect: () => [
        isA<AnonymousAccessLoadingInProgressState>()
            .having((s) => s.bucket, 'bucket', 'backups')
            .having(prefixes, 'rules', isEmpty),
        isA<AnonymousAccessLoadingSuccessState>(),
      ],
    );

    blocTest<AnonymousAccessCubit, AnonymousAccessState>(
      'A late response of a bucket no longer shown is dropped',
      build: build,
      act: (cubit) async {
        final slow = Completer<List<AnonymousRuleModel>>();
        when(
          () => repo.getRules(
            bucket: 'media',
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) => slow.future);
        final first = cubit.load(bucket: 'media');
        await cubit.load(bucket: 'backups');
        slow.complete([photos]);
        await first;
      },
      expect: () => [
        isA<AnonymousAccessLoadingInProgressState>().having(
          (s) => s.bucket,
          'bucket',
          'media',
        ),
        isA<AnonymousAccessLoadingInProgressState>().having(
          (s) => s.bucket,
          'bucket',
          'backups',
        ),
        isA<AnonymousAccessLoadingSuccessState>()
            .having((s) => s.bucket, 'bucket', 'backups')
            .having(prefixes, 'rules', ['photos/', 'inbox/*.pdf']),
      ],
    );

    blocTest<AnonymousAccessCubit, AnonymousAccessState>(
      'Deleting a rule reloads the bucket',
      build: build,
      act: (cubit) async {
        await cubit.load(bucket: 'media');
        await cubit.deleteRule(prefix: 'photos/');
      },
      skip: 2,
      expect: () => [
        isA<AnonymousAccessProcessInProgressState>(),
        isA<AnonymousAccessProcessingOKState>(),
        isA<AnonymousAccessLoadingInProgressState>(),
        isA<AnonymousAccessLoadingSuccessState>(),
      ],
      verify: (_) => verify(
        () => repo.deleteRule(bucket: 'media', prefix: 'photos/', token: 'jwt'),
      ),
    );

    blocTest<AnonymousAccessCubit, AnonymousAccessState>(
      'Without a bucket there is nothing to delete',
      build: build,
      act: (cubit) => cubit.deleteRule(prefix: 'photos/'),
      expect: () => const <AnonymousAccessState>[],
    );

    blocTest<AnonymousAccessCubit, AnonymousAccessState>(
      'A failed delete keeps the rules and carries the message',
      build: build,
      act: (cubit) async {
        await cubit.load(bucket: 'media');
        when(
          () => repo.deleteRule(
            bucket: any(named: 'bucket'),
            prefix: any(named: 'prefix'),
            token: any(named: 'token'),
          ),
        ).thenThrow(apiError('down'));
        await cubit.deleteRule(prefix: 'photos/');
      },
      skip: 2,
      expect: () => [
        isA<AnonymousAccessProcessInProgressState>(),
        isA<AnonymousAccessProcessingErrorState>()
            .having((s) => s.message, 'message', 'down')
            .having(prefixes, 'rules', ['photos/', 'inbox/*.pdf']),
      ],
    );
  });

  group('AnonymousRuleFormCubit', () {
    AnonymousRuleFormCubit build() => AnonymousRuleFormCubit(repo, auth);

    When<Future<void>> whenCreate() => when(
      () => repo.createRule(
        bucket: any(named: 'bucket'),
        rule: any(named: 'rule'),
        token: any(named: 'token'),
      ),
    );

    blocTest<AnonymousRuleFormCubit, AnonymousRuleFormState>(
      'Creates the rule',
      build: build,
      setUp: () => whenCreate().thenAnswer((_) async {}),
      act: (cubit) => cubit.create(bucket: 'media', rule: photos),
      expect: () => [
        isA<AnonymousRuleFormProcessInProgressState>(),
        isA<AnonymousRuleFormProcessingOKState>().having(
          (s) => s.prefix,
          'prefix',
          'photos/',
        ),
      ],
      verify: (_) => verify(
        () => repo.createRule(bucket: 'media', rule: photos, token: 'jwt'),
      ),
    );

    blocTest<AnonymousRuleFormCubit, AnonymousRuleFormState>(
      'A 422 goes to the fields that failed',
      build: build,
      setUp: () => whenCreate().thenThrow(
        ExceptionConverter.parse(
          httpError(422, {
            'status': 422,
            'violations': [
              {
                'fieldName': 'prefix',
                'message': 'Too short',
                'code': 'size.min',
              },
            ],
          }),
        ),
      ),
      act: (cubit) => cubit.create(bucket: 'media', rule: photos),
      expect: () => [
        isA<AnonymousRuleFormProcessInProgressState>(),
        isA<AnonymousRuleFormProcessingErrorState>().having(
          (s) => s.fieldErrors,
          'fieldErrors',
          {AnonymousRuleFormField.prefix: 'Too short'},
        ),
      ],
    );

    blocTest<AnonymousRuleFormCubit, AnonymousRuleFormState>(
      'Any other error belongs to the whole form',
      build: build,
      setUp: () => whenCreate().thenThrow(apiError('down')),
      act: (cubit) => cubit.create(bucket: 'media', rule: photos),
      expect: () => [
        isA<AnonymousRuleFormProcessInProgressState>(),
        isA<AnonymousRuleFormProcessingErrorState>()
            .having((s) => s.exception.message, 'message', 'down')
            .having((s) => s.fieldErrors, 'fieldErrors', isEmpty),
      ],
    );
  });
}
