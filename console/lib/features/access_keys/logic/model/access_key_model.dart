/// What an access key may do on a bucket. The names are the ones the API
/// expects (`readOnly`, `writeOnly`, `readWrite`)
enum AccessKeyLevel { readOnly, writeOnly, readWrite }

/// Whether S3 clients can sign with a key right now
enum AccessKeyStatus { active, disabled, expired }

/// Level of a key on one bucket
class AccessKeyGrantModel {
  final String bucket;
  final AccessKeyLevel access;

  const AccessKeyGrantModel({required this.bucket, required this.access});
}

/// Access key for native S3 clients. It reaches every bucket with
/// [allBuckets], or only the buckets of [grants]
class AccessKeyModel {
  final String id;
  final String name;
  final bool enabled;
  final bool expired;
  final AccessKeyLevel? allBuckets;
  final List<AccessKeyGrantModel> grants;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  /// Only right after creating the key or regenerating its secret: the service
  /// never returns it again
  final String? secret;

  const AccessKeyModel({
    required this.id,
    required this.name,
    required this.enabled,
    required this.expired,
    required this.allBuckets,
    required this.grants,
    required this.expiresAt,
    required this.createdAt,
    required this.lastUsedAt,
    this.secret,
  });

  AccessKeyStatus get status => !enabled
      ? AccessKeyStatus.disabled
      : expired
      ? AccessKeyStatus.expired
      : AccessKeyStatus.active;
}

/// The managed keys plus the id of the root key (`FEATHER_ACCESS`), which
/// can't be edited or deleted and is the only one that opens the console
class AccessKeyListModel {
  final String rootAccessKeyId;
  final List<AccessKeyModel> keys;

  const AccessKeyListModel({required this.rootAccessKeyId, required this.keys});
}

/// What the create/edit drawer sends: the scope is [allBuckets] or [grants]
class AccessKeyDraft {
  final String name;
  final bool enabled;
  final AccessKeyLevel? allBuckets;
  final List<AccessKeyGrantModel> grants;
  final DateTime? expiresAt;

  const AccessKeyDraft({
    required this.name,
    required this.enabled,
    required this.allBuckets,
    required this.grants,
    required this.expiresAt,
  });

  /// The same key with [enabled] changed, for *Disable*/*Enable*
  factory AccessKeyDraft.of(AccessKeyModel key, {bool? enabled}) {
    return AccessKeyDraft(
      name: key.name,
      enabled: enabled ?? key.enabled,
      allBuckets: key.allBuckets,
      grants: key.grants,
      expiresAt: key.expiresAt,
    );
  }
}
