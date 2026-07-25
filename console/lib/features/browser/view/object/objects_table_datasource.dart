import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'objects_subscreen.dart';

class ObjectsTableDatasource extends StatefulWidget {
  final BrowserSearchState state;
  final List<BrowserObjectWrapper> filteredWrappers;
  final TextEditingController searchController;
  final Function(String prefix) onNavigate;
  final Function(BrowserObjectModel) onSelected;

  const ObjectsTableDatasource({
    required this.state,
    required this.filteredWrappers,
    required this.searchController,
    required this.onNavigate,
    required this.onSelected,
    super.key,
  });

  @override
  State<ObjectsTableDatasource> createState() => _ObjectsTableDatasourceState();
}

class _ObjectsTableDatasourceState extends State<ObjectsTableDatasource> {
  Map<String, double?> columnWidths = {
    'name': null,
    'size': null,
    'last_modified': null,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        final nameWidth = totalWidth * 0.5;
        final sizeWidth = totalWidth * 0.2;
        final lastModifiedWidth = (totalWidth - (nameWidth + sizeWidth)).clamp(
          150.0,
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

        if (widget.filteredWrappers.isEmpty && widget.state is BrowserSearchOkState) {
          return NoDataPage(
            title: widget.searchController.text.isEmpty
                ? 'No objects found'
                : 'No objects matching "${widget.searchController.text}"',
          );
        }

        _ObjectsDataSource dataSource = _ObjectsDataSource(
          wrappers: widget.filteredWrappers,
        );

        return SfDataGrid(
          source: dataSource,
          headerRowHeight: 42,
          rowHeight: 42,
          selectionMode: SelectionMode.single,
          navigationMode: GridNavigationMode.row,
          onCellTap: (details) {
            if (details.rowColumnIndex.rowIndex > 0) {
              final wrapper =
                  widget.filteredWrappers[details.rowColumnIndex.rowIndex - 1];
              if (wrapper.isFolder) {
                widget.onNavigate(wrapper.fullPath);
              } else {
                final obj = widget.state.objects!.objects.firstWhere(
                  (o) => o.key == wrapper.fullPath,
                );
                widget.onSelected(obj);
              }
            }
          },
          allowColumnsResizing: true,
          onColumnResizeUpdate: (details) {
            setState(() {
              columnWidths[details.column.columnName] = details.width;

              final sum = columnWidths.values.fold(
                0.0,
                (previousValue, element) => previousValue + (element ?? 0),
              );

              final dif = totalWidth - sum;
              if (columnWidths['last_modified'] == null) {
                columnWidths['last_modified'] = lastModifiedWidth + dif;
              } else {
                columnWidths['last_modified'] =
                    columnWidths['last_modified']! + dif;
              }
            });
            return true;
          },
          columns: [
            GridColumn(
              columnName: 'name',
              width: columnWidths['name'] ?? nameWidth,
              minimumWidth: 150,
              label: header('Name'),
            ),
            GridColumn(
              columnName: 'size',
              width: columnWidths['size'] ?? sizeWidth,
              minimumWidth: 100,
              label: header('Size'),
            ),
            GridColumn(
              columnName: 'last_modified',
              width: columnWidths['last_modified'] ?? lastModifiedWidth,
              minimumWidth: 150,
              label: header('Last Modified'),
            ),
          ],
        );
      },
    );
  }
}

class _ObjectsDataSource extends DataGridSource {
  final List<BrowserObjectWrapper> wrappers;

  _ObjectsDataSource({required this.wrappers}) {
    _rows = wrappers.map(_buildRow).toList();
  }

  late final List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        final bool isName = cell.columnName == 'name';
        final wrapper = cell.value is BrowserObjectWrapper
            ? cell.value as BrowserObjectWrapper
            : null;

        if (isName && wrapper != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  wrapper.isFolder ? Icons.folder : Icons.insert_drive_file,
                  size: 18,
                  color: wrapper.isFolder ? Colors.amber : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wrapper.name,
                    style: app.textTheme.bodyMedium?.copyWith(
                      color: app.colors.neutral.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
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
      }).toList(),
    );
  }

  DataGridRow _buildRow(BrowserObjectWrapper wrapper) {
    return DataGridRow(
      cells: [
        DataGridCell<BrowserObjectWrapper>(columnName: 'name', value: wrapper),
        DataGridCell<String>(
          columnName: 'size',
          value: wrapper.isFolder
              ? '-'
              : app.storageFormatter.formatSize(wrapper.size!),
        ),
        DataGridCell<String>(
          columnName: 'last_modified',
          value: wrapper.lastModified != null
              ? app.dateFormatter.l.format(wrapper.lastModified!)
              : '-',
        ),
      ],
    );
  }
}
