import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements AccessKeyClient {}

AccessKeyResponse _response({
  String id = 'FIOKAAAA',
  String? allBuckets,
  List<AccessKeyGrantDto> buckets = const [],
  String? secret,
}) {
  return AccessKeyResponse(
    accessKeyId: id,
    name: 'Backups NAS',
    enabled: true,
    expired: false,
    allBuckets: allBuckets,
    buckets: buckets,
    expiresAt: DateTime.utc(2027, 1, 1),
    createdAt: DateTime.utc(2026, 10, 1),
    lastUsedAt: null,
    secretAccessKey: secret,
  );
}

void main() {
  late _MockClient client;
  late AccessKeyRepo repo;

  setUpAll(() {
    registerFallbackValue(
      AccessKeyRequest(
        name: '',
        enabled: true,
        allBuckets: null,
        buckets: const [],
        expiresAt: null,
      ),
    );
  });

  setUp(() {
    client = _MockClient();
    repo = AccessKeyRepo(client);
  });

  group('Response → model', () {
    test('Maps grants, levels and the root id', () async {
      when(() => client.listKeys(token: any(named: 'token'))).thenAnswer(
        (_) async => AccessKeyListResponse(
          rootAccessKeyId: 'root',
          keys: [
            _response(
              buckets: [
                AccessKeyGrantDto(bucket: 'backups', access: 'readWrite'),
                AccessKeyGrantDto(bucket: 'media', access: 'readOnly'),
              ],
            ),
            _response(id: 'FIOKBBBB', allBuckets: 'writeOnly'),
          ],
        ),
      );

      final list = await repo.listKeys(token: 'jwt');

      expect(list.rootAccessKeyId, 'root');
      final first = list.keys.first;
      expect(first.allBuckets, isNull);
      expect(first.grants.map((g) => (g.bucket, g.access)), [
        ('backups', AccessKeyLevel.readWrite),
        ('media', AccessKeyLevel.readOnly),
      ]);
      expect(first.status, AccessKeyStatus.active);
      expect(first.secret, isNull);
      expect(list.keys.last.allBuckets, AccessKeyLevel.writeOnly);
      verify(() => client.listKeys(token: 'jwt')).called(1);
    });

    test('Keeps the secret of a just created key', () async {
      when(
        () => client.createKey(
          request: any(named: 'request'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => _response(secret: 's3cr3t'));

      final key = await repo.createKey(
        draft: const AccessKeyDraft(
          name: 'Backups NAS',
          enabled: true,
          allBuckets: AccessKeyLevel.readOnly,
          grants: [],
          expiresAt: null,
        ),
      );

      expect(key.secret, 's3cr3t');
    });
  });

  group('Draft → request', () {
    test('Every bucket: all_buckets and no grants', () async {
      when(
        () => client.createKey(
          request: any(named: 'request'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => _response());

      await repo.createKey(
        draft: const AccessKeyDraft(
          name: 'CI',
          enabled: true,
          allBuckets: AccessKeyLevel.readWrite,
          grants: [],
          expiresAt: null,
        ),
      );

      final request =
          verify(
                () => client.createKey(
                  request: captureAny(named: 'request'),
                  token: any(named: 'token'),
                ),
              ).captured.single
              as AccessKeyRequest;
      expect(request.toJson(), {
        'name': 'CI',
        'enabled': true,
        'all_buckets': 'readWrite',
        'buckets': <Map<String, dynamic>>[],
        'expires_at': null,
      });
    });

    test('Some buckets, with the expiry in UTC', () async {
      when(
        () => client.updateKey(
          id: any(named: 'id'),
          request: any(named: 'request'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => _response());

      await repo.updateKey(
        id: 'FIOKAAAA',
        draft: AccessKeyDraft(
          name: 'Web',
          enabled: false,
          allBuckets: null,
          grants: const [
            AccessKeyGrantModel(
              bucket: 'media',
              access: AccessKeyLevel.readOnly,
            ),
          ],
          expiresAt: DateTime.utc(2027, 1, 1),
        ),
      );

      final request =
          verify(
                () => client.updateKey(
                  id: 'FIOKAAAA',
                  request: captureAny(named: 'request'),
                  token: any(named: 'token'),
                ),
              ).captured.single
              as AccessKeyRequest;
      expect(request.toJson(), {
        'name': 'Web',
        'enabled': false,
        'all_buckets': null,
        'buckets': [
          {'bucket': 'media', 'access': 'readOnly'},
        ],
        'expires_at': '2027-01-01T00:00:00.000Z',
      });
    });
  });

  test('An API error arrives with the service message', () async {
    final options = RequestOptions(path: '/access-keys/FIOKAAAA');
    when(
      () => client.deleteKey(
        id: any(named: 'id'),
        token: any(named: 'token'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 404,
          data: {'code': 'NotFound', 'message': 'Access key not found'},
        ),
      ),
    );

    expect(
      () => repo.deleteKey(id: 'FIOKAAAA'),
      throwsA(
        isA<GlobalException>().having(
          (e) => e.message,
          'message',
          'Access key not found',
        ),
      ),
    );
  });
}
