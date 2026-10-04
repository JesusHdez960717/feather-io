import 'package:service/feather.dart';

/// Body to create or update an access key. The scope is either `all_buckets`
/// (a level) or `buckets` (at least one bucket with its level), never both.
/// `enabled` is only read on update.
class AccessKeyRequest implements Validatable {
  static const int maxNameLength = 64;

  final String? name;
  final bool? enabled;
  final String? allBuckets;
  final List<Map<String, dynamic>>? buckets;
  final String? expiresAt;

  AccessKeyRequest({
    this.name,
    this.enabled,
    this.allBuckets,
    this.buckets,
    this.expiresAt,
  });

  factory AccessKeyRequest.fromJson(Map<String, dynamic> json) {
    final buckets = json['buckets'];
    return AccessKeyRequest(
      name: json['name'] as String?,
      enabled: json['enabled'] as bool?,
      allBuckets: json['all_buckets'] as String?,
      buckets: buckets is List
          ? [for (final item in buckets) _asMap(item)]
          : null,
      expiresAt: json['expires_at'] as String?,
    );
  }

  static Map<String, dynamic> _asMap(Object? item) =>
      item is Map<String, dynamic> ? item : const {};

  @override
  ConstraintValidatorContext validate() {
    final cvc = ConstraintValidatorContext();

    cvc
        .buildValidator('name')
        .notNull()
        .size(min: 1, max: maxNameLength)
        .validate(name?.trim());

    if (allBuckets != null) {
      cvc
          .buildValidator('all_buckets')
          .isEnum(AccessKeyLevel.values)
          .validate(allBuckets);
    }

    cvc.buildValidator('buckets')
      ..addRule((_) {
        final hasBuckets = buckets != null && buckets!.isNotEmpty;
        if (allBuckets == null && !hasBuckets) {
          return 'Give the key all_buckets or at least one bucket';
        }
        if (allBuckets != null && hasBuckets) {
          return 'Use all_buckets or buckets, not both';
        }
        return null;
      })
      ..addRule((_) {
        final names = [for (final item in buckets ?? const []) item['bucket']];
        return names.toSet().length != names.length
            ? 'Each bucket can only appear once'
            : null;
      })
      ..validate(buckets);

    final items = buckets ?? const [];
    for (var i = 0; i < items.length; i++) {
      final bucket = items[i]['bucket'];
      cvc.buildValidator('buckets[$i].bucket')
        ..addRule(
          (value) => value is String && S3Validator.isValidBucketName(value)
              ? null
              : 'Not a valid bucket name',
        )
        ..validate(bucket);
      cvc
          .buildValidator('buckets[$i].access')
          .notNull()
          .isEnum(AccessKeyLevel.values)
          .validate(items[i]['access']);
    }

    cvc.buildValidator('expires_at')
      ..addRule(
        (value) => value == null || DateTime.tryParse(value as String) != null
            ? null
            : 'Not a valid ISO 8601 date',
      )
      ..validate(expiresAt);

    return cvc;
  }

  AccessKeyLevel? get allBucketsLevel =>
      allBuckets == null ? null : AccessKeyLevel.values.byName(allBuckets!);

  List<AccessKeyGrant> get grants => [
    for (final item in buckets ?? const [])
      AccessKeyGrant(
        item['bucket'] as String,
        AccessKeyLevel.values.byName(item['access'] as String),
      ),
  ];

  DateTime? get expiresAtDate =>
      expiresAt == null ? null : DateTime.parse(expiresAt!);
}
