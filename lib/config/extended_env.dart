import 'package:winter/env/env.dart';

extension ExtendedEnv on Env {
  String get secret => find<String>('FEATHER_SECRET', required: true)!;

  String get access => find<String>('FEATHER_ACCESS', required: true)!;

  String get storagePath => find<String>('STORAGE_PATH', required: true)!;
}
