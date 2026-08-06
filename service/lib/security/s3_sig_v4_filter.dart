import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:service/feather.dart';

class S3SigV4Filter extends Filter {
  final String region;
  final String service;

  S3SigV4Filter({this.region = 'us-east-1', this.service = 's3'});

  @override
  Future<ResponseEntity> doFilter(
    RequestEntity request,
    FilterChain chain,
  ) async {
    final authHeader = request.headers['authorization'];
    final xAmzDate = request.headers['x-amz-date'] ?? request.headers['date'];

    if (authHeader == null || !authHeader.startsWith('AWS4-HMAC-SHA256')) {
      return ResponseEntity.forbidden(
        body: 'Missing or invalid Authorization header',
      );
    }

    try {
      // 1. Parse Authorization header
      // AWS4-HMAC-SHA256 Credential=ACCESS_KEY/DATE/REGION/SERVICE/aws4_request, SignedHeaders=HEADERS, Signature=SIGNATURE
      final parts = authHeader.split(', ');
      String? credential;
      String? signedHeaders;
      String? signature;

      for (var part in parts) {
        if (part.startsWith('AWS4-HMAC-SHA256 Credential=')) {
          credential = part.substring('AWS4-HMAC-SHA256 Credential='.length);
        } else if (part.startsWith('SignedHeaders=')) {
          signedHeaders = part.substring('SignedHeaders='.length);
        } else if (part.startsWith('Signature=')) {
          signature = part.substring('Signature='.length);
        }
      }

      if (credential == null || signedHeaders == null || signature == null) {
        return ResponseEntity.forbidden(
          body: 'Invalid Authorization header format',
        );
      }

      final credentialParts = credential.split('/');
      if (credentialParts.length < 5) {
        return ResponseEntity.forbidden(body: 'Invalid Credential format');
      }
      final accessKey = credentialParts[0];
      final dateStamp = credentialParts[1];
      final regionPart = credentialParts[2];
      final servicePart = credentialParts[3];

      // Validate access key
      if (accessKey != env.access) {
        return ResponseEntity.forbidden(body: 'Invalid Access Key');
      }

      // 2. Canonical Request
      final canonicalRequest = _createCanonicalRequest(request, signedHeaders);
      final hashedCanonicalRequest = sha256
          .convert(utf8.encode(canonicalRequest))
          .toString();

      // 3. String to Sign
      final amzDate = xAmzDate ?? '';
      final scope = '$dateStamp/$regionPart/$servicePart/aws4_request';
      final stringToSign =
          'AWS4-HMAC-SHA256\n$amzDate\n$scope\n$hashedCanonicalRequest';

      // 4. Calculate Signature
      final signingKey = _getSignatureKey(
        env.secret,
        dateStamp,
        regionPart,
        servicePart,
      );
      final calculatedSignature = _hmacSha256(
        signingKey,
        stringToSign,
      ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      if (calculatedSignature != signature.toLowerCase()) {
        return ResponseEntity.forbidden(body: 'Signature mismatch');
      }

      // Authenticate the request
      request.securityContext.setAuthentication(
        Authentication(principal: accessKey, roles: {'admin'}),
      );

      return chain.doFilter(request);
    } catch (e) {
      return ResponseEntity.forbidden(body: 'Authentication error: $e');
    }
  }

  String _createCanonicalRequest(RequestEntity request, String signedHeaders) {
    final method = request.method;
    // La URI canónica debe ser el path absoluto
    final canonicalUri = request.requestedUri.path;
    final canonicalQueryString = _getCanonicalQueryString(request.queryParams);
    final canonicalHeaders = _getCanonicalHeaders(
      request.headers,
      signedHeaders,
    );

    // Payload hash. Para S3, si no se provee, puede ser UNSIGNED-PAYLOAD
    final payloadHash =
        request.headers['x-amz-content-sha256'] ?? 'UNSIGNED-PAYLOAD';

    return '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$payloadHash';
  }

  String _getCanonicalQueryString(Map<String, String> queryParams) {
    if (queryParams.isEmpty) return '';
    final sortedKeys = queryParams.keys.toList()..sort();
    return sortedKeys
        .map(
          (k) =>
              '${Uri.encodeComponent(k)}=${Uri.encodeComponent(queryParams[k]!)}',
        )
        .join('&');
  }

  String _getCanonicalHeaders(
    Map<String, String> headers,
    String signedHeaders,
  ) {
    final signedKeys = signedHeaders.split(';');
    final buffer = StringBuffer();
    for (var key in signedKeys) {
      final lowerKey = key.toLowerCase();
      final value = headers[lowerKey]?.trim() ?? headers[key]?.trim() ?? '';
      buffer.write('$lowerKey:$value\n');
    }
    return buffer.toString();
  }

  List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  List<int> _getSignatureKey(
    String key,
    String dateStamp,
    String regionName,
    String serviceName,
  ) {
    final kDate = _hmacSha256(utf8.encode('AWS4$key'), dateStamp);
    final kRegion = _hmacSha256(kDate, regionName);
    final kService = _hmacSha256(kRegion, serviceName);
    final kSigning = _hmacSha256(kService, 'aws4_request');
    return kSigning;
  }
}
