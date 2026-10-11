import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// *Danger zone* tab of a bucket's details: empty it and delete it.
/// As in S3, only an empty bucket can be deleted
class BucketDangerTab extends StatelessWidget {
  final BucketModel bucket;
  final VoidCallback onEmpty;
  final VoidCallback onDelete;

  const BucketDangerTab({
    required this.bucket,
    required this.onEmpty,
    required this.onDelete,
    super.key,
  });

  bool get _isEmpty => bucket.objectCount == 0;

  @override
  Widget build(BuildContext context) {
    final size = app.storageFormatter.formatSize(bucket.sizeBytes);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DangerCard(
            title: app.intl.bucketEmptyTitle,
            description: _isEmpty
                ? app.intl.bucketEmptyAlreadyEmpty
                : app.intl.bucketEmptyDescription(bucket.objectCount, size),
            action: app.intl.bucketEmptyTitle,
            onPressed: _isEmpty ? null : onEmpty,
          ),
          app.dimensions.padding.l.gap(),
          _DangerCard(
            title: app.intl.bucketsDeleteTitle,
            description: app.intl.bucketDeleteDescription,
            warning: _isEmpty
                ? null
                : app.intl.bucketDeleteNotEmpty(bucket.objectCount),
            action: app.intl.bucketsDeleteTitle,
            onPressed: _isEmpty ? onDelete : null,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final String title;
  final String description;
  final String? warning;
  final String action;
  final VoidCallback? onPressed;

  /// Button filled in red (delete) instead of only outlined (empty)
  final bool filled;

  const _DangerCard({
    required this.title,
    required this.description,
    required this.action,
    required this.onPressed,
    this.warning,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final error = app.colors.primary.error;
    return Container(
      padding: EdgeInsets.all(app.dimensions.padding.xl),
      decoration: BoxDecoration(
        color: app.colors.primary.background2,
        borderRadius: app.dimensions.border.borderRadius.m,
        border: Border.all(color: error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: app.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                app.dimensions.padding.xs.gap(),
                Text(
                  description,
                  style: app.textTheme.bodyMedium?.copyWith(
                    color: app.colors.neutral.grey3,
                  ),
                ),
                if (warning != null) ...[
                  app.dimensions.padding.s.gap(),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: app.colors.primary.secondary,
                      ),
                      app.dimensions.padding.xs.gap(),
                      Expanded(
                        child: Text(
                          warning!,
                          style: app.textTheme.bodySmall?.copyWith(
                            color: app.colors.primary.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          app.dimensions.padding.xl.gap(),
          SizedBox(
            width: 170,
            height: 42,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: filled ? app.colors.neutral.white : error,
                backgroundColor: filled && enabled
                    ? app.colors.primary.errorAction
                    : app.colors.neutral.transparent,
                disabledForegroundColor: app.colors.neutral.grey4,
                disabledBackgroundColor: app.colors.primary.background3,
                side: BorderSide(
                  color: enabled
                      ? (filled ? app.colors.primary.errorAction : error)
                      : app.colors.neutral.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: app.dimensions.border.borderRadius.s,
                ),
              ),
              child: Text(action),
            ),
          ),
        ],
      ),
    );
  }
}
