import 'dart:convert';

import 'package:crypto/crypto.dart';

class S3SigV4Signer {
  final String accessKey;
  final String secretKey;
  final String region;
  final String service;

  S3SigV4Signer({
    required this.accessKey,
    required this.secretKey,
    this.region = 'us-east-1',
    this.service = 's3',
  });

  Map<String, String> sign({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String payloadHash = 'UNSIGNED-PAYLOAD',
  }) {
    final now = DateTime.now().toUtc();
    final amzDate = _formatDateTime(now);
    final dateStamp = _formatDate(now);

    final updatedHeaders = Map<String, String>.from(headers);
    updatedHeaders['x-amz-date'] = amzDate;
    updatedHeaders['x-amz-content-sha256'] = payloadHash;

    // El host es requerido para la firma
    updatedHeaders['host'] = uri.host + (uri.hasPort ? ':${uri.port}' : '');

    final sortedHeaderKeys = updatedHeaders.keys.toList()..sort();
    final signedHeaders = sortedHeaderKeys
        .map((k) => k.toLowerCase())
        .join(';');

    // 1. Canonical Request
    final canonicalUri = uri.path.isEmpty ? '/' : uri.path;
    final canonicalQueryString = _getCanonicalQueryString(uri.queryParameters);
    final canonicalHeaders = sortedHeaderKeys
        .map((k) => '${k.toLowerCase()}:${updatedHeaders[k]!.trim()}\n')
        .join();

    final canonicalRequest =
        '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    // 2. String to Sign
    final hashedCanonicalRequest = sha256
        .convert(utf8.encode(canonicalRequest))
        .toString();
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign =
        'AWS4-HMAC-SHA256\n$amzDate\n$credentialScope\n$hashedCanonicalRequest';

    // 3. Signature
    final signingKey = _getSignatureKey(secretKey, dateStamp, region, service);
    final signature = _hmacSha256(
      signingKey,
      stringToSign,
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    final authorizationHeader =
        'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    updatedHeaders['Authorization'] = authorizationHeader;

    // Remove host header as Dio/HttpClient will set it
    updatedHeaders.remove('host');

    return updatedHeaders;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first}Z';
  }

  String _formatDate(DateTime dt) {
    return dt.toIso8601String().split('T').first.replaceAll('-', '');
  }

  String _getCanonicalQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    final sortedKeys = params.keys.toList()..sort();
    return sortedKeys
        .map(
          (k) => '${Uri.encodeComponent(k)}=${Uri.encodeComponent(params[k]!)}',
        )
        .join('&');
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
