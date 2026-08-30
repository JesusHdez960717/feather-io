import 'package:drift/drift.dart';
import 'package:service/feather.dart';

class AccessRuleTableRepo {
  final AppDatabase _db;

  AccessRuleTableRepo(this._db);

  Future<List<AnonymousRulesTableData>> getRulesByBucket({
    required String bucket,
  }) {
    return (_db.select(
      _db.anonymousRulesTable,
    )..where((tbl) => tbl.bucketName.equals(bucket))).get();
  }

  Future<AnonymousRulesTableData?> getRule({
    required String bucket,
    required String prefix,
  }) {
    return (_db.select(_db.anonymousRulesTable)..where(
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
        .into(_db.anonymousRulesTable)
        .insert(
          AnonymousRulesTableCompanion.insert(
            bucketName: bucketName,
            prefix: model.prefix,
            access: model.access,
          ),
        );
  }
}
