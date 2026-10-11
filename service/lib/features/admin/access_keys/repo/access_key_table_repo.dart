import 'package:drift/drift.dart';
import 'package:service/feather.dart';

/// A key's row with its grants, as stored (the secret still encrypted).
typedef AccessKeyRow = ({
  AccessKeyTableData key,
  List<AccessKeyGrantTableData> grants,
});

class AccessKeyTableRepo {
  final AppDatabase _db;

  AccessKeyTableRepo(this._db);

  /// Every key, oldest first.
  Future<List<AccessKeyRow>> getAll() async {
    final keys = await (_db.select(
      _db.accessKeyTable,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])).get();
    final grants = await _db.select(_db.accessKeyGrantTable).get();
    return [
      for (final key in keys)
        (
          key: key,
          grants: [
            for (final grant in grants)
              if (grant.keyId == key.id) grant,
          ],
        ),
    ];
  }

  Future<AccessKeyRow?> get(String id) async {
    final key = await (_db.select(
      _db.accessKeyTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (key == null) return null;
    final grants = await (_db.select(
      _db.accessKeyGrantTable,
    )..where((tbl) => tbl.keyId.equals(id))).get();
    return (key: key, grants: grants);
  }

  Future<void> insert({
    required String id,
    required String name,
    required String secretEncrypted,
    required AccessKeyLevel? allBuckets,
    required List<AccessKeyGrant> grants,
    required DateTime? expiresAt,
  }) async {
    await _db.transaction(() async {
      await _db
          .into(_db.accessKeyTable)
          .insert(
            AccessKeyTableCompanion.insert(
              id: id,
              name: name,
              secretEncrypted: secretEncrypted,
              allBuckets: Value(allBuckets),
              expiresAt: Value(expiresAt),
            ),
          );
      await _insertGrants(id, grants);
    });
  }

  /// Replaces the name, state, scope and expiration; the secret stays.
  Future<void> update({
    required String id,
    required String name,
    required bool enabled,
    required AccessKeyLevel? allBuckets,
    required List<AccessKeyGrant> grants,
    required DateTime? expiresAt,
  }) async {
    await _db.transaction(() async {
      await (_db.update(
        _db.accessKeyTable,
      )..where((tbl) => tbl.id.equals(id))).write(
        AccessKeyTableCompanion(
          name: Value(name),
          enabled: Value(enabled),
          allBuckets: Value(allBuckets),
          expiresAt: Value(expiresAt),
        ),
      );
      await _deleteGrants(id);
      await _insertGrants(id, grants);
    });
  }

  Future<void> updateSecret({
    required String id,
    required String secretEncrypted,
  }) async {
    await (_db.update(_db.accessKeyTable)..where((tbl) => tbl.id.equals(id)))
        .write(AccessKeyTableCompanion(secretEncrypted: Value(secretEncrypted)));
  }

  Future<void> updateLastUsed({
    required String id,
    required DateTime at,
  }) async {
    await (_db.update(_db.accessKeyTable)..where((tbl) => tbl.id.equals(id)))
        .write(AccessKeyTableCompanion(lastUsedAt: Value(at)));
  }

  Future<void> delete(String id) async {
    await _db.transaction(() async {
      await _deleteGrants(id);
      await (_db.delete(
        _db.accessKeyTable,
      )..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  /// When a bucket is deleted, the keys lose their access to it.
  Future<void> deleteGrantsByBucket(String bucketName) async {
    await (_db.delete(
      _db.accessKeyGrantTable,
    )..where((tbl) => tbl.bucketName.equals(bucketName))).go();
  }

  Future<void> _insertGrants(String id, List<AccessKeyGrant> grants) async {
    await _db.batch((batch) {
      batch.insertAll(_db.accessKeyGrantTable, [
        for (final grant in grants)
          AccessKeyGrantTableCompanion.insert(
            keyId: id,
            bucketName: grant.bucket,
            access: grant.access,
          ),
      ]);
    });
  }

  Future<void> _deleteGrants(String id) async {
    await (_db.delete(
      _db.accessKeyGrantTable,
    )..where((tbl) => tbl.keyId.equals(id))).go();
  }
}
