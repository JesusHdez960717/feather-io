/// Why a folder or object name is not valid
enum ObjectNameError { empty, invalid, exists, unchanged }

/// Validates the name of a folder or object inside its folder: no `/`, none of
/// the characters the service rejects and not repeating one of [existing]
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
