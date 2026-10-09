import 'package:service/feather.dart';

/// One part of the CompleteMultipartUpload list.
class CompletedPart {
  final int partNumber;

  /// ETag returned by UploadPart (with or without quotes); empty to skip the check.
  final String etag;

  CompletedPart({required this.partNumber, required this.etag});

  factory CompletedPart.fromJson(Map<String, dynamic> json) {
    return CompletedPart(
      partNumber: json.field<int>('part_number'),
      etag: json.field<String?>('etag') ?? '',
    );
  }
}

/// Parts that make up the object, in order. Comes as S3 XML (parsed by the
/// controller) or as JSON `{"parts": [{"part_number": 1, "etag": "..."}]}`.
class CompleteMultipartRequest {
  final List<CompletedPart> parts;

  CompleteMultipartRequest({required this.parts});

  factory CompleteMultipartRequest.fromJson(Map<String, dynamic> json) {
    return CompleteMultipartRequest(
      parts: json.field<List<CompletedPart>?>('parts') ?? const [],
    );
  }
}
