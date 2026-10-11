import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// Loading veils of the app, for [LoadingOverlay.overlayWidgetBuilder]:
/// `LoadingOverlay(overlayWidgetBuilder: LoadingOverlayStyles.table, ...)`
abstract final class LoadingOverlayStyles {
  /// Full screen: strong blur and the theme's spinner
  static Widget global(BuildContext context) => _veil(sigma: 4.5);

  /// Drawers and forms: light blur, 8% black tint and a `primaryFaded`
  /// spinner
  static Widget form(BuildContext context) => _veil(
    sigma: 1.5,
    tint: app.colors.neutral.black.withValues(alpha: 0.08),
    spinnerColor: app.colors.primary.primaryFaded,
  );

  /// Table or grid panels: minimal blur, the content stays readable
  static Widget table(BuildContext context) => _veil(
    sigma: 0.5,
    tint: app.colors.neutral.black.withValues(alpha: 0.08),
    spinnerColor: app.colors.primary.purple,
  );

  static Widget _veil({
    required double sigma,
    Color? tint,
    Color? spinnerColor,
  }) {
    final spinner = Center(
      child: CircularProgressIndicator(color: spinnerColor),
    );
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: tint == null ? spinner : ColoredBox(color: tint, child: spinner),
    );
  }
}
