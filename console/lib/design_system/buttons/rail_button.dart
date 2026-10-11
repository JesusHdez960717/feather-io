import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// Square button of the rail footer (transfers, language, log out):
/// 44x44, `background2` with a `grey5` border and `radius-s`. [onPressed] gets
/// the button's context, to anchor a menu or a panel to it
class RailButton extends StatelessWidget {
  static const double size = 44;

  final String tooltip;
  final void Function(BuildContext context) onPressed;
  final Widget child;

  /// Painted outside the border, over the top right corner
  final Widget? badge;

  const RailButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.badge,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final radius = app.dimensions.border.borderRadius.s;
    return Tooltip(
      message: tooltip,
      // the badge goes outside the Material: it paints its border over what
      // it contains
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppFocusRing(
            borderRadius: radius,
            child: Material(
              color: app.colors.primary.background2,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(color: app.colors.neutral.grey5),
              ),
              child: InkWell(
                borderRadius: radius,
                hoverColor: app.colors.primary.background3,
                onTap: () => onPressed(context),
                child: SizedBox.square(
                  dimension: size,
                  child: Center(child: child),
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: -6,
              // doesn't block the button's tap
              child: IgnorePointer(child: badge),
            ),
        ],
      ),
    );
  }
}
