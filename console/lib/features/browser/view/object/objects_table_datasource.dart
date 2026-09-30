import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'object_info_helper.dart';

class ObjectsTableDatasource extends StatefulWidget {
  final BrowserSearchState state;
  final List<BrowserObjectWrapper> filteredWrappers;
  final List<BrowserObjectWrapper> selectedWrappers;
  final TextEditingController searchController;

  ///Hay un filtro de tipo/tamaño/fecha activo (cambia el mensaje de lista vacia)
  final bool hasActiveFilter;
  final Function(String prefix) onNavigate;
  final Function(BrowserObjectModel) onSelected;
  final Function(List<BrowserObjectWrapper> selected) onSelectionChanged;
  final Function(BrowserObjectWrapper wrapper, RenderBox box) onShowOptions;

  const ObjectsTableDatasource({
    required this.state,
    required this.filteredWrappers,
    required this.selectedWrappers,
    required this.searchController,
    required this.hasActiveFilter,
    required this.onNavigate,
    required this.onSelected,
    required this.onSelectionChanged,
    required this.onShowOptions,
    super.key,
  });

  @override
  State<ObjectsTableDatasource> createState() => _ObjectsTableDatasourceState();
}

class _ObjectsTableDatasourceState extends State<ObjectsTableDatasource> {
  final DataGridController _dataGridController = DataGridController();
  late _ObjectsDataSource _dataSource;

  Map<String, double?> columnWidths = {
    'name': null,
    'type': null,
    'size': null,
    'last_modified': null,
    'actions': null,
  };

  @override
  void initState() {
    super.initState();
    _dataSource = _buildDataSource();
    _updateSelection();
  }

