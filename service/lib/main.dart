import 'feather.dart';

//versions
//fvm flutter pub outdated
//fvm flutter pub upgrade --major-versions

//migration
//dart fix --dry-run
//dart fix --apply
//
//fvm flutter analyze
//
//fvm dart run build_runner build
void main() async {
  await FeatherIO.start();
}

class FeatherIO {
  static Future start({int port = 8080}) async {
    //--------------- OM ---------------\\
    om.addDeserializer(
      Deserializer<DownloadObjectsRequest>(
        (data) => DownloadObjectsRequest.fromJson(data),
      ),
    );
    om.addDeserializer(
      Deserializer<LoginRequest>((data) => LoginRequest.fromJson(data)),
    );
    om.addDeserializer(
      Deserializer<CreateRuleRequest>(
        (data) => CreateRuleRequest.fromJson(data),
      ),
    );
    om.addDeserializer(
      Deserializer<DeleteRuleRequest>(
        (data) => DeleteRuleRequest.fromJson(data),
      ),
    );

    //--------------- DB ---------------\\
    final database = AppDatabase();
    di.put(database);

    //--------------- File ---------------\\
    FileManagementService fileManagement = FileManagementService();
    di.put(fileManagement);

    //--------------- JWT ---------------\\
    JwtService jwtService = JwtService();
    di.put(jwtService);

    //--------------- s3 ---------------\\
    S3Controller s3controller = S3Controller();

    //--------------- admin ---------------\\
    AdminController adminController = AdminController();

    await Winter.start(
      config: ServerConfig(port: port),
      globalFilterConfig: FilterConfig([JwtFilter()]),
      securityConfig: SecurityConfig(cors: const CorsConfig()),
      router: WinterRouter(
        config: RouterConfig(onLoadedRoutes: DefaultOnLoadedRoutes.log()),
        routes: [adminController.routing, s3controller.routing],
      ),
    );
  }
}
