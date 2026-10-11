import 'package:console/app_exporter.dart';

class TransfersInit {
  static Future init() async {
    TransferClient client = TransferClient(app.di.find());
    app.di.put(client);

    TransferRepo repo = TransferRepo(client);
    app.di.put(repo);

    TransferCubit cubit = TransferCubit(repo, app.di.find());
    app.di.put(cubit);
  }
}
