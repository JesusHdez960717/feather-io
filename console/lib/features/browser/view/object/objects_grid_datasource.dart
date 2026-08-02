import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

import 'object_info_helper.dart';

class ObjectsGridDatasource extends StatelessWidget {
  final BrowserSearchState state;
  final List<BrowserObjectWrapper> filteredWrappers;
  final List<BrowserObjectWrapper> selectedWrappers;
  final TextEditingController searchController;
  final Function(String prefix) onNavigate;
  final Function(BrowserObjectModel) onSelected;
  final Function(List<BrowserObjectWrapper> selected) onSelectionChanged;
  final Function(BrowserObjectWrapper wrapper, RenderBox box) onShowOptions;

  const ObjectsGridDatasource({
    required this.state,
    required this.filteredWrappers,
    required this.selectedWrappers,
    required this.searchController,
    required this.onNavigate,
    required this.onSelected,
    required this.onSelectionChanged,
    required this.onShowOptions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredWrappers.isEmpty && state is BrowserSearchOkState) {
      return NoDataPage(
        title: searchController.text.isEmpty
            ? 'No objects found'
            : 'No objects matching "${searchController.text}"',
        description: searchController.text.isEmpty
            ? 'Arrastre ficheros aqui para subir'
            : null,
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
        padding: EdgeInsets.all(app.dimensions.padding.m),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: app.dimensions.padding.m,
          crossAxisSpacing: app.dimensions.padding.m,
        ),
        itemCount: filteredWrappers.length,
        itemBuilder: (context, index) {
          final wrapper = filteredWrappers[index];
          final fileInfo = ObjectInfoHelper.getFileInfo(wrapper);
          final isSelected = selectedWrappers.contains(wrapper);
          final anySelected = selectedWrappers.isNotEmpty;

          return _ObjectGridItem(
            wrapper: wrapper,
            fileInfo: fileInfo,
            state: state,
            isSelected: isSelected,
            anySelected: anySelected,
            onNavigate: onNavigate,
            onSelected: onSelected,
            onShowOptions: onShowOptions,
            onToggleSelection: () {
              final newSelection = List<BrowserObjectWrapper>.from(
                selectedWrappers,
              );
              if (isSelected) {
                newSelection.remove(wrapper);
              } else {
                newSelection.add(wrapper);
              }
              onSelectionChanged(newSelection);
            },
          );
        },
      ),
    );
  }
}

class _ObjectGridItem extends StatefulWidget {
  final BrowserObjectWrapper wrapper;
  final ({String name, IconData icon}) fileInfo;
  final BrowserSearchState state;
  final bool isSelected;
  final bool anySelected;
  final Function(String prefix) onNavigate;
  final Function(BrowserObjectModel) onSelected;
  final Function(BrowserObjectWrapper wrapper, RenderBox box) onShowOptions;
  final VoidCallback onToggleSelection;

  const _ObjectGridItem({
    required this.wrapper,
    required this.fileInfo,
    required this.state,
    required this.isSelected,
    required this.anySelected,
    required this.onNavigate,
    required this.onSelected,
    required this.onShowOptions,
    required this.onToggleSelection,
  });

  @override
  State<_ObjectGridItem> createState() => _ObjectGridItemState();
}

class _ObjectGridItemState extends State<_ObjectGridItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (widget.wrapper.isFolder) {
                widget.onNavigate(widget.wrapper.fullPath);
              } else {
                final obj = widget.state.objects!.objects.firstWhere(
                  (o) => o.key == widget.wrapper.fullPath,
                );
                widget.onSelected(obj);
              }
            },
            borderRadius: app.dimensions.border.borderRadius.s,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? app.colors.neutral.transparent
                    : _isHovered
                    ? app.colors.neutral.grey5.withValues(alpha: 0.3)
                    : app.colors.neutral.transparent,
                borderRadius: app.dimensions.border.borderRadius.s,
                border: Border.all(
                  color: widget.isSelected
                      ? app.colors.primary.tertiary
                      : app.colors.neutral.grey3,
                ),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: app.colors.neutral.black.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.fileInfo.icon,
                    size: 26,
                    color: app.colors.neutral.grey2,
                  ),
                  app.dimensions.padding.l.gap(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Text(
                          widget.wrapper.name,
                          style: app.textTheme.bodyLarge?.copyWith(
                            color: app.colors.neutral.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        app.dimensions.padding.m.gap(),
                        Text(
                          widget.wrapper.isFolder
                              ? 'Carpeta'
                              : '${app.storageFormatter.formatSize(widget.wrapper.size!)} • ${widget.fileInfo.name}',
                          style: app.textTheme.labelSmall?.copyWith(
                            color: app.colors.neutral.grey3,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        app.dimensions.padding.xs.gap(),
                        Text(
                          widget.wrapper.lastModified != null
                              ? app.dateFormatter.s.format(
                                  widget.wrapper.lastModified!,
                                )
                              : '-',
                          style: app.textTheme.labelSmall?.copyWith(
                            color: app.colors.neutral.grey3,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isHovered || widget.anySelected)
            Positioned(
              top: 0,
              left: 0,
              child: Checkbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onToggleSelection(),
                activeColor: app.colors.primary.tertiary,
                side: BorderSide(color: app.colors.neutral.grey2),
                shape: RoundedRectangleBorder(
                  borderRadius: app.dimensions.border.borderRadius.xs,
                ),
              ),
            ),
          if (_isHovered)
            Positioned(
              top: 4,
              right: 4,
              child: Builder(
                builder: (context) {
                  return IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: app.colors.neutral.grey2,
                    ),
                    onPressed: () {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      widget.onShowOptions(widget.wrapper, box);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
