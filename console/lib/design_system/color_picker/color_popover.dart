import 'dart:math' as math;

import 'package:console/app_exporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Panel to pick a custom color: saturation/brightness, hue and HEX.
/// [AppColorPicker] opens it anchored above its custom color circle
class ColorPopover extends StatefulWidget {
  static const double width = 264;
  static const double height = 360;

  final Color initial;

  /// Color checked for low contrast against (e.g. the white icon)
  final Color? contrastAgainst;

  /// Icon drawn over the color in the preview
  final SvgAsset? previewIcon;
  final ValueChanged<Color> onApply;
  final VoidCallback onCancel;

  const ColorPopover({
    required this.initial,
    required this.onApply,
    required this.onCancel,
    this.contrastAgainst,
    this.previewIcon,
    super.key,
  });

  @override
  State<ColorPopover> createState() => _ColorPopoverState();
}

class _ColorPopoverState extends State<ColorPopover> {
  static const double _areaWidth = ColorPopover.width - 24;
  static const double _areaHeight = 150;
  static const double _minContrast = 3;

  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final TextEditingController _hexController = TextEditingController(
    text: widget.initial.toHex(),
  );
  final FocusNode _hexFocus = FocusNode();
  bool _hexTouched = false;

  @override
  void initState() {
    super.initState();
    _hexFocus.addListener(() {
      if (!_hexFocus.hasFocus && mounted) setState(() => _hexTouched = true);
    });
  }

  @override
  void dispose() {
    _hexController.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  Color? get _hexColor => colorFromHex(_hexController.text);

  Color get _color => _hexColor ?? _hsv.toColor();

  bool get _showHexError =>
      _hexColor == null &&
      (_hexTouched || _hexController.text.replaceFirst('#', '').length >= 6);

  void _setHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _hexController.text = hsv.toColor().toHex();
      _hexTouched = false;
    });
  }

  void _onHexChanged(String text) {
    final color = colorFromHex(text);
    setState(() {
      if (color != null) _hsv = HSVColor.fromColor(color);
    });
  }

  void _apply() {
    final color = _hexColor;
    if (color != null) widget.onApply(color);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: app.colors.neutral.transparent,
      child: Container(
        width: ColorPopover.width,
        padding: EdgeInsets.all(app.dimensions.padding.m),
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            app.dimensions.padding.m.gap(),
            _SaturationValueArea(
              hsv: _hsv,
              width: _areaWidth,
              height: _areaHeight,
              onChanged: _setHsv,
            ),
            app.dimensions.padding.m.gap(),
            _HueSlider(hsv: _hsv, width: _areaWidth, onChanged: _setHsv),
            app.dimensions.padding.m.gap(),
            _buildHexRow(),
            app.dimensions.padding.m.gap(),
            _buildMessage(),
            app.dimensions.padding.m.gap(),
            _buildActions(),
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
            app.intl.colorCustom,
            style: app.textTheme.titleSmall?.copyWith(
              color: app.colors.neutral.white,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            tooltip: app.intl.close,
            padding: EdgeInsets.zero,
            iconSize: 18,
            onPressed: widget.onCancel,
            icon: app.assets.icons.actions.close.build(
              size: 20,
              color: app.colors.neutral.grey3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHexRow() {
    final errorColor = app.colors.primary.error;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(
              color: app.colors.neutral.white.withValues(alpha: 0.2),
            ),
          ),
          child: widget.previewIcon?.build(
            size: 16,
            color: widget.contrastAgainst ?? app.colors.neutral.white,
          ),
        ),
        app.dimensions.padding.s.gap(),
        Expanded(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: app.colors.primary.backgroundForm,
              borderRadius: app.dimensions.border.borderRadius.s,
              border: Border.all(
                color: _showHexError ? errorColor : app.colors.neutral.grey3,
                width: _showHexError ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'HEX',
                  style: app.textTheme.bodyMedium?.copyWith(
                    color: app.colors.neutral.grey3,
                  ),
                ),
                app.dimensions.padding.xs.gap(),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    focusNode: _hexFocus,
                    onChanged: _onHexChanged,
                    onSubmitted: (_) => _apply(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[#0-9a-fA-F]'),
                      ),
                      LengthLimitingTextInputFormatter(7),
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) => newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                        ),
                      ),
                    ],
                    style: app.textTheme.bodyMedium?.copyWith(
                      color: app.colors.neutral.white,
                      letterSpacing: 0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    final style = app.textTheme.bodySmall;
    IconData? icon;
    Color color = app.colors.neutral.grey3;
    Color iconColor = app.colors.primary.green;
    String? text;

    if (_showHexError) {
      icon = Icons.error_outline;
      color = iconColor = app.colors.primary.error;
      text = app.intl.colorHexInvalid;
    } else if (widget.contrastAgainst != null) {
      final ratio = _color.contrastWith(widget.contrastAgainst!);
      final formatted = ratio.toStringAsFixed(1);
      if (ratio < _minContrast) {
        icon = Icons.warning_rounded;
        color = iconColor = app.colors.primary.secondary;
        text = app.intl.colorContrastLow(formatted);
      } else {
        icon = Icons.check_circle_outline;
        text = app.intl.colorContrast(formatted);
      }
    }

    if (text == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: style?.copyWith(color: color)),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final actionStyle = app.textTheme.bodyMedium?.copyWith(
      color: app.colors.neutral.white,
    );
    final canApply = _hexColor != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PrimaryButton(
          onPressed: widget.onCancel,
          color: app.colors.primary.background3,
          title: app.intl.cancel,
          titleStyle: actionStyle,
          h: 32,
        ),
        app.dimensions.padding.s.gap(),
        PrimaryButton(
          onPressed: canApply ? _apply : null,
          color: app.colors.primary.purple.brighten(0.15),
          disabledColor: app.colors.primary.purple
              .brighten(0.15)
              .withValues(alpha: 0.55),
          title: app.intl.colorApply,
          titleStyle: actionStyle?.copyWith(fontWeight: FontWeight.w500),
          h: 32,
        ),
      ],
    );
  }
}

