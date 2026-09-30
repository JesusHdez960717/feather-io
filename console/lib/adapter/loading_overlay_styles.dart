import 'dart:ui';

import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///Velos de carga de la app, para [LoadingOverlay.overlayWidgetBuilder]:
///`LoadingOverlay(overlayWidgetBuilder: LoadingOverlayStyles.table, ...)`
abstract final class LoadingOverlayStyles {
  ///Pantalla completa: blur fuerte y spinner del tema
  static Widget global(BuildContext context) => _veil(sigma: 4.5);

  ///Cajones y formularios: blur ligero, tinte negro al 8% y spinner
  ///`primaryFaded`
  static Widget form(BuildContext context) => _veil(
    sigma: 1.5,
    tint: app.colors.neutral.black.withValues(alpha: 0.08),
    spinnerColor: app.colors.primary.primaryFaded,
  );

  ///Paneles de tabla o cuadricula: blur minimo, el contenido sigue legible
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
