import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:service/feather.dart';

/// Authenticates native S3 clients with AWS Signature Version 4, whether the
/// signature comes in the `Authorization` header or in the query (presigned URL).
///
/// The root key (`FEATHER_ACCESS`) gets every S3 permission and its id as the
/// principal. A managed access key gets the permissions of its level on the
/// request's bucket, and the [AccessKeyModel] as the principal, so the
/// controller can check other buckets (the source of a copy, ListBuckets).
class S3SigV4Filter extends Filter {
  static final S3SigV4Filter _instance = S3SigV4Filter._();

  late final AccessKeyService _accessKeys = AccessKeyService();

  S3SigV4Filter._();

  factory S3SigV4Filter() => _instance;

  static const Set<String> _readPermissions = {
    's3.list-objects',
    's3.get-object',
  };

  static const Set<String> _writePermissions = {
    's3.put-object',
    's3.delete-object',
    's3.multi-delete-objects',
  };

  static const Set<String> _rootPermissions = {
    's3.list-buckets',
    's3.create-bucket',
    's3.delete-bucket',
    's3.list-objects',
    's3.put-object',
    's3.get-object',
    's3.delete-object',
    's3.multi-delete-objects',
  };

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final authHeader = request.headers['authorization'];
    final isHeaderSigned =
        authHeader != null && authHeader.startsWith(SigV4Signer.algorithm);
    final isPresigned = request.queryParams.containsKey(
      SigV4Signer.signatureParam,
    );

    // Without a SigV4 signature there is nothing to verify: each route's AuthFilter decides (401)
    if (!isHeaderSigned && !isPresigned) {
      return await chain.doFilter(request);
    }

