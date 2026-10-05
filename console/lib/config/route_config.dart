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
        if (isLoggingIn) return null;
        // Remember where the user was going, to open it after logging in
        return Uri(
          path: LoginScreen.navigator.path,
          queryParameters: {RouteNames.loginFromParam: state.uri.toString()},
        ).toString();
      }

      if (isLoggingIn) {
        return _afterLogin(state.uri.queryParameters[RouteNames.loginFromParam]);
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
          StatefulShellBranch(
            routes: <RouteBase>[
              ///   /keys
              GoRoute(
                name: AccessKeysScreen.navigator.name,
                path: AccessKeysScreen.navigator.path,
                builder: AccessKeysScreen.navigator.builder,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// The location saved in `?from=` if it is one of ours (a path, not the login
/// itself); otherwise the browser
String _afterLogin(String? from) {
  final uri = from == null ? null : Uri.tryParse(from);
  final valid =
      uri != null &&
      !uri.hasScheme &&
      !uri.hasAuthority &&
      uri.path.startsWith('/') &&
      uri.path != LoginScreen.navigator.path;
  return valid ? from! : BrowserScreen.navigator.path;
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
