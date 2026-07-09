import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onPressed;
  final String? buttonText;

  final Color? backgroundColor;

  const ErrorPage({
    this.errorMessage,
    this.onPressed,
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
                child: SelectionArea(
                  child: Text(
                    errorMessage ?? 'Error',
                    style: app.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (onPressed != null) ...[
                (2 * app.dimensions.padding.xxl).gap(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2 * app.dimensions.padding.xxl,
                  ),
                  child: PrimaryButton.primary(
                    title: buttonText ?? 'Try again',
                    onPressed: onPressed ?? () {},
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
