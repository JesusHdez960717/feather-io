import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fixtures.dart';

class _MockClient extends Mock implements AnonymousAccessClient {}

void main() {
  late _MockClient client;
  late AnonymousAccessRepo repo;

  setUpAll(() {
    registerFallbackValue(AnonymousRuleCreateRequest(prefix: '', access: ''));
    registerFallbackValue(AnonymousRuleDeleteRequest(prefix: ''));
  });

  setUp(() {
    client = _MockClient();
    repo = AnonymousAccessRepo(client);
  });

  test('Maps the access names of the API to the enum', () async {
    when(
      () => client.getRules(
        bucket: any(named: 'bucket'),
        token: any(named: 'token'),
      ),
    ).thenAnswer(
      (_) async => [
        AnonymousRuleResponse.fromJson({
          'prefix': 'photos/',
          'access': 'readOnly',
        }),
        AnonymousRuleResponse.fromJson({
          'prefix': 'inbox/*.pdf',
          'access': 'readWrite',
        }),
      ],
    );

    final rules = await repo.getRules(bucket: 'media', token: 'jwt');

    expect(rules.map((r) => r.prefix), ['photos/', 'inbox/*.pdf']);
    expect(rules.map((r) => r.access), [
      AnonymousAccessType.readOnly,
      AnonymousAccessType.readWrite,
    ]);
  });

  test('A new rule sends the prefix and the access name', () async {
    when(
      () => client.createRule(
        bucket: any(named: 'bucket'),
        request: any(named: 'request'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});

    await repo.createRule(
      bucket: 'media',
      rule: AnonymousRuleModel(
        prefix: 'inbox/',
        access: AnonymousAccessType.writeOnly,
      ),
    );

    final request =
        verify(
              () => client.createRule(
                bucket: 'media',
                request: captureAny(named: 'request'),
                token: any(named: 'token'),
              ),
            ).captured.single
            as AnonymousRuleCreateRequest;
    expect(request.toJson(), {'prefix': 'inbox/', 'access': 'writeOnly'});
  });

  test('An API error arrives with the service message', () async {
    when(
      () => client.deleteRule(
        bucket: any(named: 'bucket'),
        request: any(named: 'request'),
        token: any(named: 'token'),
      ),
    ).thenThrow(
      httpError(404, {
        'code': 'NoSuchBucket',
        'detail': 'The bucket "media" does not exist.',
      }),
    );

    await expectLater(
      () => repo.deleteRule(bucket: 'media', prefix: 'photos/'),
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
