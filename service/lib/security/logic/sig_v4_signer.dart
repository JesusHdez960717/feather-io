import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Firma AWS Signature Version 4 (S3). La usan el filtro que valida las
/// peticiones firmadas y el servicio que genera URLs prefirmadas
class SigV4Signer {
  static const String algorithm = 'AWS4-HMAC-SHA256';
  static const String region = 'us-east-1';
  static const String service = 's3';
  static const String unsignedPayload = 'UNSIGNED-PAYLOAD';

  /// Parametros de la query de una URL prefirmada
  static const String algorithmParam = 'X-Amz-Algorithm';
  static const String credentialParam = 'X-Amz-Credential';
  static const String dateParam = 'X-Amz-Date';
  static const String expiresParam = 'X-Amz-Expires';
  static const String signedHeadersParam = 'X-Amz-SignedHeaders';
  static const String signatureParam = 'X-Amz-Signature';

  /// Caducidad maxima de una URL prefirmada (7 dias), como en S3
  static const Duration maxExpiration = Duration(days: 7);

  /// `20260930` de una fecha UTC
  static String dateStamp(DateTime utc) =>
      '${utc.year.toString().padLeft(4, '0')}'
      '${utc.month.toString().padLeft(2, '0')}'
      '${utc.day.toString().padLeft(2, '0')}';

  /// `20260930T184512Z` de una fecha UTC
  static String amzDate(DateTime utc) =>
      '${dateStamp(utc)}T'
      '${utc.hour.toString().padLeft(2, '0')}'
      '${utc.minute.toString().padLeft(2, '0')}'
      '${utc.second.toString().padLeft(2, '0')}Z';

  /// Lee un `X-Amz-Date` (`20260930T184512Z`); null si no tiene ese formato
  static DateTime? parseAmzDate(String value) {
    final match = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$')
        .firstMatch(value);
    if (match == null) return null;
    final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    return DateTime.utc(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
      parts[4],
      parts[5],
    );
  }

  static String scope(String dateStamp, {String region = region}) =>
      '$dateStamp/$region/$service/aws4_request';

  /// Codifica [value] como lo hace AWS al firmar: todo en `%XX` (bytes UTF-8)
  /// salvo `A-Za-z0-9-_.~`. `Uri.encodeComponent` deja `!'()*` sin codificar y
  /// la firma no coincidiria
  static String uriEncode(String value) {
    final buffer = StringBuffer();
    for (final byte in utf8.encode(value)) {
      final unreserved =
          (byte >= 0x41 && byte <= 0x5A) || // A-Z
          (byte >= 0x61 && byte <= 0x7A) || // a-z
          (byte >= 0x30 && byte <= 0x39) || // 0-9
          byte == 0x2D || // -
          byte == 0x5F || // _
          byte == 0x2E || // .
          byte == 0x7E; // ~
      buffer.write(
        unreserved
            ? String.fromCharCode(byte)
            : '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
      );
    }
    return buffer.toString();
  }

  /// La query canonica: cada nombre y valor con [uriEncode], ordenada por el
  /// nombre ya codificado
  static String canonicalQuery(Map<String, String> params) {
    final encoded = [
      for (final MapEntry(:key, :value) in params.entries)
        (uriEncode(key), uriEncode(value)),
    ]..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    return encoded.map((pair) => '${pair.$1}=${pair.$2}').join('&');
  }

  static String canonicalHeaders(
    Map<String, String> headers,
    String signedHeaders,
  ) {
    final buffer = StringBuffer();
    for (final key in signedHeaders.split(';')) {
      final lowerKey = key.toLowerCase();
      final value = headers[lowerKey]?.trim() ?? headers[key]?.trim() ?? '';
      buffer.write('$lowerKey:$value\n');
    }
    return buffer.toString();
  }

  /// La peticion canonica. [path] va tal cual en la URL (ya codificado)
  static String canonicalRequest({
    required String method,
    required String path,
    required Map<String, String> query,
    required Map<String, String> headers,
    required String signedHeaders,
    required String payloadHash,
  }) {
    return '$method\n$path\n${canonicalQuery(query)}\n'
        '${canonicalHeaders(headers, signedHeaders)}\n'
        '$signedHeaders\n$payloadHash';
  }

  /// La firma en hexadecimal de [canonicalRequest]
  static String signature({
    required String secret,
    required String amzDate,
    required String scope,
    required String canonicalRequest,
  }) {
    final parts = scope.split('/');
    final stringToSign =
        '$algorithm\n$amzDate\n$scope\n'
        '${sha256.convert(utf8.encode(canonicalRequest))}';
    final key = _signingKey(secret, parts[0], parts[1], parts[2]);
    return Hmac(sha256, key)
        .convert(utf8.encode(stringToSign))
        .bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static List<int> _hmac(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  static List<int> _signingKey(
    String secret,
    String dateStamp,
    String region,
    String service,
  ) {
    final kDate = _hmac(utf8.encode('AWS4$secret'), dateStamp);
    final kRegion = _hmac(kDate, region);
    final kService = _hmac(kRegion, service);
    return _hmac(kService, 'aws4_request');
  }

  /// Compara dos firmas sin cortar en la primera diferencia
  static bool sameSignature(String a, String b) {
    final left = a.toLowerCase();
    final right = b.toLowerCase();
    if (left.length != right.length) return false;
    var diff = 0;
    for (var i = 0; i < left.length; i++) {
      diff |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
    }
    return diff == 0;
  }
}
