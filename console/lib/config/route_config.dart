import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteConfig {
  static RouterConfig<Object> router = GoRouter(
    initialLocation:
        //true app.di.find<AuthCubit>().isLoggedIn
        BrowserScreen.navigator.path,
        //: LoginScreen.navigator.path,
    navigatorKey: navigatorKey,
    routes: [
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
        ],
      ),
    ],
  );
}
