import 'package:material_ui/material_ui.dart';

class AppDimensions {
  static final AppDimensions _instance = AppDimensions._internal();

  AppDimensions._internal();

  factory AppDimensions() => _instance;

  AppBorder border = AppBorder();

  AppPadding padding = AppPadding();
}

class AppBorder {
  final AppRadius radius = AppRadius();
  late final AppBorderRadius borderRadius;
  final AppBorderWidth width = AppBorderWidth();
  final AppBorderWidth side = AppBorderWidth();

  AppBorder() {
    borderRadius = AppBorderRadius(radius);
  }
}

///Escala de 3 pasos. Un radio interior es el exterior menos el relleno que
///los separa (p. ej. pista `m` con 4px de relleno → segmentos `s`)
class AppRadius {
  ///4.0: casillas, badges y chips dentro de una barra
  Radius get xs => const Radius.circular(4);

  ///8.0: controles (botones, inputs, buscador, menus, dialogos, segmentos)
  Radius get s => const Radius.circular(8);

  ///12.0: tarjetas, paneles, snackbars y la pista del selector
  Radius get m => const Radius.circular(12);

  Radius get def => m;
}

class AppBorderRadius {
  final AppRadius radius;

  AppBorderRadius(this.radius);

  BorderRadius get xs => BorderRadius.all(radius.xs);

  BorderRadius get s => BorderRadius.all(radius.s);

  BorderRadius get m => BorderRadius.all(radius.m);

  BorderRadius get def => m;
}

class AppBorderWidth {
  ///1.0
  double get s => 1;

  ///1.5
  double get m => 1.5;

  ///2.0
  double get l => 2.0;

  ///m = 1.5
  double get def => m;
}

class AppPadding {
  ///4.0
  double get xs => 4.0;

  ///8.0
  double get s => 8.0;

  ///10.0
  double get sm => 10.0;

  ///12.0
  double get m => 12.0;

  ///16.0
  double get l => 16.0;

  ///20.0
  double get xl => 20.0;

  ///24.0
  double get xxl => 24.0;

  ///medium: 12.0
  double get def => m;
}
