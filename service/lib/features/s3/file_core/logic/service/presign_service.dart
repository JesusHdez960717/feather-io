import 'package:service/feather.dart';

/// Genera URLs prefirmadas (SigV4 en la query) con las credenciales del
/// servicio, para que la consola pueda compartir un objeto sin conocerlas
class PresignService {
  final FileManagementService fileManagement;

  PresignService() : fileManagement = di.find();

  /// URL `GET` de [key] valida durante [expiresIn]. [host] y [scheme] son los
  /// de la peticion: la URL apunta al mismo servicio y la firma incluye el host
  Future<PresignedUrlModel> presignGet({
    required String scheme,
    required String host,
    required String bucketName,
    required String key,
    required Duration expiresIn,
  }) async {
    if (expiresIn.inSeconds < 1 || expiresIn > SigV4Signer.maxExpiration) {
      throw S3Exception(
        S3ErrorCode.invalidArgument,
        message: 'La caducidad debe estar entre 1 segundo y 7 días.',
        resource: key,
      );
    }
    //valida el bucket y la key y comprueba que el objeto existe
    await fileManagement.getFile(bucketName: bucketName, key: key);

    final now = DateTime.now().toUtc();
    final amzDate = SigV4Signer.amzDate(now);
    final scope = SigV4Signer.scope(SigV4Signer.dateStamp(now));
    final path =
        '/${SigV4Signer.uriEncode(bucketName)}/'
        '${key.split('/').map(SigV4Signer.uriEncode).join('/')}';
    final query = {
      SigV4Signer.algorithmParam: SigV4Signer.algorithm,
      SigV4Signer.credentialParam: '${env.access}/$scope',
      SigV4Signer.dateParam: amzDate,
      SigV4Signer.expiresParam: '${expiresIn.inSeconds}',
      SigV4Signer.signedHeadersParam: 'host',
    };
    final signature = SigV4Signer.signature(
      secret: env.secret,
      amzDate: amzDate,
      scope: scope,
      canonicalRequest: SigV4Signer.canonicalRequest(
        method: 'GET',
        path: path,
        query: query,
        headers: {'host': host},
        signedHeaders: 'host',
        payloadHash: SigV4Signer.unsignedPayload,
      ),
    );

    final signedQuery = SigV4Signer.canonicalQuery({
      ...query,
      SigV4Signer.signatureParam: signature,
    });
    return PresignedUrlModel(
      url: '$scheme://$host$path?$signedQuery',
      expiresAt: now.add(expiresIn),
    );
  }
}
