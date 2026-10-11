import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class LanguageModel {
  final SvgAsset icon;
  final String key;

  /// Name of the language in that same language (`English`, `Español`): it is
  /// not translated, so everyone recognizes their own
  final String name;

  LanguageModel({required this.icon, required this.key, required this.name});

  Locale get locale => Locale(key);

  @override
  String toString() {
    return 'LanguageModel[key = $key]';
  }

  @override
  int get hashCode {
    return key.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is LanguageModel) {
      return key == other.key;
    }
    return false;
  }
}
