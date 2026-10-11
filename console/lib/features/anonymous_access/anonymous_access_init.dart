import 'package:console/app_exporter.dart';

class AnonymousAccessInit {
  static Future init() async {
    AnonymousAccessClient client = AnonymousAccessClient(app.di.find());
    app.di.put(client);

    AnonymousAccessRepo repo = AnonymousAccessRepo(client);
    app.di.put(repo);
  }
}
