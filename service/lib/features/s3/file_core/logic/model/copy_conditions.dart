import 'package:service/feather.dart';

/// Conditions of a copy on the source object (the `x-amz-copy-source-if-*`
/// headers of CopyObject and UploadPartCopy). If they don't hold, the copy fails
/// with `PreconditionFailed`.
class CopyConditions {
  /// ETags (with or without quotes, comma separated) or `*`.
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

  /// Checks the conditions against the source ([etag] and [modified]). As in
  /// S3, a matching if-match overrides if-unmodified-since, and a non-matching
  /// if-none-match overrides if-modified-since.
  void check({
    required String etag,
    required DateTime modified,
    required String resource,
  }) {
    // HTTP dates have no fractions of a second
    final seconds = DateTime.fromMillisecondsSinceEpoch(
      modified.millisecondsSinceEpoch ~/ 1000 * 1000,
      isUtc: true,
    );
    final failed =
        (ifMatch != null
            ? !_matches(ifMatch!, etag)
            : ifUnmodifiedSince != null &&
                  seconds.isAfter(ifUnmodifiedSince!)) ||
        (ifNoneMatch != null
            ? _matches(ifNoneMatch!, etag)
            : ifModifiedSince != null && !seconds.isAfter(ifModifiedSince!));
    if (failed) {
      throw S3Exception(
        S3ErrorCode.preconditionFailed,
        message: intl.errors.copy.conditionsFailed,
        resource: resource,
      );
    }
  }

  bool _matches(String condition, String etag) => condition
      .split(',')
      .map((tag) => tag.trim().replaceAll('"', ''))
      .any((tag) => tag == '*' || tag == etag);
}
