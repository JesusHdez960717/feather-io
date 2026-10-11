import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Every request carries `Authorization` (and JSON), so all of them need a CORS
/// preflight, which the service answers: the per-request warning is noise
void useBrowserHttpAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(enableCORSWarning: false);
}
