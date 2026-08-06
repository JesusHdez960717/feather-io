import 'package:service/feather.dart';

class SecurityAccessFilter extends Filter {
  final String secretHeader = 'FEATHER_SECRET';
  final String accessHeader = 'FEATHER_ACCESS';

  late final String _envSecret;
  late final String _envAccess;

  SecurityAccessFilter() {
    _envSecret = env.secret;
    _envAccess = env.access;
  }

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    String? secret = request.headers[secretHeader];
    String? access = request.headers[accessHeader];

    if (secret != null || access != null) {
      if (secret == _envSecret && access == _envAccess) {
        request.securityContext.setAuthentication(
          Authentication(principal: 'ADMIN', roles: {'admin'}),
        );
      } else {
        // Marcamos que hubo un intento de autenticación pero falló (no es nulo)
        request.securityContext.setAuthentication(Authentication.anonymous());
      }
    } else {
      // No se proporcionaron credenciales (es nulo)
      request.securityContext.clearContext();
    }

    return await chain.doFilter(request);
    /*
    String? secret = request.headers[secretHeader];
    String? access = request.headers[accessHeader];

    if (secret == null || access == null) {
      return ResponseEntity.unauthorized();
    }
    if (secret != _envSecret || access != _envAccess) {
      return ResponseEntity.forbidden();
    }
    request.securityContext.setAuthentication(
      Authentication(principal: 'ADMIN', roles: {'admin'}),
    );
    return await chain.doFilter(request);
    */
  }

  @override
  bool shouldFilter(RequestEntity request) {
    return !(request.routingContext?.key == 'put-object');
  }
}
