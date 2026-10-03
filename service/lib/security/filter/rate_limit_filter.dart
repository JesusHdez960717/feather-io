import 'package:service/feather.dart';

/// Limite general de peticiones por IP (ventana deslizante, el [RateLimiter] de
/// Winter). Va el primero de los filtros globales: corta una avalancha antes de
/// leer cuerpos o comprobar firmas. Ver "Límite general" en `DECISIONES.md`.
///
/// Por encima del limite, la API S3 responde `503 SlowDown`, como S3: es lo que
/// los SDKs y la CLI de AWS reintentan con espera (un 429 la CLI no lo
/// reintenta y el fichero falla). La API de admin responde `429`. Todas las
/// respuestas llevan `X-RateLimit-*`, y las rechazadas `Retry-After`
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
    //por IP; detras de proxies propios, ver TRUSTED_PROXIES
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
        message: 'Demasiadas peticiones; reduce el ritmo y reinténtalo.',
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

  /// Redondea hacia arriba: esperando esos segundos nunca se llega antes
  static int _ceilSeconds(Duration duration) =>
      (duration.inMicroseconds / Duration.microsecondsPerSecond).ceil();

  @override
  String toString() =>
      'RateLimitFilter{maxRequests: ${rateLimiter.maxRequests}, window: ${rateLimiter.window}}';
}
