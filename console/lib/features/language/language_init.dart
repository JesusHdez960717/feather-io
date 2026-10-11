import 'package:console/app_exporter.dart';

class LanguageInit {
  static Future<void> init() async {
    LanguageRepo repo = LanguageRepo(storage: app.di.find());
    app.di.put(repo);

    LanguageCubit cubit = LanguageCubit(repo: repo);
    app.di.put(cubit);
  }
}
