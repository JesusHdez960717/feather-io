import 'package:service/feather.dart';

class ListObjectsResponse implements XmlSerializable {
  final String bucketName;
  final String? prefix;
  final String? delimiter;
  final List<FileModel> contents;
  final List<String> commonPrefixes;

  /// Maximum keys (objects + common prefixes) of this page.
  final int maxKeys;

  /// Token this page was requested with, unless it is the first one.
  final String? continuationToken;

  /// Key the page starts after (`marker` in ListObjects V1, `start-after` in
  /// V2), as requested.
  final String? startAfter;

  /// Last key of this page, to request the next one with `marker` (V1); only
  /// when [isTruncated].
  final String? nextMarker;

  /// There are more keys after this page.
  final bool isTruncated;

  /// Token to request the next page; only when [isTruncated].
  final String? nextContinuationToken;

  /// Keys (objects + common prefixes) of every page. Not part of S3: it only
  /// goes in the JSON, so the console can show "page X of N".
  final int totalKeys;

  /// The XML is ListObjectsV2 (`list-type=2`, pages with a continuation token)
  /// instead of V1 (pages with a marker).
  final bool v2;

  /// Keys, prefixes and markers go URL-encoded in the XML (`encoding-type=url`),
  /// and the client decodes them.
  final bool urlEncoded;

  ListObjectsResponse({
    required this.bucketName,
    this.prefix,
    this.delimiter,
    required this.contents,
    required this.commonPrefixes,
    required this.maxKeys,
    this.continuationToken,
    this.startAfter,
    this.nextMarker,
    this.isTruncated = false,
    this.nextContinuationToken,
    required this.totalKeys,
    this.v2 = false,
    this.urlEncoded = false,
  });

  /// This page answered as the listing the client asked for.
  ListObjectsResponse asListing({required bool v2, required bool urlEncoded}) =>
      ListObjectsResponse(
        bucketName: bucketName,
        prefix: prefix,
        delimiter: delimiter,
        contents: contents,
        commonPrefixes: commonPrefixes,
        maxKeys: maxKeys,
        continuationToken: continuationToken,
        startAfter: startAfter,
        nextMarker: nextMarker,
        isTruncated: isTruncated,
        nextContinuationToken: nextContinuationToken,
        totalKeys: totalKeys,
        v2: v2,
        urlEncoded: urlEncoded,
      );

  /// Objects and common prefixes returned in this page.
  int get keyCount => contents.length + commonPrefixes.length;

  Map<String, Object?> toJson() {
    return {
      'name': bucketName,
      'prefix': prefix,
      'delimiter': delimiter,
      'max_keys': maxKeys,
      'key_count': keyCount,
      'continuation_token': continuationToken,
      'is_truncated': isTruncated,
      'next_continuation_token': nextContinuationToken,
      'total_keys': totalKeys,
      'contents': contents.map((e) => e.toJson()).toList(),
      'common_prefixes': commonPrefixes,
    };
  }

  /// ListBucketResult, V1 or V2.
  @override
  XmlElement toXml() {
    String text(String value) => urlEncoded ? S3Xml.urlEncode(value) : value;
    return S3Xml.root('ListBucketResult', [
      XmlElement.leaf('Name', bucketName),
      XmlElement.leaf('Prefix', text(prefix ?? '')),
      if (delimiter != null) XmlElement.leaf('Delimiter', text(delimiter!)),
      if (urlEncoded) XmlElement.leaf('EncodingType', 'url'),
      XmlElement.leaf('MaxKeys', maxKeys),
      if (v2) ...[
        XmlElement.leaf('KeyCount', keyCount),
        if (startAfter != null)
          XmlElement.leaf('StartAfter', text(startAfter!)),
        if (continuationToken != null)
          XmlElement.leaf('ContinuationToken', continuationToken),
        if (nextContinuationToken != null)
          XmlElement.leaf('NextContinuationToken', nextContinuationToken),
      ] else ...[
        XmlElement.leaf('Marker', text(startAfter ?? '')),
        if (nextMarker != null)
          XmlElement.leaf('NextMarker', text(nextMarker!)),
      ],
      XmlElement.leaf('IsTruncated', isTruncated),
      for (final file in contents)
        XmlElement(
          'Contents',
          elements: [
            XmlElement.leaf('Key', text(file.key)),
            XmlElement.leaf('LastModified', S3Xml.date(file.lastModified)),
            S3Xml.etag(file.etag),
            XmlElement.leaf('Size', file.size),
            XmlElement.leaf('StorageClass', 'STANDARD'),
          ],
        ),
      for (final prefix in commonPrefixes)
        XmlElement(
          'CommonPrefixes',
          elements: [XmlElement.leaf('Prefix', text(prefix))],
        ),
    ]);
  }
}
