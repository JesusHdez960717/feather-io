import 'dart:io';

import 'package:service/feather.dart';

/// What the S3 operations read from a request besides its body: the bucket and
/// the key of the path, the headers stored with an object, its storage class,
/// the conditions of a copy, and the permission multipart needs.
extension S3Request on RequestEntity {
  String get bucketName => pathParams['bucket']!;

  /// The object key. The path parameter loses the trailing `/`, which tells a
  /// folder (`photos/`) from an object (`photos`), so it is restored from the
  /// URL.
  String get objectKey {
    final key = pathParams['key']!;
    return requestedUri.path.endsWith('/') && !key.endsWith('/')
        ? '$key/'
        : key;
  }

  /// The content of an object or a part, without the `aws-chunked` framing
  /// when the client sends it that way.
  Stream<List<int>> objectBody() => AwsChunkedDecoder.appliesTo(this)
      ? AwsChunkedDecoder.decode(read())
      : read();

  /// Request headers stored with the object and sent back when it is read, as
  /// in S3: the content headers and the `x-amz-meta-*` metadata, plus the
  /// storage class. `aws-chunked` is the transfer format, not the object's, so
  /// it is not stored.
  Map<String, String> objectHeaders() {
    final stored = {
      for (final MapEntry(:key, :value) in headers.entries)
        if (_storedHeaders.contains(key.toLowerCase()) ||
            key.toLowerCase().startsWith('x-amz-meta-'))
          key.toLowerCase(): value,
    };
    final encoding = stored['content-encoding']
        ?.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != 'aws-chunked')
        .join(', ');
    if (encoding == null || encoding.isEmpty) {
      stored.remove('content-encoding');
    } else {
      stored['content-encoding'] = encoding;
    }
    return {...stored, 'x-amz-storage-class': ?storageClass()};
  }

  // x-amz-storage-class is not here: it is validated apart, and the standard
  // one (STANDARD) is not stored
  static const Set<String> _storedHeaders = {
    'cache-control',
    'content-disposition',
    'content-encoding',
    'content-language',
    'content-type',
    'expires',
  };

  /// The class in `x-amz-storage-class`, or null when missing or standard
  /// (`STANDARD`, which S3 never sends back). All of them are stored the same
  /// way: the requested one is only remembered to send it back.
  String? storageClass() {
    final value = headers['x-amz-storage-class']?.trim().toUpperCase();
    if (value == null || value.isEmpty || value == 'STANDARD') return null;
    if (!_storageClasses.contains(value)) {
      throw S3Exception(
        S3ErrorCode.invalidStorageClass,
        message: intl.errors.s3.invalidStorageClass(value: value),
        resource: requestedUri.path,
      );
    }
    return value;
  }

  static const Set<String> _storageClasses = {
    'STANDARD',
    'REDUCED_REDUNDANCY',
    'STANDARD_IA',
    'ONEZONE_IA',
    'INTELLIGENT_TIERING',
    'GLACIER',
    'GLACIER_IR',
    'DEEP_ARCHIVE',
    'OUTPOSTS',
    'EXPRESS_ONEZONE',
  };

  /// The `x-amz-copy-source-if-*` conditions of a copy. A date that can't be
  /// parsed is ignored, as in S3.
  CopyConditions copyConditions() {
    DateTime? date(String name) {
      final value = headers['x-amz-copy-source-if-$name'];
      if (value == null) return null;
      try {
        return HttpDate.parse(value);
      } catch (_) {
        return null;
      }
    }

    return CopyConditions(
      ifMatch: headers['x-amz-copy-source-if-match'],
      ifNoneMatch: headers['x-amz-copy-source-if-none-match'],
      ifModifiedSince: date('modified-since'),
      ifUnmodifiedSince: date('unmodified-since'),
    );
  }

  /// Multipart is never anonymous: it requires the regular upload permission.
  /// Needed by the operations that go through routes accepting anonymous rules
  /// (UploadPart via PUT, AbortMultipartUpload via DELETE, ListParts and
  /// ListMultipartUploads via GET); Create and Complete go through POST, whose
  /// route already requires it.
  void requireUploadPermission(String resource) {
    final permissions = securityContext.authentication?.permissions ?? const {};
    if (!permissions.contains('s3.put-object')) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.multipart.needsUploadPermission,
        resource: resource,
      );
    }
  }
}
