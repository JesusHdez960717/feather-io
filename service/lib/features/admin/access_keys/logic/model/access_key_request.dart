import 'package:service/feather.dart';

/// Body to create or update an access key. The scope is either `all_buckets`
/// (a level) or `buckets` (at least one bucket with its level), never both.
/// `enabled` is only read on update.
class AccessKeyRequest implements Validatable {
  static const int maxNameLength = 64;

  final String? name;
  final bool? enabled;
  final String? allBuckets;
  final List<AccessKeyGrantRequest>? buckets;
  final String? expiresAt;

  AccessKeyRequest({
    this.name,
    this.enabled,
    this.allBuckets,
    this.buckets,
    this.expiresAt,
  });

  /// The example of the OpenAPI document.
  static final AccessKeyRequest example = AccessKeyRequest(
    name: 'Backups',
    enabled: true,
    buckets: [
      AccessKeyGrantRequest(
        bucket: 'backups',
        access: AccessKeyLevel.readWrite.name,
      ),
    ],
    expiresAt: '2027-01-01T00:00:00.000Z',
  );

  factory AccessKeyRequest.fromJson(Map<String, dynamic> json) {
    return AccessKeyRequest(
      name: json.field<String?>('name'),
      enabled: json.field<bool?>('enabled'),
      allBuckets: json.field<String?>('all_buckets'),
      buckets: json.field<List<AccessKeyGrantRequest>?>('buckets'),
      expiresAt: json.field<String?>('expires_at'),
    );
  }

  @override
  ConstraintValidatorContext validate() => ConstraintValidatorContext()
    ..field('name', name?.trim()).notNull().size(min: 1, max: maxNameLength)
    ..field('all_buckets', allBuckets).isEnum(AccessKeyLevel.values)
    ..field('buckets', buckets)
        .custom((buckets) {
          final hasBuckets = buckets != null && buckets.isNotEmpty;
          if (allBuckets == null && !hasBuckets) {
            return intl.errors.validations.accessKeyNoScope;
          }
          if (allBuckets != null && hasBuckets) {
            return intl.errors.validations.accessKeyBothScopes;
          }
          return null;
        })
        .custom((buckets) {
          final names = [for (final item in buckets ?? const []) item?.bucket];
          return names.toSet().length != names.length
              ? intl.errors.validations.accessKeyRepeatedBucket
              : null;
        })
        .validEach()
    ..field('expires_at', expiresAt).custom(
      (value) => value == null || DateTime.tryParse(value) != null
          ? null
          : intl.errors.validations.isoDate,
    );

  AccessKeyLevel? get allBucketsLevel =>
      allBuckets == null ? null : AccessKeyLevel.values.byName(allBuckets!);

  List<AccessKeyGrant> get grants => [
    for (final item in buckets ?? const <AccessKeyGrantRequest>[])
      item.toGrant(),
  ];

  DateTime? get expiresAtDate =>
      expiresAt == null ? null : DateTime.parse(expiresAt!);

  Map<String, Object?> toJson() => {
    'name': name,
    'enabled': enabled,
    'all_buckets': allBuckets,
    'buckets': buckets,
    'expires_at': expiresAt,
  };
}

/// A bucket of [AccessKeyRequest.buckets] with the key's level on it.
class AccessKeyGrantRequest implements Validatable {
  final String? bucket;
  final String? access;

  AccessKeyGrantRequest({this.bucket, this.access});

  factory AccessKeyGrantRequest.fromJson(Map<String, dynamic> json) {
    return AccessKeyGrantRequest(
      bucket: json.field<String?>('bucket'),
      access: json.field<String?>('access'),
    );
  }

  @override
  ConstraintValidatorContext validate() => ConstraintValidatorContext()
    ..field('bucket', bucket).custom(
      (value) => value != null && S3Validator.isValidBucketName(value)
          ? null
          : intl.errors.validations.bucketName,
    )
    ..field('access', access).notNull().isEnum(AccessKeyLevel.values);

  AccessKeyGrant toGrant() =>
      AccessKeyGrant(bucket!, AccessKeyLevel.values.byName(access!));

  Map<String, Object?> toJson() => {'bucket': bucket, 'access': access};
}
