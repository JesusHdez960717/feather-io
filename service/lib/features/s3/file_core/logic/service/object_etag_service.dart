import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:service/feather.dart';

/// ETag de los objetos: el md5 del contenido (o el de S3 para multipart,
/// `md5(md5 de las partes)-N`). Se guarda en la BD al escribir el objeto y,
/// si falta o el fichero cambio por fuera, se calcula leyendolo y se guarda
class ObjectEtagService {
  /// ETag de un objeto vacio (y de las carpetas)
  static final String emptyEtag = md5.convert(const []).toString();

  final ObjectEtagTableRepo repo;

  ObjectEtagService() : repo = ObjectEtagTableRepo(di.find());

  /// Guarda el ETag de [file], recien escrito en [bucketName]/[key]
  Future<void> save({
    required String bucketName,
    required String key,
    required File file,
    required String etag,
  }) async {
    final stat = await file.stat();
    await repo.save(
      bucketName: bucketName,
      key: key,
      etag: etag,
      size: stat.size,
      modified: stat.modified,
    );
  }

  /// El ETag de [file]; lo calcula si no esta guardado o ya no vale
  Future<String> etagOf({
    required String bucketName,
    required String key,
    required File file,
    FileStat? stat,
  }) async {
    final fileStat = stat ?? await file.stat();
    final stored = await repo.find(bucketName, key);
    if (stored != null && _matches(stored, fileStat)) return stored.etag;
    return _compute(bucketName, key, file, fileStat);
  }

  /// Los ETags de varios objetos del bucket, con una sola consulta
  Future<Map<String, String>> etagsOf({
    required String bucketName,
    required Map<String, (File, FileStat)> files,
  }) async {
    final stored = {
      for (final row in await repo.findByKeys(bucketName, files.keys))
        row.objectKey: row,
    };
    final etags = <String, String>{};
    for (final MapEntry(key: key, value: (file, stat)) in files.entries) {
      final row = stored[key];
      etags[key] = row != null && _matches(row, stat)
          ? row.etag
          : await _compute(bucketName, key, file, stat);
    }
    return etags;
  }

  Future<void> forget(String bucketName, String key) =>
      repo.delete(bucketName, key);

  /// Olvida todo lo que hay por debajo de la carpeta [prefix]
  Future<void> forgetFolder(String bucketName, String prefix) => repo
      .deleteByPrefix(bucketName, prefix.endsWith('/') ? prefix : '$prefix/');

  Future<void> forgetBucket(String bucketName) =>
      repo.deleteByBucket(bucketName);

  bool _matches(ObjectEtagTableData row, FileStat stat) =>
      row.size == stat.size &&
      row.modified == stat.modified.microsecondsSinceEpoch;

  Future<String> _compute(
    String bucketName,
    String key,
    File file,
    FileStat stat,
  ) async {
    final etag = (await md5.bind(file.openRead()).first).toString();
    await repo.save(
      bucketName: bucketName,
      key: key,
      etag: etag,
      size: stat.size,
      modified: stat.modified,
    );
    return etag;
  }
}

/// Calcula el md5 de un stream mientras pasa por [bind], sin guardarlo entero
class Md5Tap {
  final _DigestSink _digest = _DigestSink();
  late final ByteConversionSink _hasher = md5.startChunkedConversion(_digest);

  Stream<List<int>> bind(Stream<List<int>> stream) => stream.map((chunk) {
    _hasher.add(chunk);
    return chunk;
  });

  /// El md5 en hexadecimal; llamar cuando el stream ha terminado
  String close() {
    _hasher.close();
    return _digest.value.toString();
  }
}

/// Recoge el resultado de un hash por trozos
class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
