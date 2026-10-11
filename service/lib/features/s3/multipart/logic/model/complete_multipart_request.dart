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

  /// The S3 body, a `CompleteMultipartUpload` with a `Part` (`PartNumber`,
  /// `ETag`) per part. A part without a valid number is a [FormatException].
  factory CompleteMultipartRequest.fromXml(XmlElement root) {
    return CompleteMultipartRequest(
      parts: [
        for (final part in root.children('Part'))
          CompletedPart(
            partNumber:
                int.tryParse(part.childText('PartNumber')?.trim() ?? '') ??
                (throw const FormatException('A part without PartNumber')),
            etag: part.childText('ETag')?.trim() ?? '',
          ),
      ],
    );
  }

  factory CompleteMultipartRequest.fromJson(Map<String, dynamic> json) {
    return CompleteMultipartRequest(
      parts: json.field<List<CompletedPart>?>('parts') ?? const [],
    );
  }
}
