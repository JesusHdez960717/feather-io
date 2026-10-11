import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

/// What the browser URL asks for doesn't exist (a bucket or a folder): title,
/// explanation and an action to go back somewhere that does exist
class BrowserNotFoundPage extends StatelessWidget {
  final String title;
  final String description;
  final String action;
  final VoidCallback onAction;

  const BrowserNotFoundPage({
    required this.title,
    required this.description,
    required this.action,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(app.dimensions.padding.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: app.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              app.dimensions.padding.m.gap(),
              Text(
                description,
                textAlign: TextAlign.center,
                style: app.textTheme.bodyMedium?.copyWith(
                  color: app.colors.neutral.grey3,
                ),
              ),
              (2 * app.dimensions.padding.xl).gap(),
              PrimaryButton.primary(title: action, onPressed: onAction, w: 260),
            ],
          ),
        ),
      ),
    );
  }
}
