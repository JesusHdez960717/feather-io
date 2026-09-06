import 'package:service/feather.dart';

class S3BucketNameFilter extends Filter {
  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final bucketName = request.pathParams['bucket'];

    if (bucketName != null && !S3Validator.isValidBucketName(bucketName)) {
      return ResponseEntity(
        HttpStatus.badRequest.value,
        body: 'El nombre del bucket "$bucketName" no es válido.',
      );
    }

    return await chain.doFilter(request);
  }
}
