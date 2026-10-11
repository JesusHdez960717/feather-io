/// What an access key may do on a bucket (the same levels as the anonymous
/// rules).
enum AccessKeyLevel {
  readOnly,
  writeOnly,
  readWrite;

  bool get canRead => this != writeOnly;

  bool get canWrite => this != readOnly;
}

class AccessKeyGrant {
  final String bucket;
  final AccessKeyLevel access;

  AccessKeyGrant(this.bucket, this.access);

  Map<String, Object?> toJson() => {'bucket': bucket, 'access': access.name};
}

/// An access key for native S3 clients. It reaches every bucket with
/// [allBuckets], or only the buckets of [grants].
class AccessKeyModel {
  final String id;
  final String name;
  final bool enabled;
  final AccessKeyLevel? allBuckets;
  final List<AccessKeyGrant> grants;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  /// Only right after creating the key or regenerating its secret: it is never
  /// shown again.
  final String? secret;

  AccessKeyModel({
    required this.id,
    required this.name,
    required this.enabled,
    required this.allBuckets,
    required this.grants,
    required this.expiresAt,
    required this.createdAt,
    required this.lastUsedAt,
    this.secret,
  });

  /// The example of the OpenAPI document; [secret] only comes on create and
  /// on regenerating it.
  static final AccessKeyModel example = AccessKeyModel(
    id: 'FIOKA1B2C3D4E5F6G7H8',
    name: 'Backups',
    enabled: true,
    allBuckets: null,
    grants: [AccessKeyGrant('backups', AccessKeyLevel.readWrite)],
    expiresAt: DateTime.utc(2027),
    createdAt: DateTime.utc(2026, 10, 1, 8),
    lastUsedAt: DateTime.utc(2026, 10, 9, 7, 45),
    secret: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
  );

  bool get isExpired =>
      expiresAt != null && !DateTime.now().isBefore(expiresAt!);

  /// Enabled and not expired: S3 clients can sign with it.
  bool get isUsable => enabled && !isExpired;

  /// Its level on [bucket], or null when it can't reach it.
  AccessKeyLevel? levelOn(String bucket) {
    if (allBuckets != null) return allBuckets;
    for (final grant in grants) {
      if (grant.bucket == bucket) return grant.access;
    }
    return null;
  }

  bool canRead(String bucket) => levelOn(bucket)?.canRead ?? false;

  AccessKeyModel withSecret(String secret) => AccessKeyModel(
    id: id,
    name: name,
    enabled: enabled,
    allBuckets: allBuckets,
    grants: grants,
    expiresAt: expiresAt,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt,
    secret: secret,
  );

  AccessKeyModel withoutSecret() => AccessKeyModel(
    id: id,
    name: name,
    enabled: enabled,
    allBuckets: allBuckets,
    grants: grants,
    expiresAt: expiresAt,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt,
  );

  Map<String, Object?> toJson() {
    return {
      'access_key_id': id,
      'name': name,
      'enabled': enabled,
      'expired': isExpired,
      'all_buckets': allBuckets?.name,
      'buckets': grants,
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'last_used_at': lastUsedAt?.toUtc().toIso8601String(),
      if (secret != null) 'secret_access_key': secret,
    };
  }
}

/// The managed keys plus the id of the root key (`FEATHER_ACCESS`), which has
/// no row: it can't be edited or deleted.
class AccessKeyListModel {
  final String rootAccessKeyId;
  final List<AccessKeyModel> keys;

  AccessKeyListModel({required this.rootAccessKeyId, required this.keys});

  /// The example of the OpenAPI document.
  static final AccessKeyListModel example = AccessKeyListModel(
    rootAccessKeyId: 'feather-access',
    keys: [AccessKeyModel.example.withoutSecret()],
  );

  Map<String, Object?> toJson() => {
    'root_access_key_id': rootAccessKeyId,
    'keys': keys,
  };
}
