import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ObjectsDataGrid extends StatefulWidget {
  final BrowserSearchState state;
  final Function(String prefix) onNavigate;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final Function(BrowserObjectModel) onSelected;

  const ObjectsDataGrid({
    required this.state,
    required this.onNavigate,
    required this.onRefresh,
    required this.onBack,
    required this.onSelected,
    super.key,
  });

  @override
  State<ObjectsDataGrid> createState() => _ObjectsDataGridState();
}

class _ObjectsDataGridState extends State<ObjectsDataGrid> {
  Map<String, double?> columnWidths = {
    'name': null,
    'size': null,
    'last_modified': null,
  };

  final TextEditingController _searchController = TextEditingController();
  List<BrowserObjectWrapper> _allWrappers = [];
  List<BrowserObjectWrapper> _filteredWrappers = [];

  @override
  void initState() {
    super.initState();
    _initializeWrappers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant ObjectsDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.objects != widget.state.objects ||
        oldWidget.state.prefix != widget.state.prefix) {
      _initializeWrappers();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _initializeWrappers() {
    final ListObjectsModel? objectsModel = widget.state.objects;
    _allWrappers = [];

    if (objectsModel != null) {
      for (final cp in objectsModel.commonPrefixes) {
        final name = cp.split('/').where((s) => s.isNotEmpty).last;
        _allWrappers.add(
          BrowserObjectWrapper(name: name, isFolder: true, fullPath: cp),
        );
      }
      for (final obj in objectsModel.objects) {
        final name = obj.key.split('/').last;
        if (name.isEmpty) continue;
        _allWrappers.add(
          BrowserObjectWrapper(
            name: name,
            isFolder: false,
            size: obj.sizeBytes,
            lastModified: obj.lastModified,
            fullPath: obj.key,
          ),
        );
      }
    }
    _onSearchChanged();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredWrappers = _allWrappers;
      } else {
        _filteredWrappers = _allWrappers
            .where((w) => w.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Widget _buildBreadcrumbs() {
    final bucketName = widget.state.selectedBucket?.name ?? '';
    final prefix = widget.state.prefix;
    final parts = prefix.split('/').where((s) => s.isNotEmpty).toList();

    List<Widget> children = [];

    Widget separator() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '/',
        style: app.textTheme.bodyMedium?.copyWith(
          color: app.colors.neutral.grey3,
        ),
      ),
    );

    Widget breadcrumbItem({
      required String label,
      required VoidCallback? onTap,
      required bool isLast,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: app.dimensions.border.borderRadius.s,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            label,
            style: app.textTheme.bodyMedium?.copyWith(
              color: isLast
                  ? app.colors.neutral.white
                  : app.colors.primary.purple,
              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              decoration: isLast ? null : TextDecoration.underline,
            ),
          ),
        ),
      );
    }

    children.add(separator());

    // Bucket name (root of object navigation)
    children.add(
      breadcrumbItem(
        label: bucketName,
        onTap: parts.isEmpty ? null : () => widget.onNavigate(''),
        isLast: parts.isEmpty,
      ),
    );

    String cumulativePath = '';
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      cumulativePath += '$part/';
      final isLast = i == parts.length - 1;
      final targetPath = cumulativePath;

      children.add(separator());
      children.add(
        breadcrumbItem(
          label: part,
          onTap: isLast ? null : () => widget.onNavigate(targetPath),
          isLast: isLast,
        ),
      );
    }

    return Container(
      height: 24,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.state.prefix;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: app.colors.primary.background2,
            borderRadius: BorderRadius.only(
              topLeft: app.dimensions.border.radius.m,
              topRight: app.dimensions.border.radius.m,
            ),
            border: Border.all(color: app.colors.neutral.grey5),
          ),
          child: Padding(
            padding: EdgeInsets.all(app.dimensions.padding.l),
            child: Row(
              children: [
                if (prefix.isNotEmpty)
                  PrimaryButton.secondary(
                    onPressed: widget.onBack,
                    title: 'Back',
                    h: 42,
                    icon: null,
                  ),
                if (prefix.isNotEmpty) app.dimensions.padding.m.gap(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumbs(),
                      app.dimensions.padding.xs.gap(),
                      EMTextSearchField(
                        controller: _searchController,
                        onSearch: (value) {},
                        hint: 'Search objects...',
                      ),
                    ],
                  ),
                ),
                app.dimensions.padding.l.gap(),
                PrimaryButton.secondary(
                  onPressed: () {
                    widget.onRefresh();
                  },
                  title: 'Refresh',
                  h: 42,
                  icon: app.assets.icons.actions.refresh,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: widget.state is! BrowserSearchOkState,
                      child: _buildDataGrid(constraints),
                    ),
                    if (widget.state is BrowserSearchingState)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                          child: Container(
                            color: app.colors.neutral.black.withValues(
                              alpha: 0.08,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: app.colors.primary.purple,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.state is BrowserSearchErrorState)
                      Positioned.fill(
                        child: ErrorPage(
                          message: (widget.state as BrowserSearchErrorState)
                              .exception
                              .message,
                          onRetry: widget.onRefresh,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataGrid(BoxConstraints constraints) {
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

    if (_filteredWrappers.isEmpty && widget.state is BrowserSearchOkState) {
      return NoDataPage(
        title: _searchController.text.isEmpty
            ? 'No objects found'
            : 'No objects matching "${_searchController.text}"',
      );
    }

    _ObjectsDataSource dataSource = _ObjectsDataSource(
      wrappers: _filteredWrappers,
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
              _filteredWrappers[details.rowColumnIndex.rowIndex - 1];
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
  }
}

class BrowserObjectWrapper {
  final String name;
  final bool isFolder;
  final int? size;
  final DateTime? lastModified;
  final String fullPath;

  BrowserObjectWrapper({
    required this.name,
    required this.isFolder,
    this.size,
    this.lastModified,
    required this.fullPath,
  });
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
              : '${(wrapper.size! / 1024).toStringAsFixed(2)} KB',
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
