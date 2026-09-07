import 'package:drift/drift.dart';
import 'package:service/feather.dart';

class AccessRuleTableRepo {
  final AppDatabase _db;

  AccessRuleTableRepo(this._db);

  Future<List<AnonymousRuleTableData>> getRulesByBucket({
    required String bucket,
  }) {
    return (_db.select(
      _db.anonymousRuleTable,
    )..where((tbl) => tbl.bucketName.equals(bucket))).get();
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
