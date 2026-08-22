import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class ThemeConfig {
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: app.colors.primary.background1,
    brightness: Brightness.dark,
    fontFamily: 'DMSans',
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
