import 'package:console/app_exporter.dart';

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

/// An error as the repos throw it (already converted, so no `app.intl` needed)
GlobalException apiError([String message = 'boom']) =>
    GlobalException(type: GlobalExceptionType.general, message: message);
