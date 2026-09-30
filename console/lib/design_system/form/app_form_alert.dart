import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

///Aviso de error de todo un formulario, para los fallos que no son de un
///campo concreto (red, 5xx, 409...). Va arriba del formulario
class AppFormAlert extends StatelessWidget {
  final String title;
  final String message;

  const AppFormAlert({required this.title, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final errorColor = app.colors.primary.error;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: app.dimensions.padding.l,
          vertical: app.dimensions.padding.m,
        ),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.12),
          borderRadius: app.dimensions.border.borderRadius.s,
          border: Border.all(color: errorColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 20, color: errorColor),
            app.dimensions.padding.m.gap(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: app.textTheme.bodyMedium?.copyWith(
                      color: app.colors.neutral.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: app.textTheme.bodyMedium?.copyWith(
                      color: app.colors.neutral.grey2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
