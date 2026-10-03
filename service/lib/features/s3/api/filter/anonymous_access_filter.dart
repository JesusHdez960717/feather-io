import 'package:service/feather.dart';

/// Authenticates as anonymous the requests without credentials that a rule of
/// the bucket covers, with the `s3.anonymous.*` permissions of its type. Each
/// route's `AuthFilter` decides afterwards; without a rule it is still a 401.
///
/// Multi-delete is never opened: its keys come in the body, not in the path.
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
      // For list-objects the query's prefix is checked; for an object, its key
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

  /// Only when nobody has authenticated before (JWT or SigV4).
  @override
  bool shouldFilter(RequestEntity request) {
    return !request.securityContext.isAuthenticated;
  }

  @override
  String toString() {
    return 'AnonymousAccessFilter()';
  }
}
