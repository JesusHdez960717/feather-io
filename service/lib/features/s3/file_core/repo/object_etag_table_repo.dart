import 'package:drift/drift.dart';
import 'package:service/feather.dart';

class ObjectEtagTableRepo {
  final AppDatabase _db;

  ObjectEtagTableRepo(this._db);

  Future<ObjectEtagTableData?> find(String bucketName, String key) {
    return (_db.select(_db.objectEtagTable)..where(
          (tbl) =>
              tbl.bucketName.equals(bucketName) & tbl.objectKey.equals(key),
        ))
        .getSingleOrNull();
  }

  Future<List<ObjectEtagTableData>> findByKeys(
    String bucketName,
    Iterable<String> keys,
  ) {
    return (_db.select(_db.objectEtagTable)..where(
          (tbl) => tbl.bucketName.equals(bucketName) & tbl.objectKey.isIn(keys),
        ))
        .get();
  }

  Future<void> save({
    required String bucketName,
    required String key,
    required String etag,
    required int size,
    required DateTime modified,
  }) async {
    await _db
        .into(_db.objectEtagTable)
        .insertOnConflictUpdate(
          ObjectEtagTableCompanion.insert(
            bucketName: bucketName,
            objectKey: key,
            etag: etag,
            size: size,
            modified: modified.microsecondsSinceEpoch,
          ),
        );
  }

  Future<void> delete(String bucketName, String key) async {
    await (_db.delete(_db.objectEtagTable)..where(
          (tbl) =>
              tbl.bucketName.equals(bucketName) & tbl.objectKey.equals(key),
        ))
        .go();
  }

  /// Borra los de todas las keys que empiezan por [prefix] (una carpeta)
  Future<void> deleteByPrefix(String bucketName, String prefix) async {
    await (_db.delete(_db.objectEtagTable)..where(
          (tbl) =>
              tbl.bucketName.equals(bucketName) &
              tbl.objectKey.substr(1, prefix.length).equals(prefix),
        ))
        .go();
  }

  Future<void> deleteByBucket(String bucketName) async {
    await (_db.delete(
      _db.objectEtagTable,
    )..where((tbl) => tbl.bucketName.equals(bucketName))).go();
  }
}
