import 'feather.dart';

// Handy commands:
// - dependencies: fvm dart pub outdated / fvm dart pub upgrade --major-versions
// - migrations: fvm dart fix --dry-run / fvm dart fix --apply
// - analysis: fvm dart analyze
// - Drift code: fvm dart run build_runner build
void main() async {
  await FeatherIO.start();
}

class FeatherIO {
  /// [database] lets the tests use an in-memory database instead of the SQLite file.
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
      Deserializer<AccessKeyRequest>((data) => AccessKeyRequest.fromJson(data)),
    );
    om.addDeserializer(
      Deserializer<UpdateBucketRequest>(
        (data) => UpdateBucketRequest.fromJson(data),
      ),
    );

    //--------------- Errors ---------------\\
    Winter.context.setUp(
      exceptionHandler: S3ExceptionHandler(),
      localeConfig: serviceLocales(),
    );

    // A malformed PUBLIC_URL fails at start-up, not on the first presigned URL
    env.publicUrl;

    //--------------- DB ---------------\\
    di.put(database ?? AppDatabase());

    //--------------- Access keys ---------------\
    // Their secrets are stored encrypted with KEYS_ENCRYPTION_SECRET
    di.put(SecretCipher(env.keysEncryptionSecret));

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
      // The global limit is an object's, which goes to disk as a stream;
      // BodySizeFilter narrows it for every other request
      config: ServerConfig(port: port, maxBodySize: env.maxObjectSize),
      globalFilterConfig: FilterConfig([
        // First: stops a flood before reading bodies or checking signatures
        // (503 SlowDown on S3, 429 on admin)
        if (env.rateLimitRequests > 0)
          RateLimitFilter(
            maxRequests: env.rateLimitRequests,
            window: Duration(seconds: env.rateLimitWindowSeconds),
          ),
        BodySizeFilter(),
        JwtFilter(),
      ]),
      // The console reads the ETag of each part of a multipart upload
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