/// Saturation (horizontal) and brightness (vertical) square of the current hue
class _SaturationValueArea extends StatelessWidget {
  final HSVColor hsv;
  final double width;
  final double height;
  final ValueChanged<HSVColor> onChanged;

  const _SaturationValueArea({
    required this.hsv,
    required this.width,
    required this.height,
    required this.onChanged,
  });

  void _update(Offset position) {
    onChanged(
      hsv
          .withSaturation((position.dx / width).clamp(0.0, 1.0))
          .withValue(1 - (position.dy / height).clamp(0.0, 1.0)),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 0.1 : 0.01;
    double s = hsv.saturation;
    double v = hsv.value;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        s -= step;
      case LogicalKeyboardKey.arrowRight:
        s += step;
      case LogicalKeyboardKey.arrowUp:
        v += step;
      case LogicalKeyboardKey.arrowDown:
        v -= step;
      default:
        return KeyEventResult.ignored;
    }
    onChanged(
      hsv.withSaturation(s.clamp(0.0, 1.0)).withValue(v.clamp(0.0, 1.0)),
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final hue = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();
    return Semantics(
      slider: true,
      label: app.intl.colorSaturationBrightness,
      value:
          '${(hsv.saturation * 100).round()}%, ${(hsv.value * 100).round()}%',
      child: _FocusRing(
        autofocus: true,
        onKeyEvent: _onKey,
        borderRadius: app.dimensions.border.borderRadius.s,
        child: GestureDetector(
          onPanDown: (d) => _update(d.localPosition),
          onPanUpdate: (d) => _update(d.localPosition),
          child: MouseRegion(
            cursor: SystemMouseCursors.precise,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: app.dimensions.border.borderRadius.s,
                        gradient: LinearGradient(
                          colors: [app.colors.neutral.white, hue],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: app.dimensions.border.borderRadius.s,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: hsv.saturation * width - 8,
                    top: (1 - hsv.value) * height - 8,
                    child: _Thumb(color: hsv.toColor()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hue bar with the whole spectrum
class _HueSlider extends StatelessWidget {
  static const double _height = 12;

  final HSVColor hsv;
  final double width;
  final ValueChanged<HSVColor> onChanged;

  const _HueSlider({
    required this.hsv,
    required this.width,
    required this.onChanged,
  });

  void _update(double dx) =>
      onChanged(hsv.withHue((dx / width).clamp(0.0, 1.0) * 360));

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final step = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 1.0;
    final double hue;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowDown:
        hue = hsv.hue - step;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowUp:
        hue = hsv.hue + step;
      default:
        return KeyEventResult.ignored;
    }
    onChanged(hsv.withHue(hue.clamp(0.0, 360.0)));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: app.intl.colorHue,
      value: '${hsv.hue.round()}°',
      child: _FocusRing(
        onKeyEvent: _onKey,
        borderRadius: BorderRadius.circular(_height / 2),
        child: GestureDetector(
          onPanDown: (d) => _update(d.localPosition.dx),
          onPanUpdate: (d) => _update(d.localPosition.dx),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: SizedBox(
              width: width,
              height: _height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_height / 2),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFFFF00),
                            Color(0xFF00FF00),
                            Color(0xFF00FFFF),
                            Color(0xFF0000FF),
                            Color(0xFFFF00FF),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: hsv.hue / 360 * width - 8,
                    top: _height / 2 - 8,
                    child: _Thumb(
                      color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Makes a drag control focusable and paints a focus ring on it
class _FocusRing extends StatefulWidget {
  final Widget child;
  final FocusOnKeyEventCallback onKeyEvent;
  final BorderRadius borderRadius;
  final bool autofocus;

  const _FocusRing({
    required this.child,
    required this.onKeyEvent,
    required this.borderRadius,
    this.autofocus = false,
  });

  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onKeyEvent: widget.onKeyEvent,
      onFocusChange: (value) => setState(() => _focused = value),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: _focused
              ? Border.all(
                  color: app.colors.primary.primaryFaded,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final Color color;

  const _Thumb({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: app.colors.neutral.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Arrow joining the popover to the control that opens it
class ColorPopoverArrow extends StatelessWidget {
  final bool pointsDown;

  const ColorPopoverArrow({required this.pointsDown, super.key});

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: app.colors.neutral.grey5);
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: app.colors.primary.background2,
          border: pointsDown
              ? Border(right: side, bottom: side)
              : Border(left: side, top: side),
        ),
      ),
    );
  }
}
