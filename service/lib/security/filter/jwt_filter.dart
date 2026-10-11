import 'package:service/feather.dart';

class JwtFilter extends Filter {
  static final JwtFilter _instance = JwtFilter._();

  late final JwtService jwtService;

  JwtFilter._() {
    jwtService = di.find();
  }

  factory JwtFilter() => _instance;

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final authHeader = request.headers[HttpHeader.authorization];

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      final payload = jwtService.verifyToken(token);

      if (payload != null) {
        request.securityContext.setAuthentication(
          Authentication(
            principal: payload['sub'],
            roles: Set.from(payload['roles'] ?? []),
            permissions: Set.from(payload['permissions'] ?? []),
          ),
        );
      } else {
        request.securityContext.clear();
      }
    } else {
      request.securityContext.clear();
    }

    return await chain.doFilter(request);
  }

  /// Only runs while the request is not authenticated yet: it is registered
  /// globally and again on both parents, so it must not run twice.
  @override
  bool shouldFilter(RequestEntity request) {
    return !request.securityContext.isAuthenticated;
  }

  @override
  String toString() {
    return 'JwtFilter()';
  }
}
