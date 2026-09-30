import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:material_ui/material_ui.dart';

import 'objects_grid_datasource.dart';
import 'objects_table_datasource.dart';

class ObjectsSubscreen extends StatefulWidget {
  final BrowserSearchState state;
  final Function(String prefix) onNavigate;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final bool canGoForward;
  final Function(BrowserObjectModel) onSelected;
  final Function(ViewType) onViewTypeChanged;
  final Function(List<String> keys) onDelete;
  final Function(List<XFile> files) onUpload;
  final Function(List<String> keys, {String? zipName}) onDownload;
  final Function(String key) onView;
  final void Function() onExit;

  const ObjectsSubscreen({
    required this.state,
    required this.onNavigate,
    required this.onRefresh,
    required this.onBack,
    required this.onForward,
    required this.canGoForward,
    required this.onSelected,
    required this.onViewTypeChanged,
    required this.onDelete,
    required this.onUpload,
    required this.onDownload,
    required this.onView,
    required this.onExit,
    super.key,
  });

  @override
  State<ObjectsSubscreen> createState() => _ObjectsSubscreenState();
}

class _ObjectsSubscreenState extends State<ObjectsSubscreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _breadcrumbScrollController = ScrollController();
  List<BrowserObjectWrapper> _allWrappers = [];
  List<BrowserObjectWrapper> _filteredWrappers = [];
  List<BrowserObjectWrapper> _selectedWrappers = [];

  ///Filtro de tipo/tamaño/fecha; se mantiene al navegar por el bucket
  ObjectFilter _filter = ObjectFilter.none;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initializeWrappers();
    _searchController.addListener(_applyFilters);
    _scrollBreadcrumbsToEnd();
  }

  @override
  void didUpdateWidget(covariant ObjectsSubscreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.objects != widget.state.objects ||
        oldWidget.state.prefix != widget.state.prefix) {
      _initializeWrappers();
      if (oldWidget.state.prefix != widget.state.prefix) {
        _scrollBreadcrumbsToEnd();
      }
    }
  }

  void _scrollBreadcrumbsToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_breadcrumbScrollController.hasClients) {
        _breadcrumbScrollController.animateTo(
          _breadcrumbScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _breadcrumbScrollController.dispose();
    super.dispose();
  }

  void _initializeWrappers() {
    final ListObjectsModel? objectsModel = widget.state.objects;
    _allWrappers = [];
    _selectedWrappers = [];

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
    _applyFilters();
  }

  void _onSelectionChanged(List<BrowserObjectWrapper> selected) {
    setState(() {
      _selectedWrappers = selected;
    });
  }

  void _onFilterChanged(ObjectFilter filter) {
    _filter = filter;
    _applyFilters();
  }

  ///Aplica la busqueda y el filtro. La seleccion se queda solo con lo visible,
  ///para no borrar ni descargar objetos que no se ven
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();
    setState(() {
      _filteredWrappers = _allWrappers
          .where((w) => query.isEmpty || w.name.toLowerCase().contains(query))
          .where((w) => _filter.matches(w, now: now))
          .toList();
      _selectedWrappers = _selectedWrappers
          .where(_filteredWrappers.contains)
          .toList();
    });
  }

  void _onDeleteSelected(List<BrowserObjectWrapper> selected) {
    final bucket = widget.state.selectedBucket;
    if (bucket == null) return;

    final keys = selected.map((w) => w.fullPath).toList();

    ConfirmDialog.show(
      title: app.intl.objectsDeleteTitle,
      description: app.intl.objectsDeleteConfirm(keys.length),
      confirmTitle: app.intl.delete,
      confirmColor: app.colors.primary.errorAction,
      confirmAction: () => widget.onDelete(keys),
    );
  }

  void _onShowObjectOptions(BrowserObjectWrapper wrapper, RenderBox buttonBox) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        buttonBox.localToGlobal(Offset.zero, ancestor: overlay),
        buttonBox.localToGlobal(
          buttonBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: app.colors.primary.background2,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: app.dimensions.border.borderRadius.s,
        side: BorderSide(color: app.colors.neutral.grey5),
      ),
      items: [
        if (!wrapper.isFolder)
          PopupMenuItem(
            value: 'view',
            onTap: () => widget.onView(wrapper.fullPath),
            child: Row(
              children: [
                app.assets.icons.actions.view.build(
                  size: 18,
                  color: app.colors.neutral.white,
                ),
                app.dimensions.padding.m.gap(),
                Text(
                  app.intl.preview,
                  style: app.textTheme.bodyMedium?.copyWith(
                    color: app.colors.neutral.white,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'download',
          onTap: () =>
              widget.onDownload([wrapper.fullPath], zipName: wrapper.name),
          child: Row(
            children: [
              app.assets.icons.actions.download.build(
                size: 18,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                app.intl.download,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.white,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          onTap: () => _onDeleteSelected([wrapper]),
          child: Row(
            children: [
              app.assets.icons.actions.delete.build(
                size: 18,
                color: app.colors.primary.error,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                app.intl.delete,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.primary.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onShowUploadMenu(BuildContext context) {
    final RenderBox buttonBox = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        buttonBox.localToGlobal(Offset.zero, ancestor: overlay),
        buttonBox.localToGlobal(
          buttonBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      color: app.colors.primary.background2,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: app.dimensions.border.borderRadius.s,
        side: BorderSide(color: app.colors.neutral.grey5),
      ),
      items: [
        PopupMenuItem(
          onTap: () async {
            final xFiles = await FilePicker.pickFiles(multiple: true);
            if (xFiles.isNotEmpty) {
              widget.onUpload(_flattenDropItems(xFiles));
            }
          },
          child: Row(
            children: [
              app.assets.icons.actions.uploadFile.build(
                size: 18,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                app.intl.objectsUploadFiles,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.white,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () async {
            final xFiles = await FilePicker.pickDirectory();
            if (xFiles.isNotEmpty) {
              widget.onUpload(_flattenDropItems(xFiles));
            }
          },
          child: Row(
            children: [
              app.assets.icons.actions.uploadFolder.build(
                size: 18,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                app.intl.objectsUploadDirectory,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.state.prefix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBucketHeader(),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  crossAxisAlignment: .center,
                  children: [
                    //back button
                    Row(
                      children: [
                        PrimaryButton.svgIcon(
                          onPressed: prefix.isNotEmpty ? widget.onBack : null,
                          iconColor: prefix.isNotEmpty
                              ? null
                              : app.colors.neutral.grey5,
                          icon: app.assets.icons.navigation.left,
                          backgroundColor: app.colors.neutral.transparent,
                          buttonSize: 38,
                        ),
                        app.dimensions.padding.xs.gap(),
                        PrimaryButton.svgIcon(
                          onPressed: widget.canGoForward
                              ? widget.onForward
                              : null,
                          icon: app.assets.icons.navigation.right,
                          iconColor: widget.canGoForward
                              ? null
                              : app.colors.neutral.grey5,
                          backgroundColor: app.colors.neutral.transparent,
                          buttonSize: 38,
                        ),
                        app.dimensions.padding.xs.gap(),
                        PrimaryButton.svgIcon(
                          onPressed: widget.onRefresh,
                          icon: app.assets.icons.actions.refresh,
                          backgroundColor: app.colors.neutral.transparent,
                          buttonSize: 38,
                        ),
                      ],
                    ),
                    app.dimensions.padding.xl.gap(),
                    BrowserBreadcrumbs(
                      bucketName: widget.state.selectedBucket?.name ?? '',
                      prefix: widget.state.prefix,
                      onNavigate: widget.onNavigate,
                      scrollController: _breadcrumbScrollController,
                    ),
                    app.dimensions.padding.xl.gap(),
                    Row(
                      children: [
                        Builder(
                          builder: (context) {
                            return PrimaryButton.primary(
                              title: app.intl.upload,
                              icon: app.assets.icons.actions.upload,
                              onPressed: () => _onShowUploadMenu(context),
                              w: 150,
                              h: 38,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                app.dimensions.padding.s.gap(),
                const Divider(),
                app.dimensions.padding.s.gap(),
                Row(
                  mainAxisAlignment: .center,
                  crossAxisAlignment: .center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextSearchField(
                            controller: _searchController,
                            onSearch: (value) {},
                            hint: app.intl.objectsSearchHint,
                          ),
                        ],
                      ),
                    ),
                    app.dimensions.padding.l.gap(),
                    ObjectsFilterButton(
                      filter: _filter,
                      onChanged: _onFilterChanged,
                    ),
                    app.dimensions.padding.l.gap(),
                    ViewTypeSelector(
                      currentType: widget.state.viewType,
                      onChanged: widget.onViewTypeChanged,
                    ),
                    app.dimensions.padding.m.gap(),
                    Container(
                      width: 1.5,
                      height: 30,
                      color: app.colors.neutral.grey3,
                    ),
                    app.dimensions.padding.m.gap(),
                    Row(
                      children: [
                        PrimaryButton.svgIcon(
                          icon: app.assets.icons.actions.download,
                          onPressed: _selectedWrappers.isNotEmpty
                              ? () => widget.onDownload(
                                  _selectedWrappers
                                      .map((w) => w.fullPath)
                                      .toList(),
                                )
                              : null,
                          buttonSize: 42,
                          iconSize: 18,
                          backgroundColor: app.colors.neutral.transparent,
                          iconColor: _selectedWrappers.isNotEmpty
                              ? app.colors.neutral.white
                              : app.colors.neutral.grey5,
                        ),
                        app.dimensions.padding.xs.gap(),
                        PrimaryButton.svgIcon(
                          icon: app.assets.icons.actions.delete,
                          onPressed: _selectedWrappers.isNotEmpty
                              ? () => _onDeleteSelected(_selectedWrappers)
                              : null,
                          buttonSize: 42,
                          iconSize: 18,
                          backgroundColor: app.colors.neutral.transparent,
                          iconColor: _selectedWrappers.isNotEmpty
                              ? app.colors.primary.error
                              : app.colors.neutral.grey5,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: DropTarget(
            onDragEntered: (details) => setState(() => _isDragging = true),
            onDragExited: (details) => setState(() => _isDragging = false),
            onDragDone: (details) async {
              setState(() => _isDragging = false);

              widget.onUpload(_flattenDropItems(details.files));
            },
            child: ClipRect(
              child: Stack(
                children: [
                  LoadingOverlay(
                    visible:
                        widget.state is BrowserLoadingInProgressState ||
                        widget.state is BrowserProcessInProgressState,
                    overlayWidgetBuilder: LoadingOverlayStyles.table,
                    disableBackButton: false,
                    child: IgnorePointer(
                      ignoring: widget.state is! BrowserLoadingSuccessState,
                      child: widget.state.viewType == ViewType.list
                          ? ObjectsTableDatasource(
                              state: widget.state,
                              filteredWrappers: _filteredWrappers,
                              selectedWrappers: _selectedWrappers,
                              searchController: _searchController,
                              hasActiveFilter: _filter.isActive,
                              onNavigate: widget.onNavigate,
                              onSelected: widget.onSelected,
                              onSelectionChanged: _onSelectionChanged,
                              onShowOptions: _onShowObjectOptions,
                            )
                          : ObjectsGridDatasource(
                              state: widget.state,
                              filteredWrappers: _filteredWrappers,
                              selectedWrappers: _selectedWrappers,
                              searchController: _searchController,
                              hasActiveFilter: _filter.isActive,
                              onNavigate: widget.onNavigate,
                              onSelected: widget.onSelected,
                              onSelectionChanged: _onSelectionChanged,
                              onShowOptions: _onShowObjectOptions,
                            ),
                    ),
                  ),
                  if (_isDragging)
                    const Positioned.fill(child: DraggingZoneOverlay()),
                  if (widget.state is BrowserLoadingErrorState)
                    Positioned.fill(
                      child: ErrorPage(
                        message: (widget.state as BrowserLoadingErrorState)
                            .exception
                            .message,
                        onRetry: widget.onRefresh,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBucketHeader() {
    final bucket = widget.state.selectedBucket;
    if (bucket == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: app.dimensions.padding.xl),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(app.dimensions.padding.m),
            decoration: BoxDecoration(
              color:
                  bucket.uiColor ??
                  Color.lerp(
                    app.colors.primary.purple,
                    app.colors.neutral.white,
                    0.1,
                  )!.withValues(alpha: 0.2),
              borderRadius: app.dimensions.border.borderRadius.m,
            ),
            child: app.assets.icons.storage.bucket.build(
              size: 40,
              color: app.colors.neutral.white,
            ),
          ),
          app.dimensions.padding.l.gap(),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bucket.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: app.textTheme.headlineMedium?.copyWith(
                        color: app.colors.neutral.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bucket.description?.isNotEmpty == true)
                      Text(
                        bucket.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: app.textTheme.bodyMedium?.copyWith(
                          color: app.colors.neutral.grey3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<XFile> _flattenDropItems(List<XFile> items) {
  final result = <XFile>[];

  void walkDrop(DropItem item, String prefix) {
    if (item is DropItemDirectory) {
      final path = prefix.isEmpty ? item.name : '$prefix/${item.name}';
      for (final child in item.children) {
        walkDrop(child, path);
      }
    } else if (item is DropItemFile) {
      final path = prefix.isEmpty ? item.name : '$prefix/${item.name}';
      result.add(XFile(item.path, name: path, mimeType: item.mimeType));
    }
  }

  for (final item in items) {
    if (item is DropItem) {
      walkDrop(item, '');
    } else {
      result.add(item);
    }
  }

  return result;
}
