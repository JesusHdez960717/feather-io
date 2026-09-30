import 'package:service/feather.dart';

class S3BucketNameFilter extends Filter {
  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final bucketName = request.pathParams['bucket'];

    if (bucketName != null && !S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }

    return await chain.doFilter(request);
  }
}
