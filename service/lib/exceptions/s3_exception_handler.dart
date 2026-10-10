import 'package:service/feather.dart';

/// Renders the errors of the service. Every error is a Problem Details (Winter's
/// default), except on the S3 API for clients that don't ask for JSON:
/// - An [S3Exception] is the S3 `<Error>` XML (on the admin API, or with
///   `Accept: application/json`, a Problem Details with its `code` and
///   `resource`).
/// - A body over the limit (413) is `EntityTooLarge` on the S3 API.
/// - The 429 of the general rate limit ([RateLimiterFilter]) is `503 SlowDown`
///   on the S3 API, which S3 clients retry with backoff (the AWS CLI doesn't
///   retry a 429 and the file fails), and a translated 429 on the admin API.
///   Both keep `Retry-After` and `X-RateLimit-*`.
class S3ExceptionHandler extends SimpleExceptionHandler {
  final String adminPrefix = env.adminPrefix;

  @override
  Future<ResponseEntity> handle(
    RequestEntity request,
    Object error,
    StackTrace stackTrace,
  ) async {
    final admin = _isAdmin(request);

    var answered = error;
    if (error is PayloadTooLargeException && !admin) {
      // A body over the limit while it was read (without Content-Length)
      answered = S3Exception(
        S3ErrorCode.entityTooLarge,
        message: intl.errors.s3.objectOverMaximum(
          max: request.route?.key == BodySizeFilter.objectRouteKey
              ? env.maxObjectSize
              : BodySizeFilter.maxRequestBodySize,
        ),
        resource: request.pathParams['key'] ?? request.pathParams['bucket'],
      );
    } else if (error is TooManyRequestsException) {
      answered = admin
          ? TooManyRequestsException(
              detail: error.detail ?? intl.errors.admin.tooManyRequests,
              headers: error.headers,
            )
          : S3Exception(
              S3ErrorCode.slowDown,
              message: intl.errors.s3.slowDown,
              headers: error.headers,
            );
    }

    if (answered is S3Exception && !admin && !S3Response.acceptsJson(request)) {
      return S3Response.xml(
        answered.toXml(),
        status: answered.statusCode,
        headers: answered.headers,
      );
    }
    return super.handle(request, answered, stackTrace);
  }

  bool _isAdmin(RequestEntity request) {
    final segments = request.requestedUri.pathSegments;
    return segments.isNotEmpty && segments.first == adminPrefix;
  }
}
