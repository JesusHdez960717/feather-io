import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class RouteConfig {
  static final GoRouter router = GoRouter(
    initialLocation: BrowserScreen.navigator.path,
    navigatorKey: navigatorKey,
    refreshListenable: GoRouterRefreshStream(app.di.find<AuthCubit>().stream),
    redirect: (context, state) {
      final auth = app.di.find<AuthCubit>();
      final isLoggingIn = state.matchedLocation == LoginScreen.navigator.path;

      if (auth.auth == null) {
        return isLoggingIn ? null : LoginScreen.navigator.path;
      }

      if (isLoggingIn) {
        return BrowserScreen.navigator.path;
      }

      return null;
    },
    routes: [
      GoRoute(
        name: LoginScreen.navigator.name,
        path: LoginScreen.navigator.path,
        builder: LoginScreen.navigator.builder,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BaseScreen(navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: <RouteBase>[
              ///   /browser
              GoRoute(
                name: BrowserScreen.navigator.name,
                path: BrowserScreen.navigator.path,
                builder: BrowserScreen.navigator.builder,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              ///   /buckets
              GoRoute(
                name: BucketAdminScreen.navigator.name,
                path: BucketAdminScreen.navigator.path,
                builder: BucketAdminScreen.navigator.builder,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
