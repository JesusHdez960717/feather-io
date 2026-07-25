import 'package:console/app_exporter.dart';

class BrowserInit {
  static Future init() async {
    BrowserClient client = BrowserClient(app.di.find());
    app.di.put(client);

    BrowserRepo repo = BrowserRepo(client);
    app.di.put(repo);
  }
}
