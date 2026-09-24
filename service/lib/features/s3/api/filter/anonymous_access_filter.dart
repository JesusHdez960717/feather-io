import 'package:service/feather.dart';

class AnonymousAccessFilter extends Filter {
  final String bucketName;
  final List<AnonymousRuleModel> rules;

  AnonymousAccessFilter({required this.bucketName, this.rules = const []});

  static const _readKeys = {
    's3.anonymous.list-objects',
    's3.anonymous.get-object',
  };

  static const _writeKeys = {
    's3.anonymous.put-object',
    's3.anonymous.delete-object',
    's3.anonymous.multi-delete-objects',
  };

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final bucket = request.pathParams['bucket'];
    final routeKey = request.routingContext?.key;

    // Si es list-objects, el "key" a evaluar es el prefix del query param
    // Si es una operación sobre un objeto, es el key del path param
    final key =
        request.pathParams['key'] ?? request.queryParams['prefix'] ?? '';

    if (bucket == bucketName && routeKey != null) {
      final rule = _findMatchingRule(key);
      if (rule != null && _isActionAllowed(rule.access, routeKey)) {
        request.securityContext.setAuthentication(
          Authentication(
            principal: 'Anonymous',
            roles: {'anonymous'},
            permissions: _getPermissionsForAccess(rule.access),
            authenticated: true,
          ),
        );
      }
    }
    return await chain.doFilter(request);
  }

  Set<String> _getPermissionsForAccess(AnonymousAccessType access) {
    switch (access) {
      case AnonymousAccessType.readOnly:
        return _readKeys;
      case AnonymousAccessType.writeOnly:
        return _writeKeys;
      case AnonymousAccessType.readWrite:
        return {..._readKeys, ..._writeKeys};
    }
  }

  bool _isActionAllowed(AnonymousAccessType access, String routeKey) {
    switch (access) {
      case AnonymousAccessType.readOnly:
        return _readKeys.contains(routeKey);
      case AnonymousAccessType.writeOnly:
        return _writeKeys.contains(routeKey);
      case AnonymousAccessType.readWrite:
        return _readKeys.contains(routeKey) || _writeKeys.contains(routeKey);
    }
  }

  AnonymousRuleModel? _findMatchingRule(String key) {
    for (var rule in rules) {
      var pattern = rule.prefix;
      // S3 keys usually don't start with '/', so we normalize the pattern
      if (pattern.startsWith('/')) {
        pattern = pattern.substring(1);
      }

      // Basic support for wildcards:
      // We convert '.' to '\.' to treat it as a literal dot,
      // and '*' to '.*' to treat it as a wildcard.
      final regexSource = pattern.replaceAll('.', '\\.').replaceAll('*', '.*');

      try {
        final regex = RegExp('^$regexSource');
        if (regex.hasMatch(key)) {
          return rule;
        }
      } catch (_) {
        // Fallback: if it's not a valid regex, treat it as a simple prefix
        final simplePrefix = pattern.split('*').first;
        if (key.startsWith(simplePrefix)) {
          return rule;
        }
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'AnonymousAccessFilter{bucket: $bucketName, rules: ${rules.length}}';
  }
}
