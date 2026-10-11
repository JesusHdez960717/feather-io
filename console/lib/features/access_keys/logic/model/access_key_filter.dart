import 'package:console/app_exporter.dart';

/// Filters of the *Access keys* list, over the keys already loaded. Within a
/// group one option is enough; between groups all of them must hold
class AccessKeyFilter {
  static const AccessKeyFilter none = AccessKeyFilter();

  final Set<AccessKeyStatus> statuses;
  final Set<AccessKeyLevel> levels;

  /// Bucket names: a key matches if it reaches one (a key on every bucket
  /// reaches all of them)
  final Set<String> buckets;

  const AccessKeyFilter({
    this.statuses = const {},
    this.levels = const {},
    this.buckets = const {},
  });

  int get activeCount => statuses.length + levels.length + buckets.length;

  bool get isActive => activeCount > 0;

  bool matches(AccessKeyModel key) {
    if (statuses.isNotEmpty && !statuses.contains(key.status)) return false;
    if (levels.isNotEmpty) {
      final keyLevels = {
        ?key.allBuckets,
        for (final grant in key.grants) grant.access,
      };
      if (!keyLevels.any(levels.contains)) return false;
    }
    if (buckets.isNotEmpty &&
        key.allBuckets == null &&
        !key.grants.any((grant) => buckets.contains(grant.bucket))) {
      return false;
    }
    return true;
  }

  AccessKeyFilter copyWith({
    Set<AccessKeyStatus>? statuses,
    Set<AccessKeyLevel>? levels,
    Set<String>? buckets,
  }) {
    return AccessKeyFilter(
      statuses: statuses ?? this.statuses,
      levels: levels ?? this.levels,
      buckets: buckets ?? this.buckets,
    );
  }
}
