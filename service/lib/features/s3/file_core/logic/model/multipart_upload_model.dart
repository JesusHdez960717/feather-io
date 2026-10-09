import 'package:service/feather.dart';

/// A started multipart upload (CreateMultipartUpload): the parts are uploaded
/// with [uploadId] and joined when it is completed.
class MultipartUploadModel implements XmlSerializable {
  final String bucket;
  final String key;
  final String uploadId;
  final DateTime initiated;

  MultipartUploadModel({
    required this.bucket,
    required this.key,
    required this.uploadId,
    required this.initiated,
  });

  Map<String, Object?> toJson() {
    return {
      'bucket': bucket,
      'key': key,
      'upload_id': uploadId,
      'initiated': initiated.toIso8601String(),
    };
  }

  /// InitiateMultipartUploadResult, the answer of CreateMultipartUpload.
  @override
  XmlElement toXml() => S3Xml.root('InitiateMultipartUploadResult', [
    XmlElement.leaf('Bucket', bucket),
    XmlElement.leaf('Key', key),
    XmlElement.leaf('UploadId', uploadId),
  ]);

  /// An `<Upload>` of ListMultipartUploadsResult.
  XmlElement toUploadXml() => XmlElement(
    'Upload',
    elements: [
      XmlElement.leaf('Key', key),
      XmlElement.leaf('UploadId', uploadId),
      S3Xml.owner('Initiator'),
      S3Xml.owner(),
      XmlElement.leaf('StorageClass', 'STANDARD'),
      XmlElement.leaf('Initiated', S3Xml.date(initiated)),
    ],
  );
}

/// ListMultipartUploads: in JSON the list itself, in XML
/// ListMultipartUploadsResult (without paging).
class MultipartUploadListModel implements XmlSerializable {
  final String bucket;
  final String? prefix;
  final List<MultipartUploadModel> uploads;

  MultipartUploadListModel({
    required this.bucket,
    required this.prefix,
    required this.uploads,
  });

  List<MultipartUploadModel> toJson() => uploads;

  @override
  XmlElement toXml() => S3Xml.root('ListMultipartUploadsResult', [
    XmlElement.leaf('Bucket', bucket),
    XmlElement.leaf('KeyMarker', null),
    XmlElement.leaf('UploadIdMarker', null),
    XmlElement.leaf('NextKeyMarker', null),
    XmlElement.leaf('NextUploadIdMarker', null),
    XmlElement.leaf('Prefix', prefix),
    XmlElement.leaf('MaxUploads', FileManagementService.maxKeysLimit),
    XmlElement.leaf('IsTruncated', false),
    for (final upload in uploads) upload.toUploadXml(),
  ]);
}

/// A part already uploaded to a multipart upload (ListParts).
class UploadedPartModel {
  final int partNumber;

  /// md5 of the part (without quotes).
  final String etag;
  final int size;
  final DateTime lastModified;

  UploadedPartModel({
    required this.partNumber,
    required this.etag,
    required this.size,
    required this.lastModified,
  });

  Map<String, Object?> toJson() {
    return {
      'part_number': partNumber,
      'etag': etag,
      'size_bytes': size,
      'last_modified': lastModified.toIso8601String(),
    };
  }

  /// A `<Part>` of ListPartsResult.
  XmlElement toXml() => XmlElement(
    'Part',
    elements: [
      XmlElement.leaf('PartNumber', partNumber),
      XmlElement.leaf('LastModified', S3Xml.date(lastModified)),
      S3Xml.etag(etag),
      XmlElement.leaf('Size', size),
    ],
  );
}

/// ListParts: in JSON the parts of this page, in XML ListPartsResult.
class PartListModel implements XmlSerializable {
  final String bucket;
  final String key;
  final String uploadId;

  /// The part number the page starts after (`part-number-marker`).
  final int marker;
  final int maxParts;
  final bool isTruncated;
  final List<UploadedPartModel> parts;

  PartListModel({
    required this.bucket,
    required this.key,
    required this.uploadId,
    required this.marker,
    required this.maxParts,
    required this.isTruncated,
    required this.parts,
  });

  List<UploadedPartModel> toJson() => parts;

  @override
  XmlElement toXml() => S3Xml.root('ListPartsResult', [
    XmlElement.leaf('Bucket', bucket),
    XmlElement.leaf('Key', key),
    XmlElement.leaf('UploadId', uploadId),
    S3Xml.owner('Initiator'),
    S3Xml.owner(),
    XmlElement.leaf('StorageClass', 'STANDARD'),
    XmlElement.leaf('PartNumberMarker', marker),
    if (parts.isNotEmpty)
      XmlElement.leaf('NextPartNumberMarker', parts.last.partNumber),
    XmlElement.leaf('MaxParts', maxParts),
    XmlElement.leaf('IsTruncated', isTruncated),
    for (final part in parts) part.toXml(),
  ]);
}

/// A part copied from another object (UploadPartCopy).
class CopiedPartModel implements XmlSerializable {
  /// md5 of the part (without quotes).
  final String etag;
  final DateTime lastModified;

  CopiedPartModel({required this.etag, required this.lastModified});

  Map<String, Object?> toJson() {
    return {'etag': etag, 'last_modified': lastModified.toIso8601String()};
  }

  /// CopyPartResult.
  @override
  XmlElement toXml() => S3Xml.root('CopyPartResult', [
    XmlElement.leaf('LastModified', S3Xml.date(lastModified)),
    S3Xml.etag(etag),
  ]);
}

/// Object that results from completing a multipart upload.
class CompletedMultipartModel implements XmlSerializable {
  final String bucket;
  final String key;

  /// S3's multipart ETag: md5 of the parts' md5s and the number of parts.
  final String etag;
  final int size;

  /// URL of the object (`http://host/bucket/key`), for the XML; the controller
  /// sets it with [at].
  final String? location;

  CompletedMultipartModel({
    required this.bucket,
    required this.key,
    required this.etag,
    required this.size,
    this.location,
  });

  /// This object at [location].
  CompletedMultipartModel at(String location) => CompletedMultipartModel(
    bucket: bucket,
    key: key,
    etag: etag,
    size: size,
    location: location,
  );

  Map<String, Object?> toJson() {
    return {'bucket': bucket, 'key': key, 'etag': etag, 'size_bytes': size};
  }

  /// CompleteMultipartUploadResult.
  @override
  XmlElement toXml() => S3Xml.root('CompleteMultipartUploadResult', [
    XmlElement.leaf('Location', location),
    XmlElement.leaf('Bucket', bucket),
    XmlElement.leaf('Key', key),
    S3Xml.etag(etag),
  ]);
}
