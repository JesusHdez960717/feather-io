import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:material_ui/material_ui.dart';

import 'form/move_objects_dialog.dart';
import 'form/object_details_drawer.dart';
import 'form/object_name_dialog.dart';
import 'form/share_link_dialog.dart';
import 'objects_grid_datasource.dart';
import 'objects_table_datasource.dart';

class ObjectsSubscreen extends StatefulWidget {
  final BrowserSearchState state;
  final Function(String prefix) onNavigate;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final Function(BrowserObjectModel) onSelected;
  final Function(ViewType) onViewTypeChanged;
  final Function(List<String> keys) onDelete;
  final Function(List<XFile> files) onUpload;
  final Function(List<String> keys, {String? zipName}) onDownload;
  final Function(String key) onView;
  final void Function() onExit;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;
  final ValueChanged<int> onPageSizeChanged;

  /// Buckets objects can be moved to
  final List<String> bucketNames;

  const ObjectsSubscreen({
    required this.state,
    required this.onNavigate,
    required this.onRefresh,
    required this.onBack,
    required this.onForward,
    required this.onSelected,
    required this.onViewTypeChanged,
    required this.onDelete,
    required this.onUpload,
    required this.onDownload,
    required this.onView,
    required this.onExit,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.onPageSizeChanged,
    required this.bucketNames,
    super.key,
  });

  @override
  State<ObjectsSubscreen> createState() => _ObjectsSubscreenState();
}

