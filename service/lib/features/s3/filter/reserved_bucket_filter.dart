import 'package:service/feather.dart';

class ReservedBucketFilter extends Filter {
  List<String> reservedBucketNames = env.reservedBucketNames;

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final bucketName = request.pathParams['bucket'];

    if (bucketName != null && reservedBucketNames.contains(bucketName)) {
      return ResponseEntity.forbidden(
        body: 'Bucket name "$bucketName" is reserved.',
      );
    }

    return await chain.doFilter(request);
  }

  @override
  String toString() {
    return 'ReservedBucketFilter{reservedBucketNames: $reservedBucketNames}';
  }
}
