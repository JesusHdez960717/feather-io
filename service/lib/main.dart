import 'dart:math';

import 'feather.dart';

//versions
//fvm flutter pub outdated
//fvm flutter pub upgrade --major-versions

//migration
//dart fix --dry-run
//dart fix --apply
//
//fvm flutter analyze
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

    //--------------- DI ---------------\\
    JwtService jwtService = JwtService();
    di.put(jwtService);

    FileManagementService fileManagement = FileManagementService();
    di.put(fileManagement);

    S3Controller s3controller = S3Controller(fileManagement: di.find());
    di.put(s3controller);

    AdminController adminController = AdminController(
      fileManagement: di.find(),
      jwtService: di.find(),
    );
    di.put(adminController);

    final database = AppDatabase();
    di.put(database);

    await Winter.start(
      config: ServerConfig(port: port),
      globalFilterConfig: FilterConfig([JwtFilter()]),
      securityConfig: SecurityConfig(cors: const CorsConfig()),
      router: WinterRouter(
        config: RouterConfig(onLoadedRoutes: DefaultOnLoadedRoutes.log()),
        routes: [
          Route.get(
            path: '/test',
            handler: (request) async {
              AppDatabase database = di.find<AppDatabase>();

              await database
                  .into(database.bucket)
                  .insert(
                    BucketCompanion.insert(
                      name: 'random: ${Random().nextInt(50)}',
                    ),
                  );

              List<BucketData> allItems = await database
                  .select(database.bucket)
                  .get();

              return ResponseEntity.ok(
                body: allItems.fold(
                  '',
                  (previousValue, element) =>
                      '$previousValue - ${element.name}',
                ),
              );
            },
          ),
          adminController.routing,
          s3controller.routing,
        ],
      ),
    );
  }
}
