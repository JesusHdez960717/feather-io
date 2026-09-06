import 'package:console/app_exporter.dart';
import 'data/repo/bucket_repo.dart';
import 'data/rest/bucket_client.dart';

class BucketsInit {
  static Future init() async {
    BucketClient client = BucketClient(app.di.find());
    app.di.put(client);

    BucketRepo repo = BucketRepo(client);
    app.di.put(repo);
  }
}
