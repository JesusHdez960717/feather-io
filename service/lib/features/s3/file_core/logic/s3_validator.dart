import 'package:path/path.dart' as p;

class S3Validator {
  /// Valida el nombre del bucket según reglas de AWS S3.
  static bool isValidBucketName(String name) {
    if (name.length < 3 || name.length > 63) return false;

    // Solo minúsculas, números, puntos y guiones.
    // Debe empezar y terminar con letra o número.
    final regExp = RegExp(r'^[a-z0-9]([a-z0-9.-]{1,61}[a-z0-9])?$');
    if (!regExp.hasMatch(name)) return false;

    // No puede contener puntos consecutivos (..)
    if (name.contains('..')) return false;

    // No puede parecer una dirección IP
    final ipRegExp = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (ipRegExp.hasMatch(name)) return false;

    return true;
  }

  /// Valida el Key (objeto) según reglas de AWS S3 y seguridad local.
  static bool isValidKey(String key) {
    if (key.isEmpty || key.length > 1024) return false;

    // Caracteres seguros recomendados por S3: 0-9a-zA-Z!-_.*'()/
    // También bloqueamos secuencias de Path Traversal por seguridad.
    if (key.contains('..') ||
        key.contains(r'..\') ||
        key.contains('\x00') ||
        key.contains('%00')) {
      return false;
    }

    // Caracteres prohibidos comunes (que S3 recomienda evitar o que causan problemas en FS)
    // Bloqueamos caracteres de control, >, <, :, ", |, ?, *
    final invalidChars = RegExp(r'[\x00-\x1F\x7F<>:"|?*]');
    if (invalidChars.hasMatch(key)) return false;

    try {
      final uri = Uri.parse(key);
      if (uri.hasScheme || uri.hasAuthority) return false;

      for (var segment in uri.pathSegments) {
        if (segment == '.' || segment == '..') return false;
      }

      // Verificación de Path Traversal física
      const fakeRoot = '/safe_root';
      final fullPath = p.join(fakeRoot, key);
      final canonicalRoot = p.canonicalize(fakeRoot);
      final canonicalPath = p.canonicalize(fullPath);

      if (!canonicalPath.startsWith(canonicalRoot)) return false;

      return true;
    } catch (e) {
      return false;
    }
  }
}
