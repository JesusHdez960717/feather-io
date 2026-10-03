import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class BucketsTableDatasource extends StatefulWidget {
  final BucketState state;
  final TextEditingController searchController;
  final List<BucketModel> filteredBuckets;
  final Function(BucketModel) onSelected;
  final Function(BucketModel bucket, RenderBox box) onShowOptions;

  const BucketsTableDatasource({
    required this.state,
    required this.searchController,
    required this.filteredBuckets,
    required this.onSelected,
    required this.onShowOptions,
    super.key,
  });

  @override
  State<BucketsTableDatasource> createState() => _BucketsTableDatasourceState();
}

class _BucketsTableDatasourceState extends State<BucketsTableDatasource> {
  Map<String, double?> columnWidths = {
    'name': null,
    'objects': null,
    'size': null,
    'created_at': null,
    'actions': null,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        final nameWidth = totalWidth * 0.4;
        final objectsWidth = totalWidth * 0.15;
        final sizeWidth = totalWidth * 0.2;
        final actionsWidth = 50.0;

        final createdAtWidth =
            (totalWidth - (nameWidth + objectsWidth + sizeWidth + actionsWidth))
                .clamp(130.0, totalWidth);

        Widget header(String text) {
          return Padding(
            padding: EdgeInsets.all(app.dimensions.padding.s),
            child: Text(
              text,
              style: app.textTheme.bodyLarge!.copyWith(
                color: app.colors.neutral.grey3,
              ),
            ),
          );
        }

        if (widget.filteredBuckets.isEmpty &&
            widget.state is BucketLoadingSuccessState) {
          return NoDataPage(
            title: widget.searchController.text.isEmpty
                ? app.intl.bucketsEmpty
                : app.intl.bucketsNoMatch(widget.searchController.text),
          );
        }

        _BucketsDataSource dataSource = _BucketsDataSource(
          buckets: widget.filteredBuckets,
          onRowTap: widget.onSelected,
          onShowOptions: widget.onShowOptions,
        );

        return Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
              right: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
              bottom: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
            ),
          ),
          child: SfDataGrid(
            source: dataSource,
            headerRowHeight: 42,
            rowHeight: 42,
            selectionMode: SelectionMode.single,
            navigationMode: GridNavigationMode.row,
            allowColumnsResizing: true,
            onColumnResizeUpdate: (details) {
              setState(() {
                columnWidths[details.column.columnName] = details.width;

                // Resizing any column that is NOT last_modified adjusts
                // last_modified so the table doesn't shrink.
                final othersWidth =
                    (columnWidths['name'] ?? nameWidth) +
                    (columnWidths['objects'] ?? objectsWidth) +
                    (columnWidths['size'] ?? sizeWidth) +
                    (columnWidths['actions'] ?? actionsWidth);

                columnWidths['created_at'] = (totalWidth - othersWidth).clamp(
                  150.0,
                  totalWidth,
                );
              });
              return true;
            },
            columns: [
              GridColumn(
                columnName: 'bucket',
                width: 0,
                minimumWidth: 0,
                label: const SizedBox.shrink(),
              ),
              GridColumn(
                columnName: 'name',
                width: columnWidths['name'] ?? nameWidth,
                minimumWidth: 150,
                label: header(app.intl.name),
              ),
              GridColumn(
                columnName: 'objects',
                width: columnWidths['objects'] ?? objectsWidth,
                minimumWidth: 100,
                label: header(app.intl.objects),
              ),
              GridColumn(
                columnName: 'size',
                width: columnWidths['size'] ?? sizeWidth,
                minimumWidth: 100,
                label: header(app.intl.size),
              ),
              GridColumn(
                columnName: 'created_at',
                width: columnWidths['created_at'] ?? createdAtWidth,
                minimumWidth: 150,
                label: header(app.intl.createdAt),
              ),
              GridColumn(
                columnName: 'actions',
                width: actionsWidth,
                label: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BucketsDataSource extends DataGridSource {
  final List<BucketModel> buckets;
  final void Function(BucketModel bucket) onRowTap;
  final void Function(BucketModel bucket, RenderBox box) onShowOptions;

  final ValueNotifier<BucketModel?> hoveredBucket = ValueNotifier(null);

  _BucketsDataSource({
    required this.buckets,
    required this.onRowTap,
    required this.onShowOptions,
  }) {
    _rows = buckets.map(_buildRow).toList();
  }

  late final List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final bucket = row.getCells()[0].value as BucketModel;

    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        final bool isActions = cell.columnName == 'actions';

        Widget content;

        if (isActions) {
          content = ValueListenableBuilder<BucketModel?>(
            valueListenable: hoveredBucket,
            builder: (context, hovered, _) {
              final isHovered = hovered == bucket;
              return Opacity(
                opacity: isHovered ? 1.0 : 0.0,
                child: Center(
                  child: Builder(
                    builder: (context) {
                      return IconButton(
                        icon: app.assets.icons.actions.more.build(size: 18, color: app.colors.neutral.grey2),
                        onPressed: isHovered
                            ? () {
                                final RenderBox box =
                                    context.findRenderObject() as RenderBox;
                                onShowOptions(bucket, box);
                              }
                            : null,
                        padding: const EdgeInsets.all(4.0),
                        constraints: const BoxConstraints(),
                      );
                    },
                  ),
                ),
              );
            },
          );
        } else {
          content = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                cell.value.toString(),
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.white,
                ),
              ),
            ),
          );
        }

        return MouseRegion(
          onEnter: (_) => hoveredBucket.value = bucket,
          onExit: (_) => hoveredBucket.value = null,
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onRowTap(bucket),
            child: content,
          ),
        );
      }).toList(),
    );
  }

  DataGridRow _buildRow(BucketModel bucket) {
    return DataGridRow(
      cells: [
        DataGridCell<BucketModel>(columnName: 'bucket', value: bucket),
        DataGridCell<String>(columnName: 'name', value: bucket.name),
        DataGridCell<int>(columnName: 'objects', value: bucket.objectCount),
        DataGridCell<String>(
          columnName: 'size',
          value: app.storageFormatter.formatSize(bucket.sizeBytes),
        ),
        DataGridCell<String>(
          columnName: 'created_at',
          value: app.dateFormatter.l.format(bucket.creationDate),
        ),
        DataGridCell<BucketModel>(columnName: 'actions', value: bucket),
      ],
    );
  }
}
