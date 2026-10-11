import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class ErrorPage extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final String? buttonText;

  final Color? backgroundColor;

  const ErrorPage({
    this.message,
    this.onRetry,
    this.buttonText,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: app.dimensions.padding.xxl,
                ),
                child: Text(
                  message ?? app.intl.error,
                  style: app.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              if (onRetry != null) ...[
                (2 * app.dimensions.padding.xxl).gap(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2 * app.dimensions.padding.xxl,
                  ),
                  child: PrimaryButton.primary(
                    title: buttonText ?? app.intl.tryAgain,
                    onPressed: onRetry ?? () {},
                    w: 260,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
