import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

///Boton *Filtrar* con el numero de opciones activas. Abre debajo un panel que
///aplica cada cambio al momento
class ObjectsFilterButton extends StatefulWidget {
  final ObjectFilter filter;
  final ValueChanged<ObjectFilter> onChanged;

  const ObjectsFilterButton({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  @override
  State<ObjectsFilterButton> createState() => _ObjectsFilterButtonState();
}

class _ObjectsFilterButtonState extends State<ObjectsFilterButton> {
  static const double _gap = 8;

  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();

  void _close() {
    if (_portal.isShowing) {
      _portal.hide();
      setState(() {});
    }
  }

  void _toggle() {
    if (_portal.isShowing) {
      _close();
    } else {
      _portal.show();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.filter.activeCount;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildPanel,
      child: CompositedTransformTarget(
        link: _link,
        child: Badge.count(
          count: count,
          isLabelVisible: count > 0,
          backgroundColor: app.colors.primary.secondary,
          textColor: app.colors.primary.background1,
          child: PrimaryButton.primary(
            title: app.intl.filter,
            color: app.colors.primary.background3.withValues(alpha: 0.75),
            icon: app.assets.icons.actions.filter,
            onPressed: _toggle,
            h: 42,
            w: 100,
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, _gap),
              child: FocusScope(
                autofocus: true,
                //el padre reconstruye el boton con el filtro nuevo y con el, el panel
                child: _ObjectsFilterPanel(
                  filter: widget.filter,
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjectsFilterPanel extends StatelessWidget {
  static const double width = 340;

  final ObjectFilter filter;
  final ValueChanged<ObjectFilter> onChanged;

  const _ObjectsFilterPanel({required this.filter, required this.onChanged});

  Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    return Material(
      color: app.colors.neutral.transparent,
      child: Container(
        width: width,
        padding: EdgeInsets.all(app.dimensions.padding.l),
        decoration: BoxDecoration(
          color: app.colors.primary.background2,
          borderRadius: app.dimensions.border.borderRadius.s,
          border: Border.all(color: app.colors.neutral.grey5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            app.dimensions.padding.l.gap(),
            _buildGroup(
              title: app.intl.objectsFilterType,
              children: [
                for (final type in ObjectTypeFilter.values)
                  _FilterChip(
                    label: _typeLabel(type),
                    selected: filter.types.contains(type),
                    onTap: () => onChanged(
                      filter.copyWith(types: _toggle(filter.types, type)),
                    ),
                  ),
              ],
            ),
            app.dimensions.padding.l.gap(),
            _buildGroup(
              title: app.intl.objectsFilterSize,
              children: [
                for (final size in ObjectSizeFilter.values)
                  _FilterChip(
                    label: _sizeLabel(size),
                    selected: filter.sizes.contains(size),
                    onTap: () => onChanged(
                      filter.copyWith(sizes: _toggle(filter.sizes, size)),
                    ),
                  ),
              ],
            ),
            app.dimensions.padding.l.gap(),
            _buildGroup(
              title: app.intl.objectsFilterModified,
              children: [
                for (final date in ObjectDateFilter.values)
                  _FilterChip(
                    label: _dateLabel(date),
                    selected: filter.dates.contains(date),
                    onTap: () => onChanged(
                      filter.copyWith(dates: _toggle(filter.dates, date)),
                    ),
                  ),
              ],
            ),
            if (filter.isActive) ...[
              app.dimensions.padding.l.gap(),
              Text(
                app.intl.objectsFilterFoldersHidden,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            app.intl.objectsFilterTitle,
            style: app.textTheme.titleMedium?.copyWith(
              color: app.colors.neutral.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: filter.isActive
              ? () => onChanged(ObjectFilter.none)
              : null,
          child: Text(
            app.intl.objectsFilterClear,
            style: app.textTheme.bodyMedium?.copyWith(
              color: filter.isActive
                  ? app.colors.primary.secondary
                  : app.colors.neutral.grey5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroup({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: app.textTheme.labelMedium?.copyWith(
            color: app.colors.primary.primaryFaded,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        app.dimensions.padding.s.gap(),
        Wrap(
          spacing: app.dimensions.padding.s,
          runSpacing: app.dimensions.padding.s,
          children: children,
        ),
      ],
    );
  }

  String _typeLabel(ObjectTypeFilter type) => switch (type) {
    ObjectTypeFilter.image => app.intl.fileTypeImage,
    ObjectTypeFilter.video => app.intl.fileTypeVideo,
    ObjectTypeFilter.audio => app.intl.fileTypeAudio,
    ObjectTypeFilter.document => app.intl.fileTypeDocument,
    ObjectTypeFilter.archive => app.intl.fileTypeArchive,
    ObjectTypeFilter.other => app.intl.objectsFilterTypeOther,
  };

  String _sizeLabel(ObjectSizeFilter size) => switch (size) {
    ObjectSizeFilter.small => app.intl.objectsFilterSizeSmall,
    ObjectSizeFilter.medium => app.intl.objectsFilterSizeMedium,
    ObjectSizeFilter.large => app.intl.objectsFilterSizeLarge,
  };

  String _dateLabel(ObjectDateFilter date) => switch (date) {
    ObjectDateFilter.last24Hours => app.intl.objectsFilterDate24h,
    ObjectDateFilter.last7Days => app.intl.objectsFilterDate7d,
    ObjectDateFilter.last30Days => app.intl.objectsFilterDate30d,
    ObjectDateFilter.older => app.intl.objectsFilterDateOlder,
  };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = app.colors.primary.secondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: app.dimensions.border.borderRadius.s,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: app.dimensions.padding.m,
            vertical: app.dimensions.padding.s,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.15)
                : app.colors.primary.background3.withValues(alpha: 0.5),
            borderRadius: app.dimensions.border.borderRadius.s,
            border: Border.all(
              color: selected ? accent : app.colors.neutral.grey5,
            ),
          ),
          child: Text(
            label,
            style: app.textTheme.bodySmall?.copyWith(
              color: selected ? accent : app.colors.neutral.grey2,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
