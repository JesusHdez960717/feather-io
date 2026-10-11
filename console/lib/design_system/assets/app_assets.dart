import 'package:console/app_exporter.dart';

class AppAssets {
  static final AppAssets _instance = AppAssets._internal();

  AppAssets._internal();

  factory AppAssets() => _instance;

  final AppIcons icons = const AppIcons();

  /// The app icon (docs/brand.md), also the source of the web icons.
  final String appIcon = 'assets/app/app_icon.png';
}
