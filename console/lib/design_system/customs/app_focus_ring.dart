import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// Keyboard focus ring: 2px of `focusRing` outside [child], without changing
/// its size. It only shows up when navigating with the keyboard, not on click
class AppFocusRing extends StatefulWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const AppFocusRing({required this.child, this.borderRadius, super.key});

  @override
  State<AppFocusRing> createState() => _AppFocusRingState();
}

class _AppFocusRingState extends State<AppFocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final visible =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius:
              widget.borderRadius ?? app.dimensions.border.borderRadius.s,
          boxShadow: visible
              ? [
                  BoxShadow(
                    color: app.colors.primary.focusRing,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
