import 'package:console/app_exporter.dart';

class BucketsInit {
  static Future init() async {
    BucketClient client = BucketClient(app.di.find());
    app.di.put(client);

    BucketRepo repo = BucketRepo(client);
    app.di.put(repo);
  }
}
