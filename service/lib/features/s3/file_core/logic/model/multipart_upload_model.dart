import 'package:service/feather.dart';

/// Subida multipart iniciada (CreateMultipartUpload): las partes se suben con
/// [uploadId] y se juntan al completarla
class MultipartUploadModel implements Serializable {
  final String bucket;
  final String key;
  final String uploadId;

  MultipartUploadModel({
    required this.bucket,
    required this.key,
    required this.uploadId,
  });

  @override
  Object? toJson() {
    return {'bucket': bucket, 'key': key, 'upload_id': uploadId};
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
