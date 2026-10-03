import 'package:console/app_exporter.dart';

/// What happened to a bucket
enum BucketChange {
  created,

  /// Its description or color changed
  updated,

  /// All its objects were deleted
  emptied,
  deleted,

  /// Objects were uploaded or deleted (its statistics change)
  objectsChanged,
}

/// Notice on the global bus that a bucket changed. Each section (browser,
/// *Buckets*) has its own cubits, and this keeps them up to date
class BucketChangedEvent {
  /// The cubit that made the change: it already updates itself and ignores it
  final Object source;
  final BucketChange change;
  final String bucketName;

  /// The already updated bucket, in [BucketChange.updated]
  final BucketModel? bucket;

  const BucketChangedEvent({
    required this.source,
    required this.change,
    required this.bucketName,
    this.bucket,
  });
}
