import 'package:service/feather.dart';

/// Builds presigned URLs (SigV4 in the query) with the service credentials, so
/// the console can share an object without knowing them.
class PresignService {
  final FileManagementService fileManagement;

  PresignService() : fileManagement = di.find();

  /// `GET` URL of [key] valid for [expiresIn]. [host] and [scheme] come from
  /// `PUBLIC_URL` or, without it, from the request; the signature includes the host.
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
        message: intl.errors.s3.presignExpiration,
        resource: key,
      );
    }
    // Validates the bucket and the key and checks that the object exists
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
