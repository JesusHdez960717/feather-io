import 'package:feather_io/feather.dart';
import 'package:winter/winter.dart';

class SecurityFilter implements Filter {
  final String secretHeader = 'FEATHER_SECRET';
  final String accessHeader = 'FEATHER_ACCESS';

  late final String _envSecret;
  late final String _envAccess;

  SecurityFilter(Env env) {
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
    if (secret == null || access == null) {
      return ResponseEntity.unauthorized(
        body: '$secretHeader && $accessHeader are required',
      );
    }

    if (secret != _envSecret || access != _envAccess) {
      return ResponseEntity.forbidden(
        body: 'Wrong $secretHeader or $accessHeader provided',
      );
    }

    return await chain.doFilter(request);
  }
}
