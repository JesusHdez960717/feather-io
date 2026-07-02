import 'feather.dart';

void main() async {
  FileManagementService fileManagement = FileManagementService();
  di.put(fileManagement);

  S3Controller s3controller = S3Controller(fileManagement: di.find());
  di.put(s3controller);

  await Winter.start(
    config: ServerConfig(port: 8080),
    globalFilterConfig: FilterConfig([
      SecurityAccessFilter(),
      AuthFilter(
        authenticated: true,
        shouldFilter: (request) {
          String? routeKey = request.routingContext?.key;
          List<String> whiteList = ['s3.get-file'];

          return !whiteList.contains(routeKey);
        },
      ),
    ]),
    router: WinterRouter(
      config: RouterConfig(onLoadedRoutes: DefaultOnLoadedRoutes.log()),
      routes: [s3controller.routing],
    ),
  );
}
