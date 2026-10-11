import 'package:console/app_exporter.dart';

class AuthInit {
  static Future<void> init() async {
    AuthClient client = AuthClient(app.di.find());
    app.di.put(client);

    AuthRepo repo = AuthRepo(client, storage: app.di.find());
    app.di.put(repo);

    AuthCubit cubit = AuthCubit(repo);
    // Before the router is built: a saved session skips the login
    await cubit.restore();
    app.di.put(cubit);
  }
}
