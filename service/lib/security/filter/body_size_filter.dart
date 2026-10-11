import 'package:service/feather.dart';

/// Limits the body size per route, looking at `Content-Length` before reading
/// anything. Winter cuts any body above [ExtendedEnv.maxObjectSize] (see
/// `ServerConfig` in `main.dart`):
/// - Uploading an object (`s3.put-object`) goes to disk as a stream: declaring
///   more than [ExtendedEnv.maxObjectSize] is `EntityTooLarge`.
/// - Everything else reads the body into memory (JSON, multi-delete XML,
///   login): at most [maxRequestBodySize]. Without `Content-Length` (an empty
///   or a chunked body) the limit is checked while the body is read.
class BodySizeFilter extends Filter {
  static const String objectRouteKey = 's3.put-object';

  /// Maximum body of the requests that don't upload an object (2 MB: enough for
  /// the XML of a multi-delete of 1000 keys of 1024 bytes).
  static const int maxRequestBodySize = 2 * 1024 * 1024;

  static const Set<String> _bodyMethods = {'POST', 'PUT', 'PATCH'};

  static final BodySizeFilter _instance = BodySizeFilter._();

  BodySizeFilter._();

  factory BodySizeFilter() => _instance;

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final length = request.contentLength;

    if (request.route?.key == objectRouteKey) {
      final max = env.maxObjectSize;
      if (length != null && length > max) {
        throw S3Exception(
          S3ErrorCode.entityTooLarge,
          message: intl.errors.s3.objectSizeOverMaximum(size: length, max: max),
          resource: request.pathParams['key'],
        );
      }
    } else if (length != null && length > maxRequestBodySize) {
      throw const PayloadTooLargeException();
    } else if (length == null && _bodyMethods.contains(request.method)) {
      // Without a size it can't be limited before reading, so it is cut while
      // reading (413). That lets an empty body without the header through, like
      // aws-sdk-java-v2's CreateBucket
      return await chain.doFilter(
        request.copyWith(body: _limited(request.read(), maxRequestBodySize)),
      );
    }

    return await chain.doFilter(request);
  }

  /// [body] as it is read, failing with a 413 once it goes over [maxBytes].
  /// Winter reads the rest and discards it, so the client gets the answer.
  static Stream<List<int>> _limited(
    Stream<List<int>> body,
    int maxBytes,
  ) async* {
    var read = 0;
    await for (final chunk in body) {
      read += chunk.length;
      if (read > maxBytes) throw const PayloadTooLargeException();
      yield chunk;
    }
  }

  @override
  String toString() =>
      'BodySizeFilter{maxRequestBodySize: $maxRequestBodySize}';
}
