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
  ///[database] permite a los tests usar una BD en memoria en vez del fichero SQLite
  static Future start({int port = 8080, AppDatabase? database}) async {
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
    om.addDeserializer(
      Deserializer<CreateBucketRequest>(
        (data) => CreateBucketRequest.fromJson(data),
      ),
    );
    om.addDeserializer(
      Deserializer<PresignRequest>((data) => PresignRequest.fromJson(data)),
    );
    om.addDeserializer(
      Deserializer<UpdateBucketRequest>(
        (data) => UpdateBucketRequest.fromJson(data),
      ),
    );

    //--------------- Errors ---------------\\
    Winter.context.setUp(exceptionHandler: S3ExceptionHandler());

    //--------------- DB ---------------\\
    di.put(database ?? AppDatabase());

    //--------------- File ---------------\\
    FileManagementService fileManagement = FileManagementService();
    di.put(fileManagement);

    //--------------- JWT ---------------\\
    JwtService jwtService = JwtService();
    di.put(jwtService);
    di.put(
      LoginRateLimiter(
        maxFailures: env.loginMaxFailures,
        lockDuration: Duration(seconds: env.loginLockSeconds),
        failureDelay: Duration(milliseconds: env.loginFailureDelayMs),
      ),
    );

    //--------------- s3 ---------------\\
    S3Controller s3controller = S3Controller();

    //--------------- admin ---------------\\
    AdminController adminController = AdminController();

    await Winter.start(
      //el limite global es el de un objeto, que va a disco como stream; el
      //resto de peticiones lo acota BodySizeFilter
      config: ServerConfig(port: port, maxBodySize: env.maxObjectSize),
      globalFilterConfig: FilterConfig([BodySizeFilter(), JwtFilter()]),
      //la consola lee el ETag de cada parte de una subida multipart
      securityConfig: SecurityConfig(
        cors: const CorsConfig(exposedHeaders: ['ETag']),
      ),
      router: WinterRouter(
        config: RouterConfig(onLoadedRoutes: DefaultOnLoadedRoutes.log()),
        routes: [adminController.routing, s3controller.routing],
      ),
    );
  }
}
