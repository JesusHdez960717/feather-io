import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class ThemeConfig {
  ///Los widgets de Material sin estilo propio toman la paleta, no los colores
  ///por defecto de Material 3
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: app.colors.primary.background1,
    brightness: Brightness.dark,
    fontFamily: 'DMSans',
    colorScheme: ColorScheme.dark(
      primary: app.colors.primary.primaryFaded,
      onPrimary: app.colors.primary.background1,
      secondary: app.colors.primary.secondary,
      onSecondary: app.colors.primary.background1,
      secondaryContainer: app.colors.primary.purple,
      onSecondaryContainer: app.colors.neutral.white,
      surface: app.colors.primary.background2,
      onSurface: app.colors.neutral.white,
      onSurfaceVariant: app.colors.neutral.grey3,
      error: app.colors.primary.error,
      onError: app.colors.primary.background1,
      outline: app.colors.neutral.grey5,
      outlineVariant: app.colors.neutral.grey5,
    ),
    focusColor: app.colors.primary.focusRing.withValues(alpha: 0.24),
    dividerTheme: DividerThemeData(color: app.colors.neutral.grey5),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: app.colors.primary.background2,
      indicatorColor: app.colors.primary.purple,
      selectedLabelTextStyle: TextStyle(
        color: app.colors.neutral.white,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(color: app.colors.neutral.grey3),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
