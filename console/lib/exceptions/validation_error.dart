/// A violation of a 422, in Winter's format: `{fieldName, value, message}`
class ValidationError {
  /// Request field that failed validation (e.g. `description`)
  final String source;
  final Object? invalidValue;
  final String message;

  ValidationError({
    required this.source,
    required this.invalidValue,
    required this.message,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      ValidationError(
        source: json['fieldName'] as String? ?? '',
        invalidValue: json['value'],
        message: json['message'] as String? ?? '',
      );

  @override
  String toString() {
    return 'ValidationError{source: $source, invalidValue: $invalidValue, message: $message}';
  }
}

extension ValidationErrorConverter on List<ValidationError> {
  Map<String, String> asFailedValidations() =>
      Map.fromEntries(map((e) => MapEntry(e.source, e.message)));
}
