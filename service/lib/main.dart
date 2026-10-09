import 'feather.dart';

// Handy commands:
// - dependencies: fvm dart pub outdated / fvm dart pub upgrade --major-versions
// - migrations: fvm dart fix --dry-run / fvm dart fix --apply
// - analysis: fvm dart analyze
// - Drift code: fvm dart run build_runner build
void main() async {
  // .env (and .env.<WINTER_PROFILE>) under the variables of the process, for
  // local development; in a container only the process ones exist
  Winter.context.setUp(env: Env.load());
  await FeatherIO.start();
}

class FeatherIO {
  /// [database] lets the tests use an in-memory database instead of the SQLite file.
  static Future<void> start({int port = 8080, AppDatabase? database}) async {
    // Every missing variable in one error, before anything is created
    env.requireAll(requiredEnvVariables);

    //--------------- Context ---------------\\
    Winter.context.setUp(
      logger: env.serviceLogger,
      exceptionHandler: S3ExceptionHandler(),
      localeConfig: serviceLocales(),
    );

    //--------------- OM ---------------\\
    om
      ..addDeserializer(
        Deserializer<DownloadObjectsRequest>.json(
          DownloadObjectsRequest.fromJson,
        ),
      )
      ..addDeserializer(Deserializer<LoginRequest>.json(LoginRequest.fromJson))
      ..addDeserializer(
        Deserializer<CreateRuleRequest>.json(CreateRuleRequest.fromJson),
      )
      ..addDeserializer(
        Deserializer<DeleteRuleRequest>.json(DeleteRuleRequest.fromJson),
      )
      ..addDeserializer(
        Deserializer<CreateBucketRequest>.json(CreateBucketRequest.fromJson),
      )
      ..addDeserializer(
        Deserializer<UpdateBucketRequest>.json(UpdateBucketRequest.fromJson),
      )
      ..addDeserializer(
        Deserializer<PresignRequest>.json(PresignRequest.fromJson),
      )
      ..addDeserializer(
        Deserializer<CompletedPart>.json(CompletedPart.fromJson),
      )
      ..addDeserializer(
        Deserializer<AccessKeyRequest>.json(AccessKeyRequest.fromJson),
      )
      ..addDeserializer(
        Deserializer<AccessKeyGrantRequest>.json(
          AccessKeyGrantRequest.fromJson,
        ),
      );

    // A malformed PUBLIC_URL fails at start-up, not on the first presigned URL
    env.publicUrl;

    //--------------- DB ---------------\\
    di.put<AppDatabase>(database ?? AppDatabase());

    //--------------- Access keys ---------------\
    // Their secrets are stored encrypted with KEYS_ENCRYPTION_SECRET
    di.put(SecretCipher(env.keysEncryptionSecret));

    //--------------- File ---------------\\
    di.put(FileManagementService());

    //--------------- JWT ---------------\\
    di.put(JwtService());
    di.put(
      LoginRateLimiter(
        maxFailures: env.loginMaxFailures,
        lockDuration: Duration(seconds: env.loginLockSeconds),
        failureDelay: Duration(milliseconds: env.loginFailureDelayMs),
      ),
    );

    //--------------- Routes ---------------\\
    final adminController = AdminController();
    final router = WinterRouter(
      config: RouterConfig(onLoadedRoutes: DefaultOnLoadedRoutes.log()),
      routes: [adminController.routing, S3Controller().routing],
    );

    await Winter.start(
      // The global limit is an object's, which goes to disk as a stream;
      // BodySizeFilter narrows it for every other request
      config: ServerConfig(port: port, maxBodySize: env.maxObjectSize),
      globalFilterConfig: FilterConfig([
        // First: stops a flood before reading bodies or checking signatures
        // (503 SlowDown on S3, 429 on admin: see S3ExceptionHandler)
        if (env.rateLimitRequests > 0)
          RateLimiterFilter(
            maxRequests: env.rateLimitRequests,
            window: Duration(seconds: env.rateLimitWindowSeconds),
            // Per IP; behind your own proxies, see TRUSTED_PROXIES
            clientId: (request) =>
                request.clientIp(trustedProxies: env.trustedProxies) ??
                'unknown',
          ),
        // Method, path, status and time of every request (never the query,
        // which holds the signature of a presigned URL)
        LoggingFilter(),
        BodySizeFilter(),
        JwtFilter(),
      ]),
      // The console reads the ETag of each part of a multipart upload
      securityConfig: SecurityConfig(
        cors: const CorsConfig(exposedHeaders: ['ETag']),
      ),
      router: router,
    );
  }
}
