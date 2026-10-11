import 'package:drift/drift.dart';
import 'package:service/feather.dart';

class BucketTableRepo {
  final AppDatabase _db;

  BucketTableRepo(this._db);

  Future<List<BucketTableData>> findAll() {
    return _db.select(_db.bucketTable).get();
  }

  Future<BucketTableData?> findByName(String name) {
    return (_db.select(
      _db.bucketTable,
    )..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
  }

  Future save({required String name, String? description, int? color}) async {
    await _db
        .into(_db.bucketTable)
        .insert(
          BucketTableCompanion.insert(
            name: name,
            description: Value(description),
            color: Value(color),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
          onConflict: DoUpdate(
            (old) => BucketTableCompanion.custom(
              description: Variable(description),
              color: Variable(color),
              updatedAt: Variable(DateTime.now()),
            ),
          ),
        );
  }

  Future delete(String name) async {
    await (_db.delete(
      _db.bucketTable,
    )..where((tbl) => tbl.name.equals(name))).go();
  }
}
