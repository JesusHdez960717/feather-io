import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:service/feather.dart';

/// Object metadata (`object_meta` table): the ETag, which is the md5 of the
/// content (or S3's multipart one, `md5(part md5s)-N`), and the headers it was
/// uploaded with. They are stored when the object is written; if they are
/// missing or the file changed outside the service, the ETag is computed by
/// reading the file and stored.
class ObjectMetaService {
  /// ETag of an empty object (and of folders).
  static final String emptyEtag = md5.convert(const []).toString();

  final ObjectMetaTableRepo repo;

  ObjectMetaService() : repo = ObjectMetaTableRepo(di.find());

  /// Stores the metadata of [file], just written to [bucketName]/[key].
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

  /// The metadata of [file]; the ETag is computed if it isn't stored or is stale.
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

  /// The ETags of several objects of the bucket, with a single query.
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

  /// Forgets everything under the folder [prefix].
  Future<void> forgetFolder(String bucketName, String prefix) => repo
      .deleteByPrefix(bucketName, prefix.endsWith('/') ? prefix : '$prefix/');

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

/// Computes the md5 of a stream as it goes through [bind], without buffering it.
class Md5Tap {
  /// Writes [binary] to [file] and returns its md5. If the stream fails, it
  /// closes the file (`pipe` doesn't, and on Windows an open file can't be
  /// deleted), deletes it and rethrows the error.
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

  /// The hex md5; call it once the stream is done.
  String close() {
    _hasher.close();
    return _digest.value.toString();
  }
}

/// Collects the result of a chunked hash.
class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
