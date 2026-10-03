import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class PrimaryButton extends StatelessWidget {
  static PrimaryButton primary({
    required VoidCallback? onPressed,
    required String title,
    SvgAsset? icon,
    Color? iconColor,
    Color? color,
    BorderRadius? borderRadius,
    double? h,
    double? w,
    double? horizontalPadding,
    bool isLoading = false,
  }) {
    final background = color ?? app.colors.primary.purple.brighten(0.15);
    return PrimaryButton(
      onPressed: onPressed,
      isLoading: isLoading,
      color: background,
      disabledColor: background.withValues(alpha: 0.55),
      title: title,
      icon: icon?.build(size: 16, color: iconColor ?? app.colors.neutral.white),
      titleStyle: app.textTheme.titleMedium?.copyWith(
        color: app.colors.neutral.white,
      ),
      h: h ?? 50,
      w: w ?? double.infinity,
      horizontalPadding: horizontalPadding,
      borderRadius: borderRadius,
    );
  }

  static PrimaryButton secondary({
    required VoidCallback? onPressed,
    required String title,
    Color? color,
    SvgAsset? icon,
    Color? iconColor,
    BorderRadius? borderRadius,
    double? h,
    double? w,
    double? horizontalPadding,
    bool isLoading = false,
  }) {
    final background = color ?? app.colors.primary.background3;
    return PrimaryButton(
      onPressed: onPressed,
      isLoading: isLoading,
      color: background,
      disabledColor: background.withValues(alpha: 0.55),
      title: title,
      titleStyle: app.textTheme.bodyMedium?.copyWith(
        color: app.colors.neutral.white,
      ),
      icon: icon?.build(size: 16, color: iconColor ?? app.colors.neutral.white),
      h: h,
      w: w,
      horizontalPadding: horizontalPadding,
      borderRadius: borderRadius,
    );
  }

  static Widget svgIcon({
    required SvgAsset icon,
    VoidCallback? onPressed,
    String? tooltipMessage,
    Color? iconColor,
    Color? backgroundColor,
    Color? disabledBackgroundColor,
    double? buttonSize,
    double? iconSize,
    BorderRadius? borderRadius,
  }) {
    Widget build() {
      return PrimaryButton(
        onPressed: onPressed,
        color:
            backgroundColor ??
            app.colors.primary.background3.withValues(alpha: 0.75),
        disabledColor: disabledBackgroundColor ?? backgroundColor,
        title: '',
        icon: icon.build(
          size: iconSize ?? (buttonSize != null ? (buttonSize * 0.5) : 16),
          color: iconColor ?? app.colors.neutral.grey2,
        ),
        h: buttonSize ?? 36,
        w: buttonSize ?? 36,
        titleStyle: app.textTheme.headlineSmall?.copyWith(
          color: app.colors.neutral.white,
        ),
        borderRadius: borderRadius,
      );
    }

    return tooltipMessage != null
        ? Tooltip(message: tooltipMessage, child: build())
        : build();
  }

  final VoidCallback? onPressed;
  final Color color;
  final Color? disabledColor;
  final Widget? icon;
  final String title;
  final TextStyle? titleStyle;
  final double? w;
  final double? h;

  /// Margin on each side of the content; without a fixed width, the button is
  /// as wide as its content plus this margin
  final double? horizontalPadding;
  final BorderRadius? borderRadius;

  /// While loading it keeps its size and color, swaps the icon for a spinner and
  /// ignores taps. The caller passes the text in progressive form (*Creating...*)
  final bool isLoading;

  const PrimaryButton({
    required this.color,
    required this.title,
    this.onPressed,
    this.disabledColor,
    this.titleStyle,
    this.icon,
    this.w,
    this.h,
    this.horizontalPadding,
    this.borderRadius,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final leading = isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: app.colors.neutral.white,
              backgroundColor: app.colors.neutral.white.withValues(alpha: 0.35),
            ),
          )
        : icon;
    final radius = borderRadius ?? app.dimensions.border.borderRadius.s;
    return AppFocusRing(
      borderRadius: radius,
      child: SizedBox(
        width: w,
        height: h,
        child: FilledButton(
          onPressed: isLoading ? () {} : onPressed,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: color,
            disabledBackgroundColor: disabledColor,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding ?? app.dimensions.padding.s,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[leading],
                if (leading != null && title.isNotEmpty) ...[
                  app.dimensions.padding.s.gap(),
                ],
                if (title.isNotEmpty) ...[Text(title, style: titleStyle)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
