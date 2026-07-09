import 'package:console/app_exporter.dart';

class AuthInit {
  static Future<void> init() async {
    AuthCubit cubit = AuthCubit();
    app.di.put(cubit);
  }
}
