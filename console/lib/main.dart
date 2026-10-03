import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart' as old;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final String loadingOverlayGlobalId = 'app-global-loading';

/// The texts of the app and those of `material_ui`. The ones gen-l10n generates
/// (`AppLocalizations.localizationsDelegates`) bring the Material ones of
/// `flutter_localizations`, which `material_ui` widgets can't see: outside
/// English (which `material_ui` ships by default) they would fail with "No
/// MaterialLocalizations found"
const List<LocalizationsDelegate<dynamic>> _localizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

// generate code
// fvm flutter pub run build_runner build --delete-conflicting-outputs
// fvm flutter gen-l10n

// versions
// fvm flutter pub outdated
// fvm flutter pub upgrade --major-versions

// migration
// fvm dart fix --dry-run
// fvm dart fix --apply
//
// fvm flutter analyze
class Init {
  Init._();

  static final instance = Init._();

  Future initialize() async {
    // so the splash shows instead of flashing by
    await Future.delayed(const Duration(seconds: 1));

    await FeaturesInit.init();
  }
}

void main() {
  // so the .push method of go_router updates the URL
  GoRouter.optionURLReflectsImperativeAPIs = true;

  WidgetsFlutterBinding.ensureInitialized();

  // error handling
  /*FlutterError.onError = (errorDetails) {
    app.logger.e('------------------- error 1 -------------------');
    app.logger.e(errorDetails.exception);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    app.logger.e('------------------- error 2 -------------------');
    app.logger.e(error);
    app.logger.e(stack);
    return true;
  };*/

  runApp(
    FutureBuilder(
      future: Init.instance.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiBlocProvider(
            providers: [...FeaturesInit.blocProviders],
            child: const App(),
          );
        } else {
          return const SplashScreen();
        }
      },
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageListener(
      onLanguageChangeBuilder: (locale) {
        Size size = MediaQuery.of(context).size;
        if (size.width < 800 || size.height < 400) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeConfig.theme,
            locale: locale,
            localizationsDelegates: _localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => Scaffold(
              body: Center(child: Text(context.intl.appNeedMoreSpace)),
            ),
          );
        } else {
          return MaterialApp.router(
            builder: (BuildContext context, Widget? child) {
              return LoadingOverlay(
                id: loadingOverlayGlobalId,
                overlayWidgetBuilder: LoadingOverlayStyles.global,
                child: MaterialUiCompatibilityBridge(
                  child: old.Material(
                    type: old.MaterialType.transparency,
                    child: AppSelectionArea(child: child!),
                  ),
                ),
              );
            },
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => context.intl.appName,
            theme: ThemeConfig.theme,
            locale: locale,
            routerConfig: RouteConfig.router,
            localizationsDelegates: _localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        }
      },
    );
  }
}

AppGlobal app = AppGlobal();

class AppGlobal {
  static final AppGlobal _instance = AppGlobal._internal();

  AppGlobal._internal();

  factory AppGlobal() => _instance;

  BuildContext get context => navigatorKey.currentContext!;

  ThemeData get theme => Theme.of(context);

  TextTheme get textTheme => theme.textTheme;

  AppLocalizations get intl => context.intl;

  Logger logger = Logger();

  LoadingOverlayController loading = LoadingOverlayController();

  DI di = DI();

  NavigatorHelper navigator = NavigatorHelper();

  AppDimensions dimensions = AppDimensions();

  AppColors colors = AppColors();

  AppAssets assets = AppAssets();

  DateFormatter dateFormatter = DateFormatter();

  StorageFormatter storageFormatter = StorageFormatter();

  SnackBarAdapter snack = SnackBarAdapter();

  DialogHelper dialog = DialogHelper();

  MediaQueryData get mediaQuery => MediaQuery.of(context);
}
