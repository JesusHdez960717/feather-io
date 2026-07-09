import 'package:console/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BrowserScreenNavigator {
  String get name => 'browser';

  String get path => '/browser';

  Widget builder(BuildContext context, GoRouterState state) {
    return const BrowserScreen();
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
  }
}

class BrowserScreen extends StatefulWidget {
  static final BrowserScreenNavigator navigator = BrowserScreenNavigator();

  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Browser')));
  }
}
