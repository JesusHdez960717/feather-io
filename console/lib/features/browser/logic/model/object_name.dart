///Por que un nombre de carpeta u objeto no vale
enum ObjectNameError { empty, invalid, exists, unchanged }

///Valida el nombre de una carpeta u objeto dentro de su carpeta: sin `/`, sin
///los caracteres que el servicio rechaza y sin repetir uno de [existing]
abstract class ObjectName {
  static final RegExp _forbidden = RegExp(r'[\x00-\x1F\x7F<>:"|?*/\\]');

  static ObjectNameError? validate(
    String name, {
    required Set<String> existing,
    String? current,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return ObjectNameError.empty;
    if (trimmed == current) return ObjectNameError.unchanged;
    if (_forbidden.hasMatch(trimmed) ||
        trimmed == '.' ||
        trimmed == '..' ||
        trimmed.length > 255) {
      return ObjectNameError.invalid;
    }
    if (existing.contains(trimmed)) return ObjectNameError.exists;
    return null;
  }
}
