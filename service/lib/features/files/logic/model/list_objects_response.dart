import 'package:service/feather.dart';

class ListObjectsResponse implements Serializable {
  final String bucketName;
  final String? prefix;
  final String? delimiter;
  final List<FileModel> contents;
  final List<String> commonPrefixes;

  ListObjectsResponse({
    required this.bucketName,
    this.prefix,
    this.delimiter,
    required this.contents,
    required this.commonPrefixes,
  });

  @override
  Object? toJson() {
    return {
      'name': bucketName,
      'prefix': prefix,
      'delimiter': delimiter,
      'contents': contents.map((e) => e.toJson()).toList(),
      'common_prefixes': commonPrefixes,
    };
  }
}
