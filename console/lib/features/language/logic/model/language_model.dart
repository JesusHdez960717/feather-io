import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';

class LanguageModel {
  final SvgAsset icon;
  final String key;

  ///Nombre del idioma en ese mismo idioma (`English`, `Español`): no se
  ///traduce, para que cada cual reconozca el suyo
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
