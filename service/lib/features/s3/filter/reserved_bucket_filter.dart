import 'package:service/feather.dart';

class ReservedBucketFilter extends Filter {
  static final ReservedBucketFilter _instance = ReservedBucketFilter._();

  late final List<String> reservedBucketNames;

  ReservedBucketFilter._() {
    reservedBucketNames = env.reservedBucketNames;
  }

  factory ReservedBucketFilter() => _instance;

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final bucketName = request.pathParams['bucket'];

    if (bucketName != null && reservedBucketNames.contains(bucketName)) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.s3.reservedBucket(bucket: bucketName),
        resource: bucketName,
      );
    }

    return await chain.doFilter(request);
  }

  @override
  String toString() {
    return 'ReservedBucketFilter{reservedBucketNames: $reservedBucketNames}';
  }
}