  void _updateSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedRows = _dataSource.rows.where((row) {
        final wrapper = row.getCells()[0].value as BrowserObjectWrapper;
        return widget.selectedWrappers.contains(wrapper);
      }).toList();
      _dataGridController.selectedRows = selectedRows;
    });
  }

  _ObjectsDataSource _buildDataSource() {
    return _ObjectsDataSource(
      wrappers: widget.filteredWrappers,
      onShowOptions: widget.onShowOptions,
      onRowTap: (wrapper) {
        if (wrapper.isFolder) {
          widget.onNavigate(wrapper.fullPath);
        } else {
          final obj = widget.state.objects!.objects.firstWhere(
            (o) => o.key == wrapper.fullPath,
          );
          widget.onSelected(obj);
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant ObjectsTableDatasource oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filteredWrappers != widget.filteredWrappers) {
      _dataSource = _buildDataSource();
      _updateSelection();
    } else if (oldWidget.selectedWrappers != widget.selectedWrappers) {
      _updateSelection();
    }
  }

  @override
  void dispose() {
    _dataGridController.dispose();
    super.dispose();
  }

  void _handleSelectionChanged() {
    final List<BrowserObjectWrapper> selected = _dataGridController.selectedRows
        .map((row) => row.getCells()[0].value as BrowserObjectWrapper)
        .toList();
    widget.onSelectionChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        final nameWidth = totalWidth * 0.35;
        final typeWidth = totalWidth * 0.15;
        final sizeWidth = totalWidth * 0.15;
        final actionsWidth = 50.0;
        const checkboxWidth = 60.0;

        final lastModifiedWidth =
            (totalWidth -
                    (nameWidth +
                        typeWidth +
                        sizeWidth +
                        actionsWidth +
                        checkboxWidth))
                .clamp(150.0, totalWidth);

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

        if (widget.filteredWrappers.isEmpty &&
            widget.state is BrowserLoadingSuccessState) {
          return ObjectsEmptyPage(
            query: widget.searchController.text,
            hasActiveFilter: widget.hasActiveFilter,
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
              right: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
              bottom: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
            ),
          ),
          child: SfDataGridTheme(
            data: SfDataGridThemeData(
              //para configurar los colores de background de una fila del hover y el selection
              selectionColor: app.colors.primary.background3.withValues(
                alpha: 0.8,
              ),
              rowHoverColor: app.colors.primary.background3.withValues(
                alpha: 0.2,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    //para configurar el color del checkbox
                    if (states.contains(WidgetState.selected)) {
                      return app.colors.primary.selection;
                    }
                    return Colors.transparent;
                  }),
                  side: BorderSide(color: app.colors.neutral.grey3, width: 1.5),
                  // Borde gris
                  checkColor: WidgetStateProperty.all(
                    app.colors.primary.background1,
                  ), // Tick oscuro
                ),
              ),
              child: SfDataGrid(
                source: _dataSource,
                controller: _dataGridController,
                headerRowHeight: 42,
                rowHeight: 42,
                selectionMode: SelectionMode.multiple,
                showCheckboxColumn: true,
                checkboxColumnSettings: const DataGridCheckboxColumnSettings(
                  width: checkboxWidth,
                ),
                onSelectionChanged: (addedRows, removedRows) {
                  _handleSelectionChanged();
                },
                navigationMode: GridNavigationMode.row,
                gridLinesVisibility: GridLinesVisibility.horizontal,
                headerGridLinesVisibility: GridLinesVisibility.horizontal,
                allowColumnsResizing: true,
                onColumnResizeUpdate: (details) {
                  setState(() {
                    columnWidths[details.column.columnName] = details.width;

                    // Si redimensionamos cualquier columna que NO sea last_modified,
                    // ajustamos last_modified para que la tabla no se achique.
                    final othersWidth =
                        (columnWidths['name'] ?? nameWidth) +
                        (columnWidths['type'] ?? typeWidth) +
                        (columnWidths['size'] ?? sizeWidth) +
                        (columnWidths['actions'] ?? actionsWidth) +
                        checkboxWidth;

                    columnWidths['last_modified'] = (totalWidth - othersWidth)
                        .clamp(150.0, totalWidth);
                  });
                  return true;
                },
                columns: [
                  GridColumn(
                    columnName: 'name',
                    width: columnWidths['name'] ?? nameWidth,
                    minimumWidth: 150,
                    label: header(app.intl.name),
                  ),
                  GridColumn(
                    columnName: 'type',
                    width: columnWidths['type'] ?? typeWidth,
                    minimumWidth: 100,
                    label: header(app.intl.type),
                  ),
                  GridColumn(
                    columnName: 'size',
                    width: columnWidths['size'] ?? sizeWidth,
                    minimumWidth: 100,
                    label: header(app.intl.size),
                  ),
                  GridColumn(
                    columnName: 'last_modified',
                    width: columnWidths['last_modified'] ?? lastModifiedWidth,
                    minimumWidth: 150,
                    label: header(app.intl.lastModified),
                  ),
                  GridColumn(
                    columnName: 'actions',
                    width: actionsWidth,
                    label: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ObjectsDataSource extends DataGridSource {
  final List<BrowserObjectWrapper> wrappers;
  final void Function(BrowserObjectWrapper wrapper) onRowTap;
  final void Function(BrowserObjectWrapper wrapper, RenderBox box)
  onShowOptions;
  final ValueNotifier<BrowserObjectWrapper?> hoveredWrapper = ValueNotifier(
    null,
  );

  _ObjectsDataSource({
    required this.wrappers,
    required this.onRowTap,
    required this.onShowOptions,
  }) {
    _rows = wrappers.map(_buildRow).toList();
  }

  late List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final wrapper = row.getCells()[0].value as BrowserObjectWrapper;

    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        final bool isName = cell.columnName == 'name';
        final bool isActions = cell.columnName == 'actions';

        Widget content;
        if (isActions) {
          content = ValueListenableBuilder<BrowserObjectWrapper?>(
            valueListenable: hoveredWrapper,
            builder: (context, hovered, _) {
              final isHovered = hovered == wrapper;
              return Opacity(
                opacity: isHovered ? 1.0 : 0.0,
                child: Center(
                  child: Builder(
                    builder: (context) {
                      return IconButton(
                        icon: app.assets.icons.actions.more.build(
                          size: 18,
                          color: app.colors.neutral.grey2,
                        ),
                        onPressed: isHovered
                            ? () {
                                final RenderBox box =
                                    context.findRenderObject() as RenderBox;
                                onShowOptions(wrapper, box);
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
        } else if (isName) {
          final fileInfo = ObjectInfoHelper.getFileInfo(wrapper);
          content = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(fileInfo.icon, size: 18, color: app.colors.neutral.grey2),
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
          onEnter: (_) => hoveredWrapper.value = wrapper,
          onExit: (_) => hoveredWrapper.value = null,
          cursor: wrapper.isFolder
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onRowTap(wrapper),
            child: content,
          ),
        );
      }).toList(),
    );
  }

  DataGridRow _buildRow(BrowserObjectWrapper wrapper) {
    final fileInfo = ObjectInfoHelper.getFileInfo(wrapper);
    return DataGridRow(
      cells: [
        DataGridCell<BrowserObjectWrapper>(columnName: 'name', value: wrapper),
        DataGridCell<String>(columnName: 'type', value: fileInfo.name),
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
        DataGridCell<BrowserObjectWrapper>(
          columnName: 'actions',
          value: wrapper,
        ),
      ],
    );
  }
}
