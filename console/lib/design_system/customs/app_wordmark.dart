import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// Text logo: the name in bold DM Sans with the last word in the brand yellow
/// (`Feather` in white, `IO` in `secondary`)
class AppWordmark extends StatelessWidget {
  final String name;
  final double fontSize;

  const AppWordmark({required this.name, this.fontSize = 28, super.key});

  @override
  Widget build(BuildContext context) {
    final split = name.lastIndexOf(' ');
    final style = TextStyle(
      fontFamily: 'DMSans',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02 * fontSize,
      height: 1,
      color: app.colors.neutral.white,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: split < 0 ? name : name.substring(0, split + 1)),
          if (split >= 0)
            TextSpan(
              text: name.substring(split + 1),
              style: style.copyWith(color: app.colors.primary.secondary),
            ),
        ],
      ),
      semanticsLabel: name,
      textAlign: TextAlign.center,
    );
  }
}
