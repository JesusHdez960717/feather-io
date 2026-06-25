@TestOn('vm')
library;

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  int port = 8080;
  String localUrl = 'http://localhost:$port';

  Uri url(String path) => Uri.parse(localUrl + path);

  test('Test /test', () async {
    String urlToTest = '/test';
    http.Response response = await http.get(url(urlToTest));

    expect(response.statusCode, 200);
    expect(response.body, 'Test OK');
  });
}
