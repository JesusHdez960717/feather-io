import 'package:service/feather.dart';

class AdminController {
  /// Version of the admin API in its OpenAPI document.
  static const String apiVersion = '1.0.0';

  /// Route key of the health check (`GET /{admin}/health`).
  static const String healthKey = 'admin.health';

  final String adminPrefix = env.adminPrefix;

  final AuthController authController;
  final AnonymousAccessController anonymousAccessController;
  final AccessKeyController accessKeyController;

  /// The admin API, plus its OpenAPI document (`/{admin}/openapi.json`) and
  /// Swagger UI (`/{admin}/docs`). Both are public, like the login and the
  /// health check: they describe the API, never its data.
  Route get routing => Route.parent(
    path: '/$adminPrefix',
    filterConfig: _filters,
    routes: [
      ..._routes,
      Route.openApi(
        key: 'admin.openapi',
        openApi: OpenApi(
          title: 'Feather IO admin API',
          version: apiVersion,
          description:
              'The API of the console. Log in with `POST /$adminPrefix/login` '
              'and use its `access_token` in **Authorize**. Every error is a '
              'Problem Details (RFC 9457) with the S3 error `code` and the '
              '`resource` (bucket or key) it refers to.',
          // Only the admin API: the S3 API is the one AWS documents
          router: WinterRouter(
            routes: [
              Route.parent(
                path: '/$adminPrefix',
                filterConfig: _filters,
                routes: _routes,
              ),
            ],
          ),
        ),
      ),
      Route.swaggerUi(
        key: 'admin.docs',
        specUrl: '/$adminPrefix/openapi.json',
        title: 'Feather IO admin API',
      ),
    ],
  );

  FilterConfig get _filters =>
      [S3BucketNameFilter(), JwtFilter()].toFilterConfig();

