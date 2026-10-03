import 'package:service/feather.dart';

/// General request limit per IP (a sliding window, Winter's [RateLimiter]). It
/// is the first global filter: it stops a flood before reading bodies or
/// checking signatures. See "General request limit" in `DECISIONS.md`.
///
/// Above the limit the S3 API answers `503 SlowDown`, like S3: that's what the
/// AWS SDKs and CLI retry with backoff (the CLI doesn't retry a 429 and the
/// file fails). The admin API answers `429`. Every response carries
/// `X-RateLimit-*`, and the rejected ones `Retry-After`.
class RateLimitFilter extends Filter {
  final RateLimiter rateLimiter;
  final String _adminPrefix = env.adminPrefix;
  final S3ExceptionHandler _s3Errors = S3ExceptionHandler();

  RateLimitFilter({required int maxRequests, required Duration window})
    : rateLimiter = RateLimiter(maxRequests, window);

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    // Per IP; behind your own proxies, see TRUSTED_PROXIES
    final client =
        request.clientIp(trustedProxies: env.trustedProxies) ?? 'unknown';
    final allowed = rateLimiter.allowRequest(client);
    final headers = {
      'X-RateLimit-Limit': '${rateLimiter.maxRequests}',
      'X-RateLimit-Remaining': '${rateLimiter.getRemaining(client)}',
      'X-RateLimit-Reset': '${_ceilSeconds(rateLimiter.getResetDuration(client))}',
    };

    if (allowed) {
      final response = await chain.doFilter(request);
      return response.copyWith(headers: {...response.headers, ...headers});
    }

    logger.debug(
      'Rate limit exceeded for $client in ${request.method} ${request.requestedUri.path}',
    );
    final wait = _ceilSeconds(rateLimiter.getWaitDuration(client));
    final retryAfter = '${wait > 0 ? wait : 1}';

    if (_isAdmin(request)) {
      return ResponseEntity.tooManyRequests(
        body: 'Too many requests',
        retryAfter: int.parse(retryAfter),
        headers: headers,
      );
    }
    final error = await _s3Errors(
      request,
      S3Exception(
        S3ErrorCode.slowDown,
        message: 'Please reduce your request rate.',
      ),
      StackTrace.current,
    );
    return error.copyWith(
      headers: {...error.headers, ...headers, 'Retry-After': retryAfter},
    );
  }

  bool _isAdmin(RequestEntity request) {
    final segments = request.requestedUri.pathSegments;
    return segments.isNotEmpty && segments.first == _adminPrefix;
  }

  /// Rounds up, so a client waiting that long is never too early.
  static int _ceilSeconds(Duration duration) =>
      (duration.inMicroseconds / Duration.microsecondsPerSecond).ceil();

  @override
  String toString() =>
      'RateLimitFilter{maxRequests: ${rateLimiter.maxRequests}, window: ${rateLimiter.window}}';
}
