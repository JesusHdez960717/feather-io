import 'package:service/feather.dart';

/// Autentica como anonimo las peticiones sin credenciales que cubre una regla
/// de acceso anonimo del bucket, con los permisos `s3.anonymous.*` de su tipo.
/// El `AuthFilter` de cada ruta decide despues; sin regla, sigue siendo un 401.
///
/// El multi-delete no se abre nunca: sus keys van en el body y no en la ruta.
class AnonymousAccessFilter extends Filter {
  static final AnonymousAccessFilter _instance = AnonymousAccessFilter._();

  late final AnonymousAccessService _service = AnonymousAccessService();

  AnonymousAccessFilter._();

  factory AnonymousAccessFilter() => _instance;

  static const _readKeys = {'s3.list-objects', 's3.get-object'};

  static const _writeKeys = {'s3.put-object', 's3.delete-object'};

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final bucket = request.pathParams['bucket'];
    final routeKey = request.routingContext?.key;

    if (bucket != null && routeKey != null && _isAnonymousRoute(routeKey)) {
      // En list-objects se evalua el prefix del query; en un objeto, su key
      final key = routeKey == 's3.list-objects'
          ? request.queryParams['prefix'] ?? ''
          : request.pathParams['key'] ?? '';

      final rule = await _service.findMatchingRule(bucket: bucket, key: key);
      if (rule != null && _allowedKeys(rule.access).contains(routeKey)) {
        request.securityContext.setAuthentication(
          Authentication(
            principal: 'anonymous',
            roles: {'anonymous'},
            permissions: {
              for (final allowed in _allowedKeys(rule.access))
                allowed.replaceFirst('s3.', 's3.anonymous.'),
            },
            authenticated: true,
          ),
        );
      }
    }
    return await chain.doFilter(request);
  }

  bool _isAnonymousRoute(String routeKey) =>
      _readKeys.contains(routeKey) || _writeKeys.contains(routeKey);

  Set<String> _allowedKeys(AnonymousAccessType access) {
    return switch (access) {
      AnonymousAccessType.readOnly => _readKeys,
      AnonymousAccessType.writeOnly => _writeKeys,
      AnonymousAccessType.readWrite => {..._readKeys, ..._writeKeys},
    };
  }

  ///Solo si nadie se ha autenticado antes (JWT o SigV4)
  @override
  bool shouldFilter(RequestEntity request) {
    return !request.securityContext.isAuthenticated;
  }

  @override
  String toString() {
    return 'AnonymousAccessFilter()';
  }
}
