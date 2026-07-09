import 'dart:js_interop';

@JS('window.env')
external EnvConfig get env;

@JS()
@staticInterop
class EnvConfig {}

extension EnvConfigExtension on EnvConfig {
  external String get SERVICE_URL;
}

///use it like this
class Environment {
  static String get serviceUrl => env.SERVICE_URL.startsWith('http')
      ? env.SERVICE_URL
      : 'https://${env.SERVICE_URL}';

  static Map<String, String> get raw => {'SERVICE_URL': env.SERVICE_URL};
}
