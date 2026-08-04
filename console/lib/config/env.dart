import 'dart:js_interop';

@JS('window.env')
external EnvConfig get env;

@JS()
@staticInterop
class EnvConfig {}

extension EnvConfigExtension on EnvConfig {
  external String get SERVICE_URL;

  external String? get ADMIN_PREFIX;
}

///use it like this
class Environment {
  static String get serviceUrl => env.SERVICE_URL.startsWith('http')
      ? env.SERVICE_URL
      : 'https://${env.SERVICE_URL}';

  static String get adminPrefix => env.ADMIN_PREFIX ?? '_admin';

  static Map<String, String> get raw => {
        'SERVICE_URL': env.SERVICE_URL,
        'ADMIN_PREFIX': adminPrefix,
      };
}
