/// A violation of a 422 (an item of the `violations` of its Problem Details):
/// `{fieldName, message, code, params}`. The value that failed is never sent
class ValidationError {
  /// Request field that failed validation (e.g. `description`, `buckets[0].access`)
  final String source;

  /// The rule that failed (`size.max`, `notNull`…), when there is one
  final String? code;

  /// The text, already in the language of the request
  final String message;

  ValidationError({
    required this.source,
    required this.code,
    required this.message,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      ValidationError(
        source: json['fieldName'] as String? ?? '',
        code: json['code'] as String?,
        message: json['message'] as String? ?? '',
      );

  @override
  String toString() {
    return 'ValidationError{source: $source, code: $code, message: $message}';
  }
}

extension ValidationErrorConverter on List<ValidationError> {
  Map<String, String> asFailedValidations() =>
      Map.fromEntries(map((e) => MapEntry(e.source, e.message)));
}