  List<Route> get _routes => [
    // For the orchestrator (Docker, Kubernetes, a load balancer): 503 when the
    // database or the volume fail. Public, and never logged when it is up
    Route.health(
      key: healthKey,
      path: '/health',
      checks: {
        'database': di.find<AppDatabase>().ping,
        'storage': objectService.storageWritable,
      },
    ),
    Route.post(
      key: 'admin.auth.login',
      path: '/login',
      handler: authController.login,
      docs: RouteDocs(
        summary: 'Log in with the root key',
        description:
            'Checks `FEATHER_ACCESS`/`FEATHER_SECRET` and issues a JWT valid '
            'for 12 hours. Every failure waits a second, and 10 failures in a '
            'row lock the IP for 15 minutes.',
        tags: ['Auth'],
        request: BodyDocs(
          example: LoginRequest.example,
          schema: JsonSchema.object(
            {'access': JsonSchema.string(), 'secret': JsonSchema.string()},
            required: ['access', 'secret'],
          ),
        ),
        response: LoginResponse.example,
        responses: {
          403: 'Wrong credentials (`InvalidCredentials`)',
          429: 'Too many failed logins from this IP (`Retry-After`)',
        },
      ),
    ),
    Route.get(
      key: 'admin.bucket.get',
      path: '/bucket/{bucket}',
      handler: getBucket,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.bucket.get')),
        ReservedBucketFilter(),
      ]),
      docs: RouteDocs(
        summary: 'A bucket with its metadata and stats',
        tags: ['Buckets'],
        response: BucketModel.example,
      ),
    ),
    Route.delete(
      key: 'admin.bucket.empty',
      path: '/bucket/{bucket}/objects',
      handler: emptyBucket,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.bucket.empty')),
        ReservedBucketFilter(),
      ]),
      docs: const RouteDocs(
        summary: 'Delete every object of a bucket, keeping the bucket',
        tags: ['Buckets'],
        status: 204,
      ),
    ),
    Route.delete(
      key: 'admin.bucket.delete-folder',
      path: '/bucket/{bucket}/folder',
      handler: deleteFolder,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.bucket.delete-folder')),
        ReservedBucketFilter(),
      ]),
      docs: RouteDocs(
        summary: 'Delete a folder with all its content',
        description:
            'Through the S3 API, deleting `photos/` only removes the empty '
            'folder (its marker).',
        tags: ['Buckets'],
        status: 204,
        query: [
          QueryParam(
            'prefix',
            JsonSchema.string(minLength: 1),
            required: true,
            description: 'The folder, ending in `/` (`photos/`)',
          ),
        ],
      ),
    ),
    Route.post(
      key: 'admin.bucket.presign',
      path: '/bucket/{bucket}/presign',
      handler: presignObject,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.bucket.presign')),
        ReservedBucketFilter(),
      ]),
      docs: RouteDocs(
        summary: 'A presigned URL to download an object',
        description:
            'Signed with the root key. It points to `PUBLIC_URL` or, without '
            'it, to the host of this request (the host is part of the '
            'signature).',
        tags: ['Buckets'],
        request: PresignRequest.example,
        response: PresignedUrlModel.example,
      ),
    ),
    Route.put(
      key: 'admin.bucket.update',
      path: '/bucket/{bucket}',
      handler: updateBucket,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.bucket.update')),
        ReservedBucketFilter(),
      ]),
      docs: RouteDocs(
        summary: 'Replace the metadata of a bucket',
        description: 'A missing or null field clears it.',
        tags: ['Buckets'],
        request: UpdateBucketRequest.example,
        response: BucketModel.example,
      ),
    ),
    Route.post(
      key: 'admin.bucket.download',
      path: '/bucket/{bucket}/download',
      handler: downloadObjects,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.bucket.download')),
      ]),
      docs: RouteDocs(
        summary: 'Download objects and folders in a zip',
        tags: ['Buckets'],
        request: DownloadObjectsRequest.example,
        response: BodyDocs(
          schema: JsonSchema.string(format: 'binary'),
          contentType: 'application/zip',
        ),
      ),
    ),
    Route.get(
      key: 'admin.bucket.anonymous-access.get-rules',
      path: '/bucket/{bucket}/anonymous-access',
      handler: anonymousAccessController.getRules,
      filterConfig: FilterConfig([
        AuthFilter(
          rules: hasPermission('admin.bucket.anonymous-access.get-rules'),
        ),
      ]),
      docs: RouteDocs(
        summary: 'The anonymous access rules of a bucket',
        tags: ['Anonymous access'],
        response: [AnonymousRuleModel.example],
      ),
    ),
    Route.post(
      key: 'admin.bucket.anonymous-access.write-rule',
      path: '/bucket/{bucket}/anonymous-access',
      handler: anonymousAccessController.createRule,
      filterConfig: FilterConfig([
        AuthFilter(
          rules: hasPermission('admin.bucket.anonymous-access.write-rule'),
        ),
      ]),
      docs: RouteDocs(
        summary: 'Create or replace the rule of a prefix',
        description:
            'A prefix without `*` opens every key that starts with it; with '
            '`*` (any characters, `/` included) the whole key must match.',
        tags: ['Anonymous access'],
        request: CreateRuleRequest.example,
        response: AnonymousRuleModel.example,
      ),
    ),
    Route.delete(
      key: 'admin.bucket.anonymous-access.delete-rule',
      path: '/bucket/{bucket}/anonymous-access',
      handler: anonymousAccessController.deleteRule,
      filterConfig: FilterConfig([
        AuthFilter(
          rules: hasPermission('admin.bucket.anonymous-access.delete-rule'),
        ),
      ]),
      docs: RouteDocs(
        summary: 'Delete the rule of a prefix',
        tags: ['Anonymous access'],
        request: DeleteRuleRequest.example,
      ),
    ),
    Route.get(
      key: 'admin.access-key.list',
      path: '/access-keys',
      handler: accessKeyController.list,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.access-key.list')),
      ]),
      docs: RouteDocs(
        summary: 'The root key and the managed access keys',
        tags: ['Access keys'],
        response: AccessKeyListModel.example,
      ),
    ),
    Route.post(
      key: 'admin.access-key.create',
      path: '/access-keys',
      handler: accessKeyController.create,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.access-key.create')),
      ]),
      docs: RouteDocs(
        summary: 'Create an access key',
        description:
            'Its `secret_access_key` is only in this response (and in the one '
            'of regenerating it).',
        tags: ['Access keys'],
        status: 201,
        request: AccessKeyRequest.example,
        response: AccessKeyModel.example,
      ),
    ),
    Route.put(
      key: 'admin.access-key.update',
      path: '/access-keys/{id}',
      handler: accessKeyController.update,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.access-key.update')),
      ]),
      docs: RouteDocs(
        summary: 'Update an access key',
        tags: ['Access keys'],
        request: AccessKeyRequest.example,
        response: AccessKeyModel.example.withoutSecret(),
      ),
    ),
    Route.post(
      key: 'admin.access-key.regenerate-secret',
      path: '/access-keys/{id}/secret',
      handler: accessKeyController.regenerateSecret,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.access-key.regenerate-secret')),
      ]),
      docs: RouteDocs(
        summary: 'Give an access key a new secret',
        description: 'The old secret stops working at once.',
        tags: ['Access keys'],
        response: AccessKeyModel.example,
      ),
    ),
    Route.delete(
      key: 'admin.access-key.delete',
      path: '/access-keys/{id}',
      handler: accessKeyController.delete,
      filterConfig: FilterConfig([
        AuthFilter(rules: hasPermission('admin.access-key.delete')),
      ]),
      docs: const RouteDocs(
        summary: 'Delete an access key',
        tags: ['Access keys'],
        status: 204,
      ),
    ),
  ];

  AdminController()
    : objectService = di.find(),
      bucketService = di.find(),
      presignService = PresignService(),
      authController = AuthController(),
      anonymousAccessController = AnonymousAccessController(),
      accessKeyController = AccessKeyController();

  final ObjectService objectService;
  final BucketService bucketService;
  final PresignService presignService;

  /// Presigned URL to download an object. It points to `PUBLIC_URL` or, without
  /// it, to the host this request arrived at; the host is part of the signature.
  Future<ResponseEntity> presignObject(RequestEntity request) async {
    // Validated by body<T>() (422)
    final presign = await request.body<PresignRequest>();

    // PUBLIC_URL if set; otherwise this request's scheme and host
    final publicUrl = env.publicUrl;
    final url = await presignService.presignGet(
      scheme: publicUrl?.scheme ?? request.requestedUri.scheme,
      host:
          publicUrl?.authority ??
          request.headers['host'] ??
          request.requestedUri.authority,
      bucketName: request.pathParams['bucket']!,
      key: presign.key!,
      expiresIn: Duration(seconds: presign.expiresIn!),
    );
    return ResponseEntity.ok(body: url);
  }

  Future<ResponseEntity> getBucket(RequestEntity request) async {
    final bucket = await bucketService.getBucket(
      bucketName: request.pathParams['bucket']!,
    );
    return ResponseEntity.ok(body: bucket);
  }

  Future<ResponseEntity> emptyBucket(RequestEntity request) async {
    await bucketService.emptyBucket(bucketName: request.pathParams['bucket']!);
    return ResponseEntity.noContent();
  }

  /// Deletes a folder with all its content: `?prefix=photos/`. Through the S3
  /// API, deleting `photos/` only removes the empty folder (its marker).
  Future<ResponseEntity> deleteFolder(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;
    final prefix = request.queryParam<String>('prefix');
    if (prefix == null || prefix.isEmpty) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: intl.errors.s3.missingFolderPrefix,
        resource: bucketName,
      );
    }
    await objectService.deleteFolder(bucketName: bucketName, prefix: prefix);
    return ResponseEntity.noContent();
  }

  Future<ResponseEntity> updateBucket(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    // Validated by body<T>() (422)
    final updateRequest = await request.body<UpdateBucketRequest>();

    final bucket = await bucketService.updateBucket(
      bucketName: bucketName,
      description: updateRequest.description,
      color: updateRequest.color,
    );

    return ResponseEntity.ok(body: bucket);
  }

  Future<ResponseEntity> downloadObjects(RequestEntity request) async {
    final bucketName = request.pathParams['bucket']!;

    try {
      final downloadRequest = await request.body<DownloadObjectsRequest>();

      final zipFile = await objectService.zipObjects(
        bucketName: bucketName,
        keys: downloadRequest.keys,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'download_$timestamp.zip';

      return ResponseEntity<Stream<List<int>>>(
        200,
        body: objectService.openAndDeleteTemp(zipFile),
        headers: {
          'content-type': 'application/zip',
          'content-disposition': 'attachment; filename="$fileName"',
          'content-length': (await zipFile.length()).toString(),
        },
      );
    } catch (e) {
      // A body that isn't the expected JSON keeps its 400 with the field
      if (e is ApiException || e is DeserializationException) rethrow;
      throw S3Exception(
        S3ErrorCode.invalidRequest,
        message: intl.errors.admin.invalidRequest,
      );
    }
  }
}
