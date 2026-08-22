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
    final authHeader = request.headers[HttpHeaders.authorization];

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
        request.securityContext.clearContext();
      }
    } else {
      request.securityContext
          .clearContext(); //TODO: aqui deberia ir el anonimo para las url publicas, y luego la validacion en el endpoint
    }

    return await chain.doFilter(request);
  }

  ///Solo filtro si NO esta autenticado aun (por si ya paso por el s3-sig-v4 o el publico de get-object)
  @override
  bool shouldFilter(RequestEntity request) {
    return !request.securityContext.isAuthenticated;
  }

  @override
  String toString() {
    return 'JwtFilter()';
  }
}
