import 'package:service/feather.dart';

/// A started multipart upload (CreateMultipartUpload): the parts are uploaded
/// with [uploadId] and joined when it is completed.
class MultipartUploadModel implements Serializable {
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

  @override
  Object? toJson() {
    return {
      'bucket': bucket,
      'key': key,
      'upload_id': uploadId,
      'initiated': initiated.toIso8601String(),
    };
  }
}

/// A part already uploaded to a multipart upload (ListParts).
class UploadedPartModel implements Serializable {
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

  @override
  Object? toJson() {
    return {
      'part_number': partNumber,
      'etag': etag,
      'size_bytes': size,
      'last_modified': lastModified.toIso8601String(),
    };
  }
}

/// A part copied from another object (UploadPartCopy).
class CopiedPartModel implements Serializable {
  /// md5 of the part (without quotes).
  final String etag;
  final DateTime lastModified;

  CopiedPartModel({required this.etag, required this.lastModified});

  @override
  Object? toJson() {
    return {'etag': etag, 'last_modified': lastModified.toIso8601String()};
  }
}

/// Object that results from completing a multipart upload.
class CompletedMultipartModel implements Serializable {
  final String bucket;
  final String key;

  /// S3's multipart ETag: md5 of the parts' md5s and the number of parts.
  final String etag;
  final int size;

  CompletedMultipartModel({
    required this.bucket,
    required this.key,
    required this.etag,
    required this.size,
  });

  @override
  Object? toJson() {
    return {'bucket': bucket, 'key': key, 'etag': etag, 'size_bytes': size};
  }
}
