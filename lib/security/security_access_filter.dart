import 'package:feather_io/feather.dart';

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
    if (secret != null &&
        access != null &&
        secret == _envSecret &&
        access == _envAccess) {
      request.securityContext.setAuthentication(
        Authentication(principal: 'ADMIN', roles: {'admin'}),
      );
    } else {
      request.securityContext.clearContext();
    }

    return await chain.doFilter(request);
  }
}