class _ObjectsSubscreenState extends State<ObjectsSubscreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _breadcrumbScrollController = ScrollController();

  /// Folders and objects of the page shown
  List<BrowserObjectWrapper> _pageWrappers = [];

  /// Folders and objects of every loaded page: search and filters look
  /// here
  List<BrowserObjectWrapper> _loadedWrappers = [];
  List<BrowserObjectWrapper> _filteredWrappers = [];
  List<BrowserObjectWrapper> _selectedWrappers = [];

  /// Type/size/date filter; kept while navigating the bucket
  ObjectFilter _filter = ObjectFilter.none;
  bool _isDragging = false;

  /// The URL asks for a folder with nothing inside, not even its own `folder/`
  /// key (an empty folder keeps it), so for the user it doesn't exist
  bool get _isMissingFolder {
    final state = widget.state;
    final objects = state.objects;
    return state is BrowserLoadingSuccessState &&
        state.prefix.endsWith('/') &&
        objects != null &&
        objects.objects.isEmpty &&
        objects.commonPrefixes.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _initializeWrappers();
    _scrollBreadcrumbsToEnd();
  }

  @override
  void didUpdateWidget(covariant ObjectsSubscreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.pages != widget.state.pages ||
        oldWidget.state.pageIndex != widget.state.pageIndex ||
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
    _searchController.dispose();
    _breadcrumbScrollController.dispose();
    super.dispose();
  }

  void _initializeWrappers() {
    final page = widget.state.objects;
    _pageWrappers = page == null
        ? []
        : _wrappersOf(page.commonPrefixes, page.objects);
    _loadedWrappers = _wrappersOf(
      widget.state.loadedPrefixes,
      widget.state.loadedObjects,
    );
    _selectedWrappers = [];
    _applyFilters();
  }

  List<BrowserObjectWrapper> _wrappersOf(
    List<String> prefixes,
    List<BrowserObjectModel> objects,
  ) {
    return [
      for (final cp in prefixes)
        BrowserObjectWrapper(
          name: cp.split('/').where((s) => s.isNotEmpty).last,
          isFolder: true,
          fullPath: cp,
        ),
      for (final obj in objects)
        // the folder itself ("photos/") arrives as an object without a name
        if (obj.key.split('/').last.isNotEmpty)
          BrowserObjectWrapper(
            name: obj.key.split('/').last,
            isFolder: false,
            size: obj.sizeBytes,
            lastModified: obj.lastModified,
            fullPath: obj.key,
          ),
    ];
  }

  /// Names already used in the folder (by what is loaded), to avoid repeating them
  Set<String> get _usedNames => {for (final w in _loadedWrappers) w.name};

  void _onSelectionChanged(List<BrowserObjectWrapper> selected) {
    setState(() {
      _selectedWrappers = selected;
    });
  }

  void _onFilterChanged(ObjectFilter filter) {
    _filter = filter;
    _applyFilters();
  }

  /// Applies the search and the filter. The selection keeps only what is
  /// visible, so objects that can't be seen are not deleted or downloaded
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();
    setState(() {
      final searching = query.isNotEmpty || _filter.isActive;
      _filteredWrappers = (searching ? _loadedWrappers : _pageWrappers)
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

  void _onRename(BrowserObjectWrapper wrapper) {
    final bucket = widget.state.selectedBucket;
    if (bucket == null) return;
    ObjectNameDialog.rename(
      bucket: bucket.name,
      key: wrapper.fullPath,
      existingNames: _usedNames,
    );
  }

  void _onMove(List<BrowserObjectWrapper> wrappers) {
    final bucket = widget.state.selectedBucket;
    if (bucket == null) return;
    MoveObjectsDialog.show(
      bucket: bucket.name,
      prefix: widget.state.prefix,
      keys: wrappers.map((w) => w.fullPath).toList(),
      buckets: widget.bucketNames,
    );
  }

  void _onCreateFolder() {
    final bucket = widget.state.selectedBucket;
    if (bucket == null) return;
    ObjectNameDialog.createFolder(
      bucket: bucket.name,
      prefix: widget.state.prefix,
      existingNames: _usedNames,
    );
  }

  void _onDetails(BrowserObjectWrapper wrapper) {
    final bucket = widget.state.selectedBucket;
    if (bucket == null) return;
    ObjectDetailsDrawer.show(
      bucket: bucket.name,
      object: wrapper,
      onDelete: () => _onDeleteSelected([wrapper]),
      onRename: () => _onRename(wrapper),
      onMove: () => _onMove([wrapper]),
      onDownload: () =>
          widget.onDownload([wrapper.fullPath], zipName: wrapper.name),
    );
  }

  /// Only objects can be moved (folders not yet)
  bool get _canMoveSelection =>
      _selectedWrappers.isNotEmpty &&
      _selectedWrappers.every((w) => !w.isFolder);

  PopupMenuItem<String> _menuItem({
    required String value,
    required SvgAsset icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? app.colors.neutral.white;
    return PopupMenuItem(
      value: value,
      onTap: onTap,
      child: Row(
        children: [
          icon.build(size: 18, color: itemColor),
          app.dimensions.padding.m.gap(),
          Text(
            label,
            style: app.textTheme.bodyMedium?.copyWith(color: itemColor),
          ),
        ],
      ),
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
      items: <PopupMenuEntry<String>>[
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
        if (!wrapper.isFolder) ...[
          _menuItem(
            value: 'details',
            icon: app.assets.icons.actions.info,
            label: app.intl.objectsDetails,
            onTap: () => _onDetails(wrapper),
          ),
          _menuItem(
            value: 'share',
            icon: app.assets.icons.actions.link,
            label: app.intl.objectsShareLink,
            onTap: () {
              final bucket = widget.state.selectedBucket;
              if (bucket != null) {
                ShareLinkDialog.show(
                  bucket: bucket.name,
                  key: wrapper.fullPath,
                );
              }
            },
          ),
          _menuItem(
            value: 'rename',
            icon: app.assets.icons.actions.edit,
            label: app.intl.objectsRename,
            onTap: () => _onRename(wrapper),
          ),
          _menuItem(
            value: 'move',
            icon: app.assets.icons.storage.folder,
            label: app.intl.objectsMove,
            onTap: () => _onMove([wrapper]),
          ),
        ],
        const PopupMenuDivider(),
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
                    // back button
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
                          onPressed: widget.state.canGoForward
                              ? widget.onForward
                              : null,
                          icon: app.assets.icons.navigation.right,
                          iconColor: widget.state.canGoForward
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
                        PrimaryButton.secondary(
                          title: app.intl.objectsNewFolder,
                          icon: app.assets.icons.storage.folder,
                          onPressed: _onCreateFolder,
                          w: 170,
                          h: 38,
                        ),
                        app.dimensions.padding.m.gap(),
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
                            // filters the folder already loaded: no wait
                            delay: 0,
                            onSearch: (_) => _applyFilters(),
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
                        Tooltip(
                          message: app.intl.objectsMoveSelection,
                          child: PrimaryButton.svgIcon(
                            icon: app.assets.icons.storage.folder,
                            onPressed: _canMoveSelection
                                ? () => _onMove(_selectedWrappers)
                                : null,
                            buttonSize: 42,
                            iconSize: 18,
                            backgroundColor: app.colors.neutral.transparent,
                            iconColor: _canMoveSelection
                                ? app.colors.neutral.white
                                : app.colors.neutral.grey5,
                          ),
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
                  if (_isMissingFolder)
                    Positioned.fill(
                      child: ColoredBox(
                        color: app.colors.primary.background1,
                        child: BrowserNotFoundPage(
                          title: app.intl.browserFolderNotFound(
                            widget.state.prefix.substring(
                              0,
                              widget.state.prefix.length - 1,
                            ),
                          ),
                          description:
                              app.intl.browserFolderNotFoundDescription,
                          action: app.intl.browserGoToBucketRoot,
                          onAction: () => widget.onNavigate(''),
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
        ObjectsPager(
          state: widget.state,
          onPrevious: widget.onPreviousPage,
          onNext: widget.onNextPage,
          onPageSizeChanged: widget.onPageSizeChanged,
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
          app.dimensions.padding.l.gap(),
          PrimaryButton.primary(
            title: app.intl.bucketSettings,
            icon: app.assets.icons.actions.settings,
            color: app.colors.primary.background3,
            onPressed: () => RouteNames.openBucketSettings(bucket.name),
            h: 42,
            w: 170,
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
