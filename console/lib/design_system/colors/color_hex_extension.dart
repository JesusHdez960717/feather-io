import 'package:material_ui/material_ui.dart';

extension ColorHexExtension on Color {
  ///Color en formato `#RRGGBB`, sin canal alfa
  String toHex() =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  ///Ratio de contraste WCAG entre este color y [other] (de 1 a 21)
  double contrastWith(Color other) {
    final a = computeLuminance();
    final b = other.computeLuminance();
    final lighter = a > b ? a : b;
    final darker = a > b ? b : a;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

///Convierte `#RRGGBB` o `RRGGBB` en un [Color] opaco; null si no es valido
Color? colorFromHex(String text) {
  final hex = text.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex, radix: 16));
}
