import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:service/feather.dart';

/// Metadatos de los objetos (tabla `object_meta`): el ETag, que es el md5 del
/// contenido (o el de S3 para multipart, `md5(md5 de las partes)-N`), y las
/// cabeceras con las que se subio. Se guardan al escribir el objeto; si faltan
/// o el fichero cambio por fuera, el ETag se calcula leyendolo y se guarda
class ObjectMetaService {
  /// ETag de un objeto vacio (y de las carpetas)
  static final String emptyEtag = md5.convert(const []).toString();

  final ObjectMetaTableRepo repo;

  ObjectMetaService() : repo = ObjectMetaTableRepo(di.find());

  /// Guarda los metadatos de [file], recien escrito en [bucketName]/[key]
  Future<void> save({
    required String bucketName,
    required String key,
    required File file,
    required String etag,
    Map<String, String> headers = const {},
  }) async {
    final stat = await file.stat();
    await repo.save(
      bucketName: bucketName,
      key: key,
      etag: etag,
      size: stat.size,
      modified: stat.modified,
      headers: jsonEncode(headers),
    );
  }

  /// Los metadatos de [file]; el ETag se calcula si no esta guardado o ya no vale
  Future<ObjectMetaModel> metaOf({
    required String bucketName,
    required String key,
    required File file,
    FileStat? stat,
  }) async {
    final fileStat = stat ?? await file.stat();
    final stored = await repo.find(bucketName, key);
    final headers = stored == null ? <String, String>{} : _headers(stored);
    if (stored != null && _matches(stored, fileStat)) {
      return ObjectMetaModel(etag: stored.etag, headers: headers);
    }
    final etag = await _compute(bucketName, key, file, fileStat, headers);
    return ObjectMetaModel(etag: etag, headers: headers);
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
          : await _compute(
              bucketName,
              key,
              file,
              stat,
              row == null ? const {} : _headers(row),
            );
    }
    return etags;
  }

  Future<void> forget(String bucketName, String key) =>
      repo.delete(bucketName, key);

  /// Olvida todo lo que hay por debajo de la carpeta [prefix]
  Future<void> forgetFolder(String bucketName, String prefix) =>
      repo.deleteByPrefix(bucketName, prefix.endsWith('/') ? prefix : '$prefix/');

  Future<void> forgetBucket(String bucketName) =>
      repo.deleteByBucket(bucketName);

  bool _matches(ObjectMetaTableData row, FileStat stat) =>
      row.size == stat.size &&
      row.modified == stat.modified.microsecondsSinceEpoch;

  Map<String, String> _headers(ObjectMetaTableData row) {
    try {
      return (jsonDecode(row.headers) as Map<String, dynamic>).map(
        (name, value) => MapEntry(name, value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<String> _compute(
    String bucketName,
    String key,
    File file,
    FileStat stat,
    Map<String, String> headers,
  ) async {
    final etag = (await md5.bind(file.openRead()).first).toString();
    await repo.save(
      bucketName: bucketName,
      key: key,
      etag: etag,
      size: stat.size,
      modified: stat.modified,
      headers: jsonEncode(headers),
    );
    return etag;
  }
}

/// Calcula el md5 de un stream mientras pasa por [bind], sin guardarlo entero
class Md5Tap {
  /// Escribe [binary] en [file] y devuelve su md5. Si el stream falla, cierra
  /// el fichero (`pipe` no lo hace, y en Windows no se puede borrar abierto),
  /// lo borra y relanza el error
  static Future<String> write(Stream<List<int>> binary, File file) async {
    final hasher = Md5Tap();
    final sink = file.openWrite();
    try {
      await hasher.bind(binary).pipe(sink);
    } catch (_) {
      try {
        await sink.close();
      } catch (_) {}
      if (await file.exists()) await file.delete();
      rethrow;
    }
    return hasher.close();
  }

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
