import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';

/// An access key with sensible defaults; each test changes only what it checks
AccessKeyModel accessKey({
  String id = 'FIOKAAAAAAAAAAAAAAAA',
  String name = 'Key',
  bool enabled = true,
  bool expired = false,
  AccessKeyLevel? allBuckets,
  List<AccessKeyGrantModel> grants = const [],
  DateTime? expiresAt,
  DateTime? lastUsedAt,
  String? secret,
}) {
  return AccessKeyModel(
    id: id,
    name: name,
    enabled: enabled,
    expired: expired,
    allBuckets: allBuckets,
    grants: grants,
    expiresAt: expiresAt,
    createdAt: DateTime(2026, 10, 1),
    lastUsedAt: lastUsedAt,
    secret: secret,
  );
}

AccessKeyGrantModel grant(String bucket, AccessKeyLevel access) =>
    AccessKeyGrantModel(bucket: bucket, access: access);

/// A bucket with sensible defaults
BucketModel bucket(String name, {int objectCount = 0, int sizeBytes = 0}) =>
    BucketModel(
      name: name,
      objectCount: objectCount,
      sizeBytes: sizeBytes,
      creationDate: DateTime(2026, 10, 1),
    );

/// The session every cubit reads its token from
AuthModel session() => AuthModel(accessToken: 'jwt', expireAt: DateTime(2100));

/// An error as the repos throw it (already converted)
GlobalException apiError([String message = 'boom']) =>
    GlobalException(type: GlobalExceptionType.general, message: message);

/// What Dio throws for an error response of the service
DioException httpError(int status, Object? data) {
  final options = RequestOptions(path: '/');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

/// Lets the listeners of the global bus run
Future<void> busDelivered() => Future<void>.delayed(Duration.zero);
