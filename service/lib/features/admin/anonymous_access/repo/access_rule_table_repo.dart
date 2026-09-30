import 'package:drift/drift.dart';
import 'package:service/feather.dart';

class AccessRuleTableRepo {
  final AppDatabase _db;

  AccessRuleTableRepo(this._db);

  Future<List<AnonymousRuleTableData>> getRulesByBucket({
    required String bucket,
  }) {
    //en orden de creacion: si varias reglas coinciden, gana la primera
    return (_db.select(_db.anonymousRuleTable)
          ..where((tbl) => tbl.bucketName.equals(bucket))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.id)]))
        .get();
  }

  Future<AnonymousRuleTableData?> getRule({
    required String bucket,
    required String prefix,
  }) {
    return (_db.select(_db.anonymousRuleTable)..where(
          (tbl) => Expression.and([
            tbl.bucketName.equals(bucket),
            tbl.prefix.equals(prefix),
          ]),
        ))
        .getSingleOrNull();
  }

  Future save({
    required String bucketName,
    required AnonymousRuleModel model,
  }) async {
    await _db
        .into(_db.anonymousRuleTable)
        .insert(
          AnonymousRuleTableCompanion.insert(
            bucketName: bucketName,
            prefix: model.prefix,
            access: model.access,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future deleteByBucket(String bucketName) async {
    await (_db.delete(
      _db.anonymousRuleTable,
    )..where((tbl) => tbl.bucketName.equals(bucketName))).go();
  }

  Future deleteRule({
    required String bucketName,
    required String prefix,
  }) async {
    await (_db.delete(_db.anonymousRuleTable)
          ..where((tbl) => tbl.bucketName.equals(bucketName))
          ..where((tbl) => tbl.prefix.equals(prefix)))
        .go();
  }
}
