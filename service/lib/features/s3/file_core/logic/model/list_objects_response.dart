import 'package:service/feather.dart';

class ListObjectsResponse {
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
  });

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
}
