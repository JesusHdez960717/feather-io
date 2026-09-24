import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Scaffold(
        body: SizedBox.expand(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    app.assets.icons.admin.build(
                      color: app.colors.neutral.white,
                      size: 148,
                    ),
                    app.dimensions.padding.xxl.gap(),
                    Text(
                      context.intl.splashTitle,
                      style: TextTheme.of(context).headlineLarge,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: Text(
                    context.intl.splashFooter,
                    style: TextTheme.of(context).titleSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
