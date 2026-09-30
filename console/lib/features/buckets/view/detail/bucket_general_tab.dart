import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

///Pestaña *General* del detalle de un bucket: estadisticas y metadatos
class BucketGeneralTab extends StatelessWidget {
  final BucketModel bucket;

  const BucketGeneralTab({required this.bucket, super.key});

  String get _s3Path => '${Environment.serviceUrl}/${bucket.name}';

  @override
  Widget build(BuildContext context) {
    final lastModified = bucket.lastModified;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _stat(app.intl.bucketDetailObjects, '${bucket.objectCount}'),
              app.dimensions.padding.l.gap(),
              _stat(
                app.intl.bucketDetailSize,
                app.storageFormatter.formatSize(bucket.sizeBytes),
              ),
              app.dimensions.padding.l.gap(),
              _stat(
                app.intl.bucketDetailCreated,
                app.dateFormatter.m.format(bucket.creationDate),
              ),
              app.dimensions.padding.l.gap(),
              _stat(
                app.intl.bucketDetailLastModified,
                lastModified == null
                    ? app.intl.bucketDetailNeverModified
                    : app.dateFormatter.m.format(lastModified),
              ),
            ],
          ),
          app.dimensions.padding.l.gap(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.l),
            decoration: _cardDecoration,
            child: Column(
              children: [
                _row(app.intl.bucketDetailName, Text(bucket.name)),
                _row(
                  app.intl.bucketDetailS3Path,
                  Row(
                    children: [
                      Flexible(child: _CodeChip(text: _s3Path)),
                      app.dimensions.padding.s.gap(),
                      IconButton(
                        tooltip: app.intl.bucketDetailCopyPath,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _s3Path));
                          app.snack.showSuccess(
                            message: app.intl.bucketDetailPathCopied,
                            context: context,
                          );
                        },
                        icon: app.assets.icons.actions.copy.build(
                          size: 16,
                          color: app.colors.neutral.grey3,
                        ),
                      ),
                    ],
                  ),
                ),
                _row(
                  app.intl.bucketDetailDescription,
                  Text(
                    bucket.description?.isNotEmpty == true
                        ? bucket.description!
                        : app.intl.bucketDetailNoDescription,
                    style: bucket.description?.isNotEmpty == true
                        ? null
                        : TextStyle(color: app.colors.neutral.grey4),
                  ),
                ),
                _row(
                  app.intl.bucketDetailColor,
                  bucket.uiColor == null
                      ? Text(
                          app.intl.colorNone,
                          style: TextStyle(color: app.colors.neutral.grey4),
                        )
                      : Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: bucket.uiColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            app.dimensions.padding.s.gap(),
                            Text(bucket.uiColor!.toHex()),
                          ],
                        ),
                  last: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: app.colors.primary.background2,
    borderRadius: app.dimensions.border.borderRadius.m,
    border: Border.all(color: app.colors.neutral.grey5),
  );

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(app.dimensions.padding.l),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: app.textTheme.bodyMedium?.copyWith(
                color: app.colors.neutral.grey2,
              ),
            ),
            app.dimensions.padding.xs.gap(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: app.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, Widget value, {bool last = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: app.colors.neutral.grey5.withValues(alpha: 0.5),
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: app.textTheme.bodyMedium?.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: app.textTheme.bodyMedium,
              child: value,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  final String text;

  const _CodeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: app.dimensions.padding.s,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: app.colors.primary.background3,
        borderRadius: app.dimensions.border.borderRadius.s,
      ),
      child: SelectableText(
        text,
        maxLines: 1,
        style: app.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}
