import 'package:console/app_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteConfig.afterLogin', () {
    final browser = BrowserScreen.navigator.path;

    test('Goes back to the page asked for, with its query', () {
      expect(RouteConfig.afterLogin('/keys'), '/keys');
      expect(
        RouteConfig.afterLogin('/buckets?bucket=backups&tab=access'),
        '/buckets?bucket=backups&tab=access',
      );
    });

    test('Without a page, goes to the browser', () {
      expect(RouteConfig.afterLogin(null), browser);
      expect(RouteConfig.afterLogin(''), browser);
    });

    test('Never leaves the console (no open redirect)', () {
      expect(RouteConfig.afterLogin('https://evil.example/phish'), browser);
      expect(RouteConfig.afterLogin('//evil.example/phish'), browser);
      expect(RouteConfig.afterLogin('javascript:alert(1)'), browser);
      expect(RouteConfig.afterLogin('keys'), browser);
    });

    test('Never goes back to the login itself', () {
      expect(RouteConfig.afterLogin(LoginScreen.navigator.path), browser);
    });
  });
}
