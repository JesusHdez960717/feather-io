import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class BucketsGridDatasource extends StatelessWidget {
  final BrowserState state;
  final TextEditingController searchController;
  final List<BucketModel> filteredBuckets;
  final Function(BucketModel) onSelected;
  final int crossAxisCount;

  const BucketsGridDatasource({
    required this.state,
    required this.searchController,
    required this.filteredBuckets,
    required this.onSelected,
    this.crossAxisCount = 3,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredBuckets.isEmpty && state is BrowserSearchOkState) {
      return NoDataPage(
        title: searchController.text.isEmpty
            ? 'No buckets found'
            : 'No buckets matching "${searchController.text}"',
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: app.colors.neutral.grey5),
          right: BorderSide(color: app.colors.neutral.grey5),
          bottom: BorderSide(color: app.colors.neutral.grey5),
        ),
      ),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          mainAxisExtent: 220,
        ),
        itemCount: filteredBuckets.length,
        itemBuilder: (context, index) {
          final bucket = filteredBuckets[index];
          return _BucketGridItem(
            bucket: bucket,
            onTap: () => onSelected(bucket),
          );
        },
      ),
    );
  }
}

class _BucketGridItem extends StatelessWidget {
  final BucketModel bucket;
  final VoidCallback onTap;

  const _BucketGridItem({required this.bucket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(app.dimensions.padding.xl),
        decoration: BoxDecoration(
          color: app.colors.primary.background2,
          border: Border.all(color: app.colors.neutral.grey5, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: .center,
          mainAxisAlignment: .spaceBetween,
          children: [
            Row(
              crossAxisAlignment: .center,
              children: [
                Container(
                  padding: EdgeInsets.all(app.dimensions.padding.m),
                  decoration: BoxDecoration(
                    color: app.colors.primary.purple.withValues(alpha: 0.1),
                    borderRadius: app.dimensions.border.borderRadius.s,
                  ),
                  child: app.assets.icons.storage.bucket.build(
                    size: 30,
                    color: app.colors.neutral.white,
                  ),
                ),
                app.dimensions.padding.m.gap(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          Text(
                            bucket.name,
                            style: app.textTheme.titleLarge?.copyWith(
                              color: app.colors.neutral.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          app.dimensions.padding.m.gap(),
                          Tooltip(
                            message:
                                'En este bucket se tiene acceso de Lectura y Escritura',
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: app.dimensions.padding.xs,
                              ),
                              decoration: BoxDecoration(
                                color: app.colors.neutral.grey4,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(2.5),
                                ),
                              ),
                              child: Text(
                                'R/W',
                                style: app.textTheme.bodyMedium?.copyWith(
                                  color: app.colors.neutral.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Created ${app.dateFormatter.l.format(bucket.creationDate)}',
                        style: app.textTheme.labelMedium?.copyWith(
                          color: app.colors.neutral.white,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  label: 'Objects',
                  value: bucket.objectCount.toString(),
                ),
                _buildInfoItem(
                  label: 'Size',
                  value: app.storageFormatter.formatSize(bucket.sizeBytes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: app.textTheme.bodyMedium?.copyWith(
            color: app.colors.neutral.grey2,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: app.textTheme.bodyLarge?.copyWith(
            color: app.colors.neutral.white,
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}