    try {
      final principal = isHeaderSigned
          ? await _verifyHeader(request, authHeader)
          : await _verifyQuery(request);
      request.securityContext.setAuthentication(
        principal is AccessKeyModel
            ? Authentication(
                principal: principal,
                roles: {'access-key'},
                permissions: keyPermissions(
                  principal,
                  request.pathParams['bucket'],
                ),
              )
            : Authentication(
                principal: principal,
                roles: {'admin'},
                permissions: _rootPermissions,
              ),
      );
    } catch (e) {
      if (e is S3Exception) rethrow;
      // No internal details in the response
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.signature.invalid,
      );
    }

    // If the client signed the body's sha256, the body must be that one;
    // otherwise a captured request could be replayed with another content
    final payloadHash = request.headers['x-amz-content-sha256'];
    if (isHeaderSigned &&
        payloadHash != null &&
        _sha256Pattern.hasMatch(payloadHash)) {
      return await chain.doFilter(
        request.copyWith(
          body: _checkSha256(request.read(), payloadHash.toLowerCase()),
        ),
      );
    }
    return await chain.doFilter(request);
  }

  /// What [key] may do in a request to [bucket] (null: ListBuckets). Every key
  /// can list buckets (it only sees its own); only one with write access to
  /// every bucket can create and delete them.
  static Set<String> keyPermissions(AccessKeyModel key, String? bucket) {
    final level = bucket == null ? null : key.levelOn(bucket);
    return {
      's3.list-buckets',
      if (level?.canRead ?? false) ..._readPermissions,
      if (level?.canWrite ?? false) ..._writePermissions,
      if (key.allBuckets?.canWrite ?? false) ...{
        's3.create-bucket',
        's3.delete-bucket',
      },
    };
  }

  /// Maximum skew between the signature's date and the server's, as in S3:
  /// outside it a signed request is no longer valid (it can't be replayed later).
  static const Duration maxClockSkew = Duration(minutes: 15);

  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-fA-F]{64}$');

  /// Lets [body] through computing its sha256 and, at the end, fails if it is
  /// not [expected]. It is read entirely before failing: stopping in the middle
  /// would close the connection without sending the error.
  static Stream<List<int>> _checkSha256(
    Stream<List<int>> body,
    String expected,
  ) async* {
    final digest = _Sha256Sink();
    final hasher = sha256.startChunkedConversion(digest);
    await for (final chunk in body) {
      hasher.add(chunk);
      yield chunk;
    }
    hasher.close();
    if (digest.value.toString() != expected) {
      throw S3Exception(
        S3ErrorCode.xAmzContentSHA256Mismatch,
        message: intl.errors.signature.sha256Mismatch,
      );
    }
  }

  /// Checks that a signature's date is within [maxClockSkew].
  static void _checkClockSkew(DateTime? signedAt) {
    final now = DateTime.now().toUtc();
    if (signedAt == null ||
        signedAt.isBefore(now.subtract(maxClockSkew)) ||
        signedAt.isAfter(now.add(maxClockSkew))) {
      throw S3Exception(
        S3ErrorCode.requestTimeTooSkewed,
        message: intl.errors.signature.clockSkew(
          minutes: maxClockSkew.inMinutes,
        ),
      );
    }
  }

  /// `Authorization: AWS4-HMAC-SHA256 Credential=…, SignedHeaders=…, Signature=…`
  Future<Object> _verifyHeader(RequestEntity request, String authHeader) {
    // Fields are separated by commas, with or without a space (s3cmd adds none)
    String? field(String name) =>
        RegExp('[\\s,]$name=([^,\\s]+)').firstMatch(authHeader)?.group(1);
    final credential = field('Credential');
    final signedHeaders = field('SignedHeaders');
    final signature = field('Signature');
    if (credential == null || signedHeaders == null || signature == null) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.signature.invalidAuthorizationHeader,
      );
    }

    final amzDate =
        request.headers['x-amz-date'] ?? request.headers['date'] ?? '';
    _checkClockSkew(_parseRequestDate(amzDate));
    return _verifySignature(
      request,
      credential: credential,
      amzDate: amzDate,
      signedHeaders: signedHeaders,
      signature: signature,
      query: request.queryParams,
      payloadHash:
          request.headers['x-amz-content-sha256'] ??
          SigV4Signer.unsignedPayload,
    );
  }

  /// Presigned URL: the signature and its data come in the query, and it expires.
  Future<Object> _verifyQuery(RequestEntity request) {
    final params = request.queryParams;
    String param(String name) {
      final value = params[name];
      if (value == null || value.isEmpty) {
        throw S3Exception(
          S3ErrorCode.accessDenied,
          message: intl.errors.signature.presignMissingParam(name: name),
        );
      }
      return value;
    }

    if (param(SigV4Signer.algorithmParam) != SigV4Signer.algorithm) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.signature.unsupportedAlgorithm,
      );
    }
    final amzDate = param(SigV4Signer.dateParam);
    final signedAt = SigV4Signer.parseAmzDate(amzDate);
    final expires = int.tryParse(param(SigV4Signer.expiresParam));
    if (signedAt == null ||
        expires == null ||
        expires < 1 ||
        expires > SigV4Signer.maxExpiration.inSeconds) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.signature.invalidDateOrExpires,
      );
    }
    // A future date would stretch the URL past its maximum expiration
    if (signedAt.isAfter(DateTime.now().toUtc().add(maxClockSkew))) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.signature.presignNotYetValid,
      );
    }
    if (DateTime.now().toUtc().isAfter(
      signedAt.add(Duration(seconds: expires)),
    )) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.signature.expired,
      );
    }

    return _verifySignature(
      request,
      credential: param(SigV4Signer.credentialParam),
      amzDate: amzDate,
      signedHeaders: param(SigV4Signer.signedHeadersParam),
      signature: param(SigV4Signer.signatureParam),
      // The signature doesn't sign itself
      query: {
        for (final entry in params.entries)
          if (entry.key != SigV4Signer.signatureParam) entry.key: entry.value,
      },
      payloadHash: SigV4Signer.unsignedPayload,
    );
  }

  /// Checks the access key and the signature. Returns the root key's id, or the
  /// managed [AccessKeyModel] that signed.
  Future<Object> _verifySignature(
    RequestEntity request, {
    required String credential,
    required String amzDate,
    required String signedHeaders,
    required String signature,
    required Map<String, String> query,
    required String payloadHash,
  }) async {
    // ACCESS_KEY/DATE/REGION/SERVICE/aws4_request
    final parts = credential.split('/');
    if (parts.length < 5) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: intl.errors.signature.invalidCredential,
      );
    }
    final accessKey = parts[0];
    final signedAt = _parseRequestDate(amzDate);
    if (signedAt == null || SigV4Signer.dateStamp(signedAt) != parts[1]) {
      throw S3Exception(
        S3ErrorCode.signatureDoesNotMatch,
        message: intl.errors.signature.credentialDateMismatch,
      );
    }
    final String secret;
    AccessKeyModel? key;
    if (accessKey == env.access) {
      secret = env.secret;
    } else {
      final found = await _accessKeys.findForSignature(accessKey);
      // Disabled or expired keys answer as unknown ones, as in AWS
      if (found == null || !found.key.isUsable) {
        throw S3Exception(
          S3ErrorCode.invalidAccessKeyId,
          message: intl.errors.signature.accessKeyInactive,
        );
      }
      key = found.key;
      secret = found.secret;
    }

    final canonicalRequest = SigV4Signer.canonicalRequest(
      method: request.method,
      path: request.requestedUri.path,
      query: query,
      headers: request.headers,
      signedHeaders: signedHeaders,
      payloadHash: payloadHash,
    );
    final expected = SigV4Signer.signature(
      secret: secret,
      amzDate: amzDate,
      scope: parts.sublist(1).join('/'),
      canonicalRequest: canonicalRequest,
    );
    if (!SigV4Signer.sameSignature(expected, signature)) {
      throw S3Exception(
        S3ErrorCode.signatureDoesNotMatch,
        message: intl.errors.signature.mismatch,
      );
    }
    if (key == null) return accessKey;
    await _accessKeys.touch(key.id);
    return key;
  }

  /// `X-Amz-Date` (`20260930T184512Z`) or, without it, the `Date` header (HTTP).
  static DateTime? _parseRequestDate(String value) {
    final amz = SigV4Signer.parseAmzDate(value);
    if (amz != null) return amz;
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Only runs while the request is not authenticated yet (the JWT filter runs first).
  @override
  bool shouldFilter(RequestEntity request) {
    return !request.securityContext.isAuthenticated;
  }

  @override
  String toString() {
    return 'S3SigV4Filter()';
  }
}

/// Collects the result of a chunked hash.
class _Sha256Sink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
