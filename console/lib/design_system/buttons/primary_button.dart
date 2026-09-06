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
  }) {
    return PrimaryButton(
      onPressed: onPressed,
      color: color ?? app.colors.primary.purple.brighten(0.15),
      title: title,
      icon: icon?.build(size: 16, color: iconColor ?? app.colors.neutral.white),
      titleStyle: app.textTheme.titleMedium?.copyWith(
        color: app.colors.neutral.white,
      ),
      h: h ?? 50,
      w: w ?? double.infinity,
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
  }) {
    return PrimaryButton(
      onPressed: onPressed,
      color: color ?? app.colors.primary.background3,
      title: title,
      titleStyle: app.textTheme.bodyMedium?.copyWith(
        color: app.colors.neutral.white,
      ),
      icon: icon?.build(size: 16, color: iconColor ?? app.colors.neutral.white),
      h: h,
      w: w,
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
  final BorderRadius? borderRadius;

  const PrimaryButton({
    required this.color,
    required this.title,
    this.onPressed,
    this.disabledColor,
    this.titleStyle,
    this.icon,
    this.w,
    this.h,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w,
      height: h,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: color,
          disabledBackgroundColor: disabledColor,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? app.dimensions.border.borderRadius.xs,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: app.dimensions.padding.s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!],
              if (icon != null && title.isNotEmpty) ...[
                app.dimensions.padding.s.gap(),
              ],
              if (title.isNotEmpty) ...[Text(title, style: titleStyle)],
            ],
          ),
        ),
      ),
    );
  }
}
