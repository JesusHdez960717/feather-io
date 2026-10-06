/// Outside the browser there is no `window.env`: `--dart-define`s or the local
/// defaults
class Environment {
  static String get serviceUrl => const String.fromEnvironment(
    'SERVICE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static String get adminPrefix =>
      const String.fromEnvironment('ADMIN_PREFIX', defaultValue: '_admin');

  static Map<String, String> get raw => {
    'SERVICE_URL': serviceUrl,
    'ADMIN_PREFIX': adminPrefix,
  };
}
