import 'package:material_ui/material_ui.dart';

extension ColorHexExtension on Color {
  /// Color as `#RRGGBB`, without the alpha channel
  String toHex() =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// WCAG contrast ratio between this color and [other] (from 1 to 21)
  double contrastWith(Color other) {
    final a = computeLuminance();
    final b = other.computeLuminance();
    final lighter = a > b ? a : b;
    final darker = a > b ? b : a;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

/// Turns `#RRGGBB` or `RRGGBB` into an opaque [Color]; null if it is not valid
Color? colorFromHex(String text) {
  final hex = text.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex, radix: 16));
}
