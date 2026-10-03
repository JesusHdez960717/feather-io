/// One part of the CompleteMultipartUpload list.
class CompletedPart {
  final int partNumber;

  /// ETag returned by UploadPart (with or without quotes); empty to skip the check.
  final String etag;

  CompletedPart({required this.partNumber, required this.etag});
}

/// Parts that make up the object, in order. Comes as S3 XML (parsed by the
/// controller) or as JSON `{"parts": [{"part_number": 1, "etag": "..."}]}`.
class CompleteMultipartRequest {
  final List<CompletedPart> parts;

  CompleteMultipartRequest({required this.parts});

  factory CompleteMultipartRequest.fromJson(Map<String, dynamic> json) {
    final parts = (json['parts'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (part) => CompletedPart(
            partNumber: part['part_number'] as int,
            etag: (part['etag'] ?? '').toString(),
          ),
        )
        .toList();
    return CompleteMultipartRequest(parts: parts);
  }
}
