import 'package:console/app_exporter.dart';

class AccessKeysInit {
  static Future init() async {
    AccessKeyClient client = AccessKeyClient(app.di.find());
    app.di.put(client);

    AccessKeyRepo repo = AccessKeyRepo(client);
    app.di.put(repo);
  }
}
