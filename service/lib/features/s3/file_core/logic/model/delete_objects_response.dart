class DeleteObjectsResponse {
  final List<String> deleted;
  final List<DeleteError> errors;
  final bool quiet;

  DeleteObjectsResponse({
    required this.deleted,
    required this.errors,
    this.quiet = false,
  });

  Map<String, Object?> toJson() {
    return {
      if (!quiet) 'deleted': deleted.map((key) => {'key': key}).toList(),
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }
}

class DeleteError {
  final String key;
  final String code;
  final String message;

  DeleteError({required this.key, required this.code, required this.message});

  Map<String, Object?> toJson() {
    return {'key': key, 'code': code, 'message': message};
  }
}
