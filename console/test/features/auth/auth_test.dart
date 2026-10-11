import 'package:bloc_test/bloc_test.dart';
import 'package:console/app_exporter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockClient extends Mock implements AuthClient {}

class _MockStorage extends Mock implements FlutterSecureStorage {}

class _MockRepo extends Mock implements AuthRepo {}

/// In-memory storage with the same calls the repo makes
_MockStorage _memoryStorage(Map<String, String> data) {
  final storage = _MockStorage();
  when(() => storage.read(key: any(named: 'key')))
      .thenAnswer((i) async => data[i.namedArguments[#key]]);
  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((i) async {
    data[i.namedArguments[#key] as String] = i.namedArguments[#value] as String;
  });
  when(() => storage.delete(key: any(named: 'key')))
      .thenAnswer((i) async => data.remove(i.namedArguments[#key]));
  return storage;
}

void main() {
  setUpAll(() {
    registerFallbackValue(LoginRequest(access: '', secret: ''));
    registerFallbackValue(AuthModel(accessToken: '', expireAt: DateTime(2100)));
  });

  group('AuthRepo', () {
    late Map<String, String> data;
    late AuthRepo repo;
    late _MockClient client;

    setUp(() {
      data = {};
      client = _MockClient();
      repo = AuthRepo(client, storage: _memoryStorage(data));
    });

    test('Saves the JWT and its expiry, never the keys', () async {
      final expireAt = DateTime.now().add(const Duration(hours: 12));
      await repo.save(AuthModel(accessToken: 'jwt', expireAt: expireAt));

      expect(data.values, contains('jwt'));
      expect(data.values.join(), isNot(contains('secret')));
      final restored = await repo.restore();
      expect(restored?.accessToken, 'jwt');
      expect(
        restored?.expireAt.millisecondsSinceEpoch,
        expireAt.millisecondsSinceEpoch,
      );
    });

    test('Nothing saved: no session', () async {
      expect(await repo.restore(), isNull);
    });

    test('An expired session is deleted, not restored', () async {
      await repo.save(
        AuthModel(
          accessToken: 'old',
          expireAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      expect(await repo.restore(), isNull);
      expect(data, isEmpty);
    });

    test('A broken expiry counts as no session', () async {
      data['auth.access_token'] = 'jwt';
      data['auth.expire_at'] = 'not a date';
      expect(await repo.restore(), isNull);
    });

    test('Unreadable storage: logs in again and clears it', () async {
      final broken = _MockStorage();
      when(() => broken.read(key: any(named: 'key')))
          .thenThrow(Exception('cannot decrypt'));
      when(() => broken.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      final repo = AuthRepo(client, storage: broken);

      expect(await repo.restore(), isNull);
      verify(() => broken.delete(key: any(named: 'key'))).called(2);
    });

    test('Login maps the response and does not keep the secret', () async {
      final expireAt = DateTime(2100);
      when(() => client.login(any())).thenAnswer(
        (_) async => LoginResponse(
          accessToken: 'jwt',
          expiresIn: 1000,
          expireAt: expireAt,
        ),
      );

      final auth = await repo.login(access: 'access', secret: 'secret');

      expect(auth.accessToken, 'jwt');
      expect(auth.expireAt, expireAt);
      final sent =
          verify(() => client.login(captureAny())).captured.single
              as LoginRequest;
      expect(sent.toJson(), {'access': 'access', 'secret': 'secret'});
    });
  });

  group('AuthCubit', () {
    late _MockRepo repo;
    final session = AuthModel(accessToken: 'jwt', expireAt: DateTime(2100));

    setUp(() {
      repo = _MockRepo();
      when(() => repo.save(any())).thenAnswer((_) async {});
      when(() => repo.clear()).thenAnswer((_) async {});
    });

    test('Restores the saved session without emitting', () async {
      when(() => repo.restore()).thenAnswer((_) async => session);
      final cubit = AuthCubit(repo);

      await cubit.restore();

      expect(cubit.auth?.accessToken, 'jwt');
      expect(cubit.state, isA<AuthInitialState>());
    });

    blocTest<AuthCubit, AuthState>(
      'A login keeps the session and saves it',
      build: () => AuthCubit(repo),
      setUp: () => when(
        () => repo.login(
          access: any(named: 'access'),
          secret: any(named: 'secret'),
        ),
      ).thenAnswer((_) async => session),
      act: (cubit) => cubit.login(access: 'access', secret: 'secret'),
      expect: () => [
        isA<AuthProcessInProgressState>(),
        isA<AuthProcessingOKState>(),
      ],
      verify: (cubit) {
        expect(cubit.auth?.accessToken, 'jwt');
        verify(() => repo.save(session)).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'A failed login keeps no session and saves nothing',
      build: () => AuthCubit(repo),
      setUp: () => when(
        () => repo.login(
          access: any(named: 'access'),
          secret: any(named: 'secret'),
        ),
      ).thenThrow(apiError('Invalid credentials')),
      act: (cubit) => cubit.login(access: 'access', secret: 'wrong'),
      expect: () => [
        isA<AuthProcessInProgressState>(),
        isA<AuthProcessingErrorState>().having(
          (s) => s.message,
          'message',
          'Invalid credentials',
        ),
      ],
      verify: (cubit) {
        expect(cubit.auth, isNull);
        verifyNever(() => repo.save(any()));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'Logging out forgets the session and deletes it',
      build: () => AuthCubit(repo),
      seed: () => AuthInitialState(),
      act: (cubit) async {
        when(() => repo.restore()).thenAnswer((_) async => session);
        await cubit.restore();
        cubit.logout();
      },
      expect: () => [isA<AuthLogoutState>()],
      verify: (cubit) {
        expect(cubit.auth, isNull);
        verify(() => repo.clear()).called(1);
      },
    );
  });
}
