import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class AppColors {
  static final AppColors _instance = AppColors._internal();

  AppColors._internal();

  factory AppColors() => _instance;

  PrimaryColor primary = PrimaryColor();
  NeutralColor neutral = NeutralColor();
  PaletteColor palette = PaletteColor();
}

/// Colors the user can pick (e.g. a bucket's color). All of them exceed 5:1
/// with a white icon on top
class PaletteColor {
  Color get violet => const Color(0xFF5C4999);

  Color get blue => const Color(0xFF2652E0);

  Color get teal => const Color(0xFF0F766E);

  Color get green => const Color(0xFF2E7D32);

  Color get amber => const Color(0xFFA15C00);

  Color get red => const Color(0xFFC62828);

  Color get pink => const Color(0xFFC0156E);

  Color get slate => const Color(0xFF475569);

  /// Wedges of the custom color circle, clockwise from the top
  List<Color> get wheel => const [
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
}

class PrimaryColor {
  /// purple: 3D3065
  Color get purple => const Color(0xFF3D3065);

  Color get backgroundForm => background1.brighten(0.05);

  Color get background1 => const Color(0xff13111c);

  Color get background2 => const Color(0xff181622);

  Color get background3 => const Color(0xff2f2c3f);

  /// light blue / purple: 9484C5
  Color get primaryFaded => const Color(0xFF9484C5);

  /// Keyboard focus ring: 5.4:1 over background2
  Color get focusRing => primaryFaded;

  /// Checked boxes and the border of what is selected: 5.4:1 over background2
  Color get selection => primaryFaded;

  /// Brand yellow: accent to highlight (badges, active target, notices).
  /// Text on top goes in background1 (12:1)
  Color get secondary => const Color(0xFFFDCA3C);

  /// Error text, icons and borders over dark backgrounds: 4.7:1 over
  /// backgroundForm
  Color get error => const Color(0xFFE95450);

  /// Fill of destructive actions and of the error snackbar: white on top
  /// gives 5.6:1
  Color get errorAction => const Color(0xFFC62828);

  /// Success text and icons over dark backgrounds: 5.9:1 over background2
  Color get green => const Color(0xFF2CAA4A);

  /// Fill of the success snackbar: white on top gives 5.1:1
  Color get greenAction => const Color(0xFF2E7D32);
}

class NeutralColor {
  Color get grey5 => const Color(0xff575562);

  /// Disabled text: 5.2:1 over background2
  Color get grey4 => const Color(0xff8a8996);

  Color get grey3 => const Color(0xffafafaf);

  Color get grey2 => const Color(0xffe5e5e5);

  Color get grey1 => const Color(0xfff7f7f7);

  Color get white => const Color(0xffffffff);

  Color get black => const Color(0xff000000);

  Color get transparent => Colors.transparent;
}
