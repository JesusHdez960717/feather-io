import 'package:service/feather.dart';

class ListObjectsResponse implements Serializable {
  final String bucketName;
  final String? prefix;
  final String? delimiter;
  final List<FileModel> contents;
  final List<String> commonPrefixes;

  /// Maximo de claves (objetos + prefijos comunes) de esta pagina
  final int maxKeys;

  /// Token con el que se pidio esta pagina, si no es la primera
  final String? continuationToken;

  /// Hay mas claves despues de esta pagina
  final bool isTruncated;

  /// Token para pedir la pagina siguiente; solo si [isTruncated]
  final String? nextContinuationToken;

  /// Claves (objetos + prefijos comunes) de todas las paginas. No es de S3:
  /// solo va en el JSON, para que la consola pueda mostrar "pagina X de N"
  final int totalKeys;

  ListObjectsResponse({
    required this.bucketName,
    this.prefix,
    this.delimiter,
    required this.contents,
    required this.commonPrefixes,
    required this.maxKeys,
    this.continuationToken,
    this.isTruncated = false,
    this.nextContinuationToken,
    required this.totalKeys,
  });

  /// Objetos y prefijos comunes devueltos en esta pagina
  int get keyCount => contents.length + commonPrefixes.length;

  @override
  Object? toJson() {
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
