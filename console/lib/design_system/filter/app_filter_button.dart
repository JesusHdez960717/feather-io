import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// An option of an [AppFilterGroup]
class AppFilterOption {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

/// A group of options of the filter panel. Within a group one option is
/// enough; between groups all of them must hold (that logic is the caller's)
class AppFilterGroup {
  final String title;
  final List<AppFilterOption> options;

  const AppFilterGroup({required this.title, required this.options});
}

/// *Filter* button with the number of active options. It opens a panel below
/// with [groups] of chips that apply each change at once
class AppFilterButton extends StatefulWidget {
  final int activeCount;
  final List<AppFilterGroup> groups;

  /// Clears every filter (the panel's *Clear*)
  final VoidCallback onClear;

  /// Extra line at the bottom of the panel, e.g. what the filters hide
  final String? note;

  const AppFilterButton({
    required this.activeCount,
    required this.groups,
    required this.onClear,
    this.note,
    super.key,
  });

  @override
  State<AppFilterButton> createState() => _AppFilterButtonState();
}

class _AppFilterButtonState extends State<AppFilterButton> {
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
    final count = widget.activeCount;
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
    // Room below the button: on a short window the panel scrolls instead of
    // being cut off by the bottom edge
    final button = this.context.findRenderObject() as RenderBox?;
    final buttonBottom = button == null
        ? 0.0
        : button.localToGlobal(Offset.zero).dy + button.size.height;
    final maxHeight =
        (MediaQuery.sizeOf(context).height -
                buttonBottom -
                _gap -
                app.dimensions.padding.l)
            .clamp(160.0, double.infinity);
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
                // the parent rebuilds the button with the new filter, and with
                // it the panel
                child: _AppFilterPanel(
                  groups: widget.groups,
                  active: widget.activeCount > 0,
                  onClear: widget.onClear,
                  note: widget.note,
                  maxHeight: maxHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppFilterPanel extends StatelessWidget {
  static const double width = 340;

  final List<AppFilterGroup> groups;
  final bool active;
  final VoidCallback onClear;
  final String? note;
  final double maxHeight;

  const _AppFilterPanel({
    required this.groups,
    required this.active,
    required this.onClear,
    required this.note,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: app.colors.neutral.transparent,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              for (final group in groups) ...[
                app.dimensions.padding.l.gap(),
                _buildGroup(group),
              ],
              if (active && note != null) ...[
                app.dimensions.padding.l.gap(),
                Text(
                  note!,
                  style: app.textTheme.bodySmall?.copyWith(
                    color: app.colors.neutral.grey3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            app.intl.filtersTitle,
            style: app.textTheme.titleMedium?.copyWith(
              color: app.colors.neutral.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: active ? onClear : null,
          child: Text(
            app.intl.filtersClear,
            style: app.textTheme.bodyMedium?.copyWith(
              color: active
                  ? app.colors.primary.secondary
                  : app.colors.neutral.grey5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroup(AppFilterGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title.toUpperCase(),
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
          children: [
            for (final option in group.options) _FilterChip(option: option),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final AppFilterOption option;

  const _FilterChip({required this.option});

  @override
  Widget build(BuildContext context) {
    final accent = app.colors.primary.secondary;
    final selected = option.selected;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: option.onTap,
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
            option.label,
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
