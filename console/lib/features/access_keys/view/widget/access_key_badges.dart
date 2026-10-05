import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// Small rounded tag
class AccessKeyPill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const AccessKeyPill({
    required this.text,
    required this.background,
    required this.foreground,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: app.textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Whether S3 clients can use the key: active, disabled or expired
class AccessKeyStatusBadge extends StatelessWidget {
  final AccessKeyStatus status;

  const AccessKeyStatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      AccessKeyStatus.active => (
        app.intl.accessKeyStatusActive,
        app.colors.palette.green,
      ),
      AccessKeyStatus.disabled => (
        app.intl.accessKeyStatusDisabled,
        app.colors.neutral.grey4,
      ),
      AccessKeyStatus.expired => (
        app.intl.accessKeyStatusExpired,
        app.colors.primary.error,
      ),
    };
    return AccessKeyPill(
      text: text,
      background: color.withValues(alpha: 0.22),
      foreground: Color.lerp(color, app.colors.neutral.white, 0.45)!,
    );
  }
}

/// The scope of a key: one tag per bucket with its level, or "All" with the
/// level and, with write access, that it can create buckets
class AccessKeyPermissions extends StatelessWidget {
  final AccessKeyModel keyModel;

  const AccessKeyPermissions({required this.keyModel, super.key});

  @override
  Widget build(BuildContext context) {
    final all = keyModel.allBuckets;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (all != null) ...[
          _GrantTag(scope: app.intl.accessKeyAllBuckets, level: all),
          if (all != AccessKeyLevel.readOnly)
            Text(
              app.intl.accessKeyCreatesBuckets,
              style: app.textTheme.bodySmall?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
        ] else if (keyModel.grants.isEmpty)
          // Its buckets were deleted: the key reaches nothing until edited
          Text(
            app.intl.accessKeyNoBuckets,
            style: app.textTheme.bodySmall?.copyWith(
              color: app.colors.neutral.grey3,
            ),
          )
        else
          for (final grant in keyModel.grants)
            _GrantTag(scope: grant.bucket, level: grant.access),
      ],
    );
  }
}

class _GrantTag extends StatelessWidget {
  final String scope;
  final AccessKeyLevel level;

  const _GrantTag({required this.scope, required this.level});

  @override
  Widget build(BuildContext context) {
    final color = level.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 10, 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: app.colors.neutral.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(scope, style: app.textTheme.bodySmall),
          ),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: app.textTheme.bodySmall?.copyWith(
              color: Color.lerp(color, app.colors.neutral.white, 0.45),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

extension AccessKeyLevelView on AccessKeyLevel {
  String get label => switch (this) {
    AccessKeyLevel.readOnly => app.intl.accessKeyLevelReadOnly,
    AccessKeyLevel.writeOnly => app.intl.accessKeyLevelWriteOnly,
    AccessKeyLevel.readWrite => app.intl.accessKeyLevelReadWrite,
  };

  /// For the per-bucket selector
  String get shortLabel => switch (this) {
    AccessKeyLevel.readOnly => app.intl.accessKeyLevelShortRead,
    AccessKeyLevel.writeOnly => app.intl.accessKeyLevelShortWrite,
    AccessKeyLevel.readWrite => app.intl.accessKeyLevelShortBoth,
  };

  String get description => switch (this) {
    AccessKeyLevel.readOnly => app.intl.accessKeyLevelReadOnlyDescription,
    AccessKeyLevel.writeOnly => app.intl.accessKeyLevelWriteOnlyDescription,
    AccessKeyLevel.readWrite => app.intl.accessKeyLevelReadWriteDescription,
  };

  Color get color => switch (this) {
    AccessKeyLevel.readOnly => app.colors.palette.blue,
    AccessKeyLevel.writeOnly => app.colors.palette.amber,
    AccessKeyLevel.readWrite => app.colors.primary.primaryFaded,
  };
}

extension AccessKeyModelView on AccessKeyModel {
  /// "Never", "Just now", "5 min ago", "2 h ago", "3 days ago" or the date
  String get lastUsedLabel {
    final used = lastUsedAt;
    if (used == null) return app.intl.accessKeyNeverUsed;
    final elapsed = DateTime.now().difference(used);
    if (elapsed.inMinutes < 1) return app.intl.accessKeyUsedNow;
    if (elapsed.inHours < 1) {
      return app.intl.accessKeyUsedMinutes(elapsed.inMinutes);
    }
    if (elapsed.inDays < 1) return app.intl.accessKeyUsedHours(elapsed.inHours);
    if (elapsed.inDays <= 30) return app.intl.accessKeyUsedDays(elapsed.inDays);
    return app.dateFormatter.m.format(used);
  }
}
