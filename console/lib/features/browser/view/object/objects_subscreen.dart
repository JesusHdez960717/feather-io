import 'dart:async';
import 'dart:js_interop';
import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'objects_grid_datasource.dart';
import 'objects_table_datasource.dart';

// webkitRelativePath no es parte de la API estándar de File,
// así que se expone como extension type sobre web.File.
extension type _FileWithRelativePath(web.File file) implements web.File {
  external String? get webkitRelativePath;
}

class ObjectsSubscreen extends StatefulWidget {
  final BrowserSearchState state;
  final Function(String prefix) onNavigate;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final Function(BrowserObjectModel) onSelected;
  final Function(ViewType) onViewTypeChanged;
  final Function(List<String> keys) onDelete;
  final Function(List<XFile> files) onUpload;
  final void Function() onExit;

  const ObjectsSubscreen({
    required this.state,
    required this.onNavigate,
    required this.onRefresh,
    required this.onBack,
    required this.onSelected,
    required this.onViewTypeChanged,
    required this.onDelete,
    required this.onUpload,
    required this.onExit,
    super.key,
  });

  @override
  State<ObjectsSubscreen> createState() => _ObjectsSubscreenState();
}

class _ObjectsSubscreenState extends State<ObjectsSubscreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BrowserObjectWrapper> _allWrappers = [];
  List<BrowserObjectWrapper> _filteredWrappers = [];
  List<BrowserObjectWrapper> _selectedWrappers = [];
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initializeWrappers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant ObjectsSubscreen oldWidget) {
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
    _onSearchChanged();
  }

  void _onSelectionChanged(List<BrowserObjectWrapper> selected) {
    setState(() {
      _selectedWrappers = selected;
    });
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

  void _onDeleteSelected(List<BrowserObjectWrapper> selected) {
    final bucket = widget.state.selectedBucket;
    if (bucket == null) return;

    final keys = selected.map((w) => w.fullPath).toList();

    ConfirmDialog.show(
      title: 'Delete objects',
      description: 'Are you sure you want to delete ${keys.length} objects?',
      confirmTitle: 'Delete',
      confirmColor: app.colors.primary.red,
      confirmAction: () => widget.onDelete(keys),
    );
  }

  void _onShowOptions(BrowserObjectWrapper wrapper, RenderBox buttonBox) {
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
          value: 'view',
          onTap: () {
            if (wrapper.isFolder) {
              widget.onNavigate(wrapper.fullPath);
            } else {
              final obj = widget.state.objects!.objects.firstWhere(
                (o) => o.key == wrapper.fullPath,
              );
              widget.onSelected(obj);
            }
          },
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                'View',
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.white,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(
                Icons.share_outlined,
                size: 18,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                'Share',
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
                color: app.colors.primary.red,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                'Delete',
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.primary.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onUploadFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    widget.onUpload(_flattenDropItems(result?.xFiles ?? []));
  }

  Future<void> _onUploadFolder() async {
    Future<XFile> webFileToXFile(web.File file) async {
      final buffer = await file.arrayBuffer().toDart;
      final bytes = buffer.toDart.asUint8List();

      final relativePath = _FileWithRelativePath(file).webkitRelativePath;
      final name = (relativePath != null && relativePath.isNotEmpty)
          ? relativePath
          : file.name;

      return XFile.fromData(
        bytes,
        name: name,
        length: bytes.length,
        lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified),
        mimeType: file.type,
      );
    }

    final input = web.HTMLInputElement()..type = 'file';
    input.setAttribute('webkitdirectory', 'true');
    input.setAttribute('directory', 'true');

    final completer = Completer<void>();
    input.addEventListener(
      'change',
      (web.Event event) {
        completer.complete();
      }.toJS,
    );

    input.click();
    await completer.future;

    final fileList = input.files;
    if (fileList == null) return;

    final xFiles = <XFile>[];
    for (var i = 0; i < fileList.length; i++) {
      final file = fileList.item(i);
      if (file == null) continue;
      xFiles.add(await webFileToXFile(file));
    }

    widget.onUpload(_flattenDropItems(xFiles));
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
          onTap: _onUploadFiles,
          child: Row(
            children: [
              app.assets.icons.actions.uploadFile.build(
                size: 18,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                'Upload files',
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.white,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: _onUploadFolder,
          child: Row(
            children: [
              app.assets.icons.actions.uploadFolder.build(
                size: 18,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                'Upload directory',
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
                          onPressed: null,
                          icon: app.assets.icons.navigation.right,
                          iconColor: app.colors.neutral.grey5,
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
                    _buildBreadcrumbs(),
                    app.dimensions.padding.xl.gap(),
                    Row(
                      children: [
                        Builder(
                          builder: (context) {
                            return PrimaryButton.primary(
                              title: 'Upload',
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
                          EMTextSearchField(
                            controller: _searchController,
                            onSearch: (value) {},
                            hint: 'Search objects...',
                          ),
                        ],
                      ),
                    ),
                    app.dimensions.padding.l.gap(),
                    Badge.count(
                      count: 1,
                      backgroundColor: app.colors.primary.purple,
                      textColor: app.colors.neutral.white,
                      child: PrimaryButton.primary(
                        title: 'Filter',
                        color: app.colors.primary.background3.withValues(
                          alpha: 0.75,
                        ),
                        icon: app.assets.icons.actions.filter,
                        onPressed: () {},
                        h: 42,
                        w: 100,
                      ),
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
                          icon: app.assets.icons.actions.delete,
                          onPressed: _selectedWrappers.isNotEmpty
                              ? () => _onDeleteSelected(_selectedWrappers)
                              : null,
                          buttonSize: 42,
                          iconSize: 18,
                          backgroundColor: app.colors.neutral.transparent,
                          iconColor: _selectedWrappers.isNotEmpty
                              ? app.colors.primary.red
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
                  IgnorePointer(
                    ignoring: widget.state is! BrowserSearchOkState,
                    child: widget.state.viewType == ViewType.list
                        ? ObjectsTableDatasource(
                            state: widget.state,
                            filteredWrappers: _filteredWrappers,
                            selectedWrappers: _selectedWrappers,
                            searchController: _searchController,
                            onNavigate: widget.onNavigate,
                            onSelected: widget.onSelected,
                            onSelectionChanged: _onSelectionChanged,
                            onShowOptions: _onShowOptions,
                          )
                        : ObjectsGridDatasource(
                            state: widget.state,
                            filteredWrappers: _filteredWrappers,
                            selectedWrappers: _selectedWrappers,
                            searchController: _searchController,
                            onNavigate: widget.onNavigate,
                            onSelected: widget.onSelected,
                            onSelectionChanged: _onSelectionChanged,
                            onShowOptions: _onShowOptions,
                          ),
                  ),
                  if (_isDragging)
                    Positioned.fill(child: _buildDraggingOverlay()),
                  if (widget.state is BrowserSearchingState ||
                      widget.state is BrowserProcessingInProgressState)
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
              color: Color.lerp(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bucket.name,
                style: app.textTheme.headlineMedium?.copyWith(
                  color: app.colors.neutral.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              /*Text(
                'Bucket storage: ${app.storageFormatter.formatSize(bucket.sizeBytes)}',
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.grey3,
                ),
              ),*/
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final bucketName = widget.state.selectedBucket?.name ?? '';
    final prefix = widget.state.prefix;
    final parts = prefix.split('/').where((s) => s.isNotEmpty).toList();

    List<Widget> children = [];

    Widget separator() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: app.assets.icons.navigation.next.build(
        size: 16,
        color: app.colors.neutral.grey3,
      ),
    );

    Widget breadcrumbItem({
      required VoidCallback? onTap,
      required bool isLast,
      required String label,
      Widget? icon,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: app.colors.primary.background2,
          borderRadius: app.dimensions.border.borderRadius.xs,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: app.dimensions.border.borderRadius.xs,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                ?icon,
                if (icon != null && label.isNotEmpty)
                  app.dimensions.padding.s.gap(),
                Text(
                  label,
                  style: app.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: app.colors.neutral.white,
                    fontWeight: isLast ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Bucket name (root of object navigation)
    children.add(
      breadcrumbItem(
        label: bucketName,
        onTap: parts.isEmpty ? null : () => widget.onNavigate(''),
        isLast: parts.isEmpty,
        icon: app.assets.icons.storage.bucket.build(
          color: app.colors.neutral.white,
          size: 14,
        ),
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

    return Expanded(
      child: Container(
        height: 38,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: app.colors.primary.background3,
          borderRadius: app.dimensions.border.borderRadius.xs,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.5),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: children),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
            right: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
            bottom: BorderSide(color: app.colors.neutral.grey5, width: 0.5),
          ),
          color: app.colors.neutral.white.withValues(alpha: 0.03),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              app.assets.icons.actions.upload.build(
                size: 48,
                color: app.colors.neutral.white,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                'Suelte aqui para subir',
                style: app.textTheme.titleLarge?.copyWith(
                  color: app.colors.neutral.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
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
    required this.fullPath,
    this.size,
    this.lastModified,
  });
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
