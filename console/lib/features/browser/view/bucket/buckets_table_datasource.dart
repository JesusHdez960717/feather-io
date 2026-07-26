import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class BucketsTableDatasource extends StatefulWidget {
  final BrowserState state;
  final TextEditingController searchController;
  final List<BucketModel> filteredBuckets;
  final Function(BucketModel) onSelected;

  const BucketsTableDatasource({
    required this.state,
    required this.searchController,
    required this.filteredBuckets,
    required this.onSelected,
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
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        final nameWidth = totalWidth * 0.4;
        final objectsWidth = totalWidth * 0.15;
        final sizeWidth = totalWidth * 0.2;
        final createdAtWidth =
            (totalWidth - (nameWidth + objectsWidth + sizeWidth)).clamp(
              130.0,
              totalWidth,
            );

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
            widget.state is BrowserSearchOkState) {
          return NoDataPage(
            title: widget.searchController.text.isEmpty
                ? 'No buckets found'
                : 'No buckets matching "${widget.searchController.text}"',
          );
        }

        _BucketsDataSource dataSource = _BucketsDataSource(
          buckets: widget.filteredBuckets,
          onRowTap: widget.onSelected,
        );

        return SfDataGrid(
          source: dataSource,
          headerRowHeight: 42,
          rowHeight: 42,
          selectionMode: SelectionMode.single,
          navigationMode: GridNavigationMode.row,
          allowColumnsResizing: true,
          onColumnResizeUpdate: (details) {
            setState(() {
              columnWidths[details.column.columnName] = details.width;

              // Si redimensionamos cualquier columna que NO sea last_modified,
              // ajustamos last_modified para que la tabla no se achique.
              final othersWidth =
                  (columnWidths['name'] ?? nameWidth) +
                  (columnWidths['objects'] ?? objectsWidth) +
                  (columnWidths['size'] ?? sizeWidth);

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
              label: header('Name'),
            ),
            GridColumn(
              columnName: 'objects',
              width: columnWidths['objects'] ?? objectsWidth,
              minimumWidth: 100,
              label: header('Objects'),
            ),
            GridColumn(
              columnName: 'size',
              width: columnWidths['size'] ?? sizeWidth,
              minimumWidth: 100,
              label: header('Size'),
            ),
            GridColumn(
              columnName: 'created_at',
              width: columnWidths['created_at'] ?? createdAtWidth,
              minimumWidth: 150,
              label: header('Created At'),
            ),
          ],
        );
      },
    );
  }
}

class _BucketsDataSource extends DataGridSource {
  final List<BucketModel> buckets;
  final void Function(BucketModel bucket) onRowTap;

  _BucketsDataSource({required this.buckets, required this.onRowTap}) {
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
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onRowTap(bucket),
            child: Padding(
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
            ),
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
      ],
    );
  }
}
