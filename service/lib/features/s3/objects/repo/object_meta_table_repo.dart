import 'package:drift/drift.dart';
import 'package:service/feather.dart';

class ObjectMetaTableRepo {
  final AppDatabase _db;

  ObjectMetaTableRepo(this._db);

  Future<ObjectMetaTableData?> find(String bucketName, String key) {
    return (_db.select(_db.objectMetaTable)..where(
          (tbl) =>
              tbl.bucketName.equals(bucketName) & tbl.objectKey.equals(key),
        ))
        .getSingleOrNull();
  }

  Future<List<ObjectMetaTableData>> findByKeys(
    String bucketName,
    Iterable<String> keys,
  ) {
    return (_db.select(_db.objectMetaTable)..where(
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
    required String headers,
  }) async {
    await _db
        .into(_db.objectMetaTable)
        .insertOnConflictUpdate(
          ObjectMetaTableCompanion.insert(
            bucketName: bucketName,
            objectKey: key,
            etag: etag,
            size: size,
            modified: modified.microsecondsSinceEpoch,
            headers: Value(headers),
          ),
        );
  }

  Future<void> delete(String bucketName, String key) async {
    await (_db.delete(_db.objectMetaTable)..where(
          (tbl) =>
              tbl.bucketName.equals(bucketName) & tbl.objectKey.equals(key),
        ))
        .go();
  }

  /// Deletes the rows of every key that starts with [prefix] (a folder).
  Future<void> deleteByPrefix(String bucketName, String prefix) async {
    await (_db.delete(_db.objectMetaTable)..where(
          (tbl) =>
              tbl.bucketName.equals(bucketName) &
              tbl.objectKey.substr(1, prefix.length).equals(prefix),
        ))
        .go();
  }

  Future<void> deleteByBucket(String bucketName) async {
    await (_db.delete(
      _db.objectMetaTable,
    )..where((tbl) => tbl.bucketName.equals(bucketName))).go();
  }
}
