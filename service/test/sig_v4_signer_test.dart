@TestOn('vm')
library;

import 'package:service/feather.dart';
import 'package:test/test.dart';

void main() {
  group('SigV4Signer', () {
    test('Should encode like AWS: everything but A-Za-z0-9-_.~', () {
      expect(
        SigV4Signer.uriEncode("aZ09-_.~ !'()*/+=;:,ñ"),
        'aZ09-_.~%20%21%27%28%29%2A%2F%2B%3D%3B%3A%2C%C3%B1',
      );
    });

    test('Should sort the canonical query by the encoded names', () {
      expect(
        SigV4Signer.canonicalQuery({
          'response-content-disposition': 'attachment; filename="a(1)!.png"',
          'X-Amz-Date': '20130524T000000Z',
          'uploads': '',
        }),
        'X-Amz-Date=20130524T000000Z'
        '&response-content-disposition=attachment%3B%20filename%3D%22a%281%29%21.png%22'
        '&uploads=',
      );
    });

    test('Should match the presigned URL example of the AWS docs', () {
      // https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
      const scope = '20130524/us-east-1/s3/aws4_request';
      final signature = SigV4Signer.signature(
        secret: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        amzDate: '20130524T000000Z',
        scope: scope,
        canonicalRequest: SigV4Signer.canonicalRequest(
          method: 'GET',
          path: '/test.txt',
          query: {
            'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
            'X-Amz-Credential': 'AKIAIOSFODNN7EXAMPLE/$scope',
            'X-Amz-Date': '20130524T000000Z',
            'X-Amz-Expires': '86400',
            'X-Amz-SignedHeaders': 'host',
          },
          headers: {'host': 'examplebucket.s3.amazonaws.com'},
          signedHeaders: 'host',
          payloadHash: SigV4Signer.unsignedPayload,
        ),
      );
      expect(
        signature,
        'aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404',
      );
    });
  });
}
