import 'package:service/feather.dart';

/// Subida multipart iniciada (CreateMultipartUpload): las partes se suben con
/// [uploadId] y se juntan al completarla
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

/// Parte copiada de otro objeto (UploadPartCopy)
class CopiedPartModel implements Serializable {
  /// md5 de la parte (sin comillas)
  final String etag;
  final DateTime lastModified;

  CopiedPartModel({required this.etag, required this.lastModified});

  @override
  Object? toJson() {
    return {'etag': etag, 'last_modified': lastModified.toIso8601String()};
  }
}

/// Objeto resultante de completar una subida multipart
class CompletedMultipartModel implements Serializable {
  final String bucket;
  final String key;

  /// ETag de S3 para multipart: md5 de los md5 de las partes y el numero de partes
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
