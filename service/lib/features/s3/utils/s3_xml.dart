import 'package:service/feather.dart';

/// The pieces every S3 XML response shares.
abstract final class S3Xml {
  static const String namespace = 'http://s3.amazonaws.com/doc/2006-03-01/';

  /// Owner of every bucket and upload: there is a single user.
  static const String ownerId = 'feather-io';

  /// The root element of an S3 response, with the S3 namespace.
  static XmlElement root(String name, List<XmlElement> elements) => XmlElement(
    name,
    attributes: const {'xmlns': namespace},
    elements: elements,
  );

  /// `<Owner>` (or `<Initiator>`): some clients (minio-java) require it.
  static XmlElement owner([String name = 'Owner']) => XmlElement(
    name,
    elements: [
      XmlElement.leaf('ID', ownerId),
      XmlElement.leaf('DisplayName', ownerId),
    ],
  );

  /// An S3 date: UTC with milliseconds (`2026-10-02T14:22:35.000Z`).
  static String date(DateTime date) {
    final utc = date.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
      utc.millisecond,
    ).toIso8601String();
  }

  /// An ETag as S3 writes it, between quotes.
  static XmlElement etag(String etag) => XmlElement.leaf('ETag', '"$etag"');

  /// [value] URL-encoded per segment (keeping `/`), for `encoding-type=url`.
  static String urlEncode(String value) =>
      value.split('/').map(SigV4Signer.uriEncode).join('/');
}
