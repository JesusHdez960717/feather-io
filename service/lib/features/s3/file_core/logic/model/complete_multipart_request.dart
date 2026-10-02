/// Una parte de la lista de CompleteMultipartUpload
class CompletedPart {
  final int partNumber;

  /// ETag que devolvio UploadPart (con o sin comillas); vacio para no comprobarlo
  final String etag;

  CompletedPart({required this.partNumber, required this.etag});
}

/// Partes que forman el objeto, en orden. Llega como XML de S3 (lo traduce el
/// controller) o como JSON `{"parts": [{"part_number": 1, "etag": "..."}]}`
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
