import 'dart:math' as math;

import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Palette option of [AppColorPicker]
class AppColorOption {
  final Color color;
  final String label;

  const AppColorOption({required this.color, required this.label});
}

/// Generic color picker: "no color", a palette and, at the end, a custom color
/// circle that opens a [ColorPopover] anchored above it.
/// It doesn't keep the value: the caller gets it in [onChanged] and passes it back in [value]
class AppColorPicker extends StatefulWidget {
  /// Default palette (the colors of [PaletteColor])
  static List<AppColorOption> get defaultPalette => [
    AppColorOption(
      color: app.colors.palette.violet,
      label: app.intl.colorViolet,
    ),
    AppColorOption(color: app.colors.palette.blue, label: app.intl.colorBlue),
    AppColorOption(color: app.colors.palette.teal, label: app.intl.colorTeal),
    AppColorOption(color: app.colors.palette.green, label: app.intl.colorGreen),
    AppColorOption(color: app.colors.palette.amber, label: app.intl.colorAmber),
    AppColorOption(color: app.colors.palette.red, label: app.intl.colorRed),
    AppColorOption(color: app.colors.palette.pink, label: app.intl.colorPink),
    AppColorOption(color: app.colors.palette.slate, label: app.intl.colorSlate),
  ];

  final Color? value;
  final ValueChanged<Color?> onChanged;
  final List<AppColorOption>? palette;
  final bool allowNone;
  final bool allowCustom;
  final bool enabled;

  /// Color the popover checks for low contrast against
  final Color? contrastAgainst;

  /// Icon the popover draws over the color in its preview
  final SvgAsset? previewIcon;

  const AppColorPicker({
    required this.value,
    required this.onChanged,
    this.palette,
    this.allowNone = true,
    this.allowCustom = true,
    this.enabled = true,
    this.contrastAgainst,
    this.previewIcon,
    super.key,
  });

  @override
  State<AppColorPicker> createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker> {
  static const double _gap = 14;
  static const double _arrowSize = 12;

  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _customKey = GlobalKey();
  bool _openAbove = true;

  List<AppColorOption> get _palette =>
      widget.palette ?? AppColorPicker.defaultPalette;

  bool _sameColor(Color a, Color b) => a.toARGB32() == b.toARGB32();

  /// A value that is not in the palette is shown as a custom color
  bool get _isCustom =>
      widget.value != null &&
      !_palette.any((o) => _sameColor(o.color, widget.value!));

  void _select(Color? color) {
    _close();
    widget.onChanged(color);
  }

  void _open() {
    final box = _customKey.currentContext?.findRenderObject() as RenderBox?;
    final top = box?.localToGlobal(Offset.zero).dy ?? double.infinity;
    setState(() => _openAbove = top > ColorPopover.height + _gap + 8);
    _portal.show();
  }

  void _close() {
    if (_portal.isShowing) {
      _portal.hide();
      setState(() {});
    }
  }

  void _toggle() => _portal.isShowing ? _close() : _open();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (widget.allowNone)
              _Swatch(
                label: app.intl.colorNone,
                selected: widget.value == null,
                onTap: () => _select(null),
                background: Color.lerp(
                  app.colors.primary.purple,
                  app.colors.neutral.white,
                  0.1,
                )!.withValues(alpha: 0.2),
                child: Icon(
                  Icons.block,
                  size: 14,
                  color: app.colors.neutral.grey3,
                ),
              ),
            for (final option in _palette)
              _Swatch(
                label: option.label,
                selected:
                    widget.value != null &&
                    _sameColor(option.color, widget.value!),
                onTap: () => _select(option.color),
                background: option.color,
              ),
            if (widget.allowCustom) _buildCustom(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustom() {
    final open = _portal.isShowing;
    final custom = _isCustom ? widget.value : null;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildPopover,
      child: CompositedTransformTarget(
        link: _link,
        child: _Swatch(
          key: _customKey,
          label: custom != null
              ? '${app.intl.colorCustom} ${custom.toHex()}'
              : app.intl.colorCustom,
          selected: custom != null,
          highlighted: open,
          onTap: _toggle,
          gradient: SweepGradient(
            transform: const GradientRotation(-math.pi / 2),
            colors: [
              for (final c in app.colors.palette.wheel) ...[c, c],
            ],
            stops: [
              for (var i = 0; i < 8; i++) ...[i / 8, (i + 1) / 8],
            ],
          ),
          child: custom == null
              ? null
              : Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: custom,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: app.colors.primary.background2,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 10,
                    color: app.colors.neutral.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPopover(BuildContext context) {
    final initial = widget.value ?? app.colors.palette.violet;
    final above = _openAbove;
    final arrow = ColorPopoverArrow(pointsDown: above);
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
              targetAnchor: above
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              followerAnchor: above
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              offset: Offset(0, above ? -_gap : _gap),
              child: FocusScope(
                autofocus: true,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ColorPopover(
                      initial: initial,
                      contrastAgainst: widget.contrastAgainst,
                      previewIcon: widget.previewIcon,
                      onCancel: _close,
                      onApply: _select,
                    ),
                    Positioned(
                      left: (ColorPopover.width - _arrowSize) / 2,
                      top: above ? null : -_arrowSize / 2,
                      bottom: above ? -_arrowSize / 2 : null,
                      child: arrow,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 28px circle of the picker row
class _Swatch extends StatelessWidget {
  static const double size = 28;

  final String label;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;
  final Color? background;
  final Gradient? gradient;
  final Widget? child;

  const _Swatch({
    required this.label,
    required this.selected,
    required this.onTap,
    this.highlighted = false,
    this.background,
    this.gradient,
    this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showCheck = selected && child == null && gradient == null;
    final ringOn = selected || highlighted;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background,
              gradient: gradient,
              border: Border.all(
                color: ringOn
                    ? app.colors.neutral.white
                    : app.colors.neutral.white.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: app.colors.primary.primaryFaded.withValues(
                          alpha: 0.45,
                        ),
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: showCheck
                ? Icon(Icons.check, size: 14, color: app.colors.neutral.white)
                : child,
          ),
        ),
      ),
    );
  }
}
