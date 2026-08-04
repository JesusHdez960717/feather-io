import 'feather.dart';

void main() async {
  await FeatherIO.start();
}

class FeatherIO {
  static Future start({int port = 8080}) async {
    om.addDeserializer(
      Deserializer<DownloadObjectsRequest>(
        (data) => DownloadObjectsRequest.fromJson(data),
      ),
    );

    FileManagementService fileManagement = FileManagementService();
    di.put(fileManagement);

    S3Controller s3controller = S3Controller(fileManagement: di.find());
    di.put(s3controller);

    AdminController adminController = AdminController(
      fileManagement: di.find(),
    );
    di.put(adminController);

    await Winter.start(
      config: ServerConfig(port: port),
      globalFilterConfig: [SecurityAccessFilter()].toFilterConfig(),
      securityConfig: SecurityConfig(cors: const CorsConfig()),
      router: WinterRouter(
        config: RouterConfig(onLoadedRoutes: DefaultOnLoadedRoutes.log()),
        routes: [adminController.routing, s3controller.routing],
      ),
    );
  }
}
