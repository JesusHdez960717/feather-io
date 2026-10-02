import 'package:service/feather.dart';

/// Autentica a los clientes S3 nativos con AWS Signature Version 4, venga la
/// firma en la cabecera `Authorization` o en la query (URL prefirmada)
class S3SigV4Filter extends Filter {
  static final S3SigV4Filter _instance = S3SigV4Filter._();

  S3SigV4Filter._();

  factory S3SigV4Filter() => _instance;

  static const Set<String> _permissions = {
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

    //sin firma SigV4 no hay nada que validar: el AuthFilter de cada ruta decide (401)
    if (!isHeaderSigned && !isPresigned) {
      return await chain.doFilter(request);
    }

    try {
      final accessKey = isHeaderSigned
          ? _verifyHeader(request, authHeader)
          : _verifyQuery(request);
      request.securityContext.setAuthentication(
        Authentication(
          principal: accessKey,
          roles: {'admin'},
          permissions: _permissions,
        ),
      );
    } catch (e) {
      if (e is S3Exception) rethrow;
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: 'Authentication error: $e',
      );
    }

    return await chain.doFilter(request);
  }

  /// `Authorization: AWS4-HMAC-SHA256 Credential=…, SignedHeaders=…, Signature=…`
  String _verifyHeader(RequestEntity request, String authHeader) {
    //los campos van separados por comas, con o sin espacio (s3cmd no lo pone)
    String? field(String name) =>
        RegExp('[\\s,]$name=([^,\\s]+)').firstMatch(authHeader)?.group(1);
    final credential = field('Credential');
    final signedHeaders = field('SignedHeaders');
    final signature = field('Signature');
    if (credential == null || signedHeaders == null || signature == null) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: 'Invalid Authorization header format',
      );
    }

    final amzDate =
        request.headers['x-amz-date'] ?? request.headers['date'] ?? '';
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

  /// URL prefirmada: la firma y sus datos van en la query y caduca
  String _verifyQuery(RequestEntity request) {
    final params = request.queryParams;
    String param(String name) {
      final value = params[name];
      if (value == null || value.isEmpty) {
        throw S3Exception(
          S3ErrorCode.accessDenied,
          message: 'Missing $name in the presigned URL',
        );
      }
      return value;
    }

    if (param(SigV4Signer.algorithmParam) != SigV4Signer.algorithm) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: 'Unsupported signing algorithm',
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
        message: 'Invalid X-Amz-Date or X-Amz-Expires',
      );
    }
    if (DateTime.now().toUtc().isAfter(
      signedAt.add(Duration(seconds: expires)),
    )) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: 'Request has expired',
      );
    }

    return _verifySignature(
      request,
      credential: param(SigV4Signer.credentialParam),
      amzDate: amzDate,
      signedHeaders: param(SigV4Signer.signedHeadersParam),
      signature: param(SigV4Signer.signatureParam),
      //la firma no se firma a si misma
      query: {
        for (final entry in params.entries)
          if (entry.key != SigV4Signer.signatureParam) entry.key: entry.value,
      },
      payloadHash: SigV4Signer.unsignedPayload,
    );
  }

  /// Comprueba la clave de acceso y la firma; devuelve la clave de acceso
  String _verifySignature(
    RequestEntity request, {
    required String credential,
    required String amzDate,
    required String signedHeaders,
    required String signature,
    required Map<String, String> query,
    required String payloadHash,
  }) {
    // ACCESS_KEY/DATE/REGION/SERVICE/aws4_request
    final parts = credential.split('/');
    if (parts.length < 5) {
      throw S3Exception(
        S3ErrorCode.accessDenied,
        message: 'Invalid Credential format',
      );
    }
    final accessKey = parts[0];
    if (accessKey != env.access) {
      throw S3Exception(
        S3ErrorCode.invalidAccessKeyId,
        message: 'Invalid Access Key',
      );
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
      secret: env.secret,
      amzDate: amzDate,
      scope: parts.sublist(1).join('/'),
      canonicalRequest: canonicalRequest,
    );
    if (!SigV4Signer.sameSignature(expected, signature)) {
      throw S3Exception(
        S3ErrorCode.signatureDoesNotMatch,
        message: 'Signature mismatch',
      );
    }
    return accessKey;
  }

  ///Solo filtro si NO esta autenticado aun (por si ya paso por el jwt)
  @override
  bool shouldFilter(RequestEntity request) {
    return !request.securityContext.isAuthenticated;
  }

  @override
  String toString() {
    return 'S3SigV4Filter()';
  }
}
