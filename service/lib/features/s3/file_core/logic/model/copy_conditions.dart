import 'package:service/feather.dart';

/// Condiciones de una copia sobre el objeto de origen (cabeceras
/// `x-amz-copy-source-if-*` de CopyObject y UploadPartCopy). Si no se cumplen,
/// la copia falla con `PreconditionFailed`
class CopyConditions {
  /// ETags (con o sin comillas, separados por comas) o `*`
  final String? ifMatch;
  final String? ifNoneMatch;
  final DateTime? ifModifiedSince;
  final DateTime? ifUnmodifiedSince;

  const CopyConditions({
    this.ifMatch,
    this.ifNoneMatch,
    this.ifModifiedSince,
    this.ifUnmodifiedSince,
  });

  static const CopyConditions none = CopyConditions();

  /// Comprueba las condiciones contra el origen ([etag] y [modified]). Como
  /// en S3, si se cumple el if-match se ignora el if-unmodified-since, y si se
  /// cumple el if-none-match se ignora el if-modified-since
  void check({
    required String etag,
    required DateTime modified,
    required String resource,
  }) {
    //las fechas HTTP no tienen fracciones de segundo
    final seconds = DateTime.fromMillisecondsSinceEpoch(
      modified.millisecondsSinceEpoch ~/ 1000 * 1000,
      isUtc: true,
    );
    final failed =
        (ifMatch != null
            ? !_matches(ifMatch!, etag)
            : ifUnmodifiedSince != null && seconds.isAfter(ifUnmodifiedSince!)) ||
        (ifNoneMatch != null
            ? _matches(ifNoneMatch!, etag)
            : ifModifiedSince != null && !seconds.isAfter(ifModifiedSince!));
    if (failed) {
      throw S3Exception(
        S3ErrorCode.preconditionFailed,
        message: 'El objeto de origen no cumple las condiciones de la copia.',
        resource: resource,
      );
    }
  }

  bool _matches(String condition, String etag) => condition
      .split(',')
      .map((tag) => tag.trim().replaceAll('"', ''))
      .any((tag) => tag == '*' || tag == etag);
}
