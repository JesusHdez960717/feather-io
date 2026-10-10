import 'package:service/feather.dart';

/// Answers `501 NotImplemented`, like S3, to the subresources the service doesn't
/// implement (`?versioning`, `?policy`, `?tagging`…). Without this filter they
/// would fall into the normal routes: `PUT /{bucket}?versioning` would try to
/// create the bucket and `GET /{bucket}?policy` would return the listing.
class UnsupportedSubresourceFilter extends Filter {
  static final UnsupportedSubresourceFilter _instance =
      UnsupportedSubresourceFilter._();

  UnsupportedSubresourceFilter._();

  factory UnsupportedSubresourceFilter() => _instance;

  static const Set<String> _unsupported = {
    'accelerate',
    'acl',
    'analytics',
    'attributes',
    'cors',
    'encryption',
    'intelligent-tiering',
    'inventory',
    'legal-hold',
    'lifecycle',
    'logging',
    'metrics',
    'notification',
    'object-lock',
    'ownershipControls',
    'policy',
    'policyStatus',
    'publicAccessBlock',
    'replication',
    'requestPayment',
    'restore',
    'retention',
    'select',
    'tagging',
    'torrent',
    'versioning',
    'versions',
    'website',
  };

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final params = request.queryParams.keys;
    final subresource = params
        .where(_unsupported.contains)
        .where((p) => !_readable(request, p))
        .firstOrNull;
    if (subresource != null) {
      throw S3Exception(
        S3ErrorCode.notImplemented,
        message: intl.errors.s3.unsupportedSubresource(
          subresource: subresource,
        ),
        resource: request.requestedUri.path,
      );
    }

    return await chain.doFilter(request);
  }

  /// Reads that are answered even though the subresource isn't implemented,
  /// because clients ask for them before other operations: an object's tags
  /// (GetObjectTagging, which the AWS CLI asks before a multipart copy; there
  /// are none) and a bucket's versioning (GetBucketVersioning, which rclone
  /// asks; it is never enabled).
  bool _readable(RequestEntity request, String subresource) {
    if (request.method != 'GET') return false;
    final hasKey = request.pathParams['key'] != null;
    return (subresource == 'tagging' && hasKey) ||
        (subresource == 'versioning' && !hasKey);
  }

  @override
  String toString() => 'UnsupportedSubresourceFilter()';
}
