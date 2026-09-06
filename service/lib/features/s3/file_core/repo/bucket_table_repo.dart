import 'package:drift/drift.dart';
import 'package:service/feather.dart';

class BucketTableRepo {
  final AppDatabase _db;

  BucketTableRepo(this._db);

  Future<List<BucketsTableData>> findAll() {
    return _db.select(_db.bucketsTable).get();
  }

  Future<BucketsTableData?> findByName(String name) {
    return (_db.select(_db.bucketsTable)..where((tbl) => tbl.name.equals(name)))
        .getSingleOrNull();
  }

  Future save({
    required String name,
    String? description,
    int? color,
  }) async {
    await _db.into(_db.bucketsTable).insert(
          BucketsTableCompanion.insert(
            name: name,
            description: Value(description),
            color: color != null ? Value(color) : const Value.absent(),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
          onConflict: DoUpdate(
            (old) => BucketsTableCompanion.custom(
              description: Variable(description),
              color: color != null ? Variable(color) : old.color,
              updatedAt: Variable(DateTime.now()),
            ),
          ),
        );
  }

  Future delete(String name) async {
    await (_db.delete(_db.bucketsTable)..where((tbl) => tbl.name.equals(name)))
        .go();
  }
}
