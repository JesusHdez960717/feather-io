import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

part 'database.g.dart';

// Generate the code with: fvm dart run build_runner build

class BucketTable extends Table {
  @override
  String get tableName => 'bucket';

  TextColumn get name => text()();

  TextColumn get description => text().nullable()();

  IntColumn get color => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {name};
}

class AnonymousRuleTable extends Table {
  @override
  String get tableName => 'anonymous_rule';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get bucketName => text().references(BucketTable, #name)();

  TextColumn get prefix => text()();

  TextColumn get access => textEnum<AnonymousAccessType>()();

  @override
  List<String> get customConstraints => ['UNIQUE (bucket_name, prefix)'];
}

/// Metadata of each object, stored when it is written: its ETag (md5) and the
/// headers it was uploaded with (`Content-Type`, `x-amz-meta-*`…). [size] and
/// [modified] are the file's at that moment: if they don't match the current
/// ones, the file changed outside the service and the ETag is recomputed.
class ObjectMetaTable extends Table {
  @override
  String get tableName => 'object_meta';

  TextColumn get bucketName => text().references(BucketTable, #name)();

  TextColumn get objectKey => text()();

  TextColumn get etag => text()();

  IntColumn get size => integer()();

  /// File modification time, in microseconds since the epoch.
  IntColumn get modified => integer()();

  /// Object headers as JSON (`{"content-type": "image/png", …}`).
  TextColumn get headers => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {bucketName, objectKey};
}

/// Access keys for native S3 clients, besides the root key of the env. The
/// secret is stored encrypted ([SecretCipher]), never in plain text.
class AccessKeyTable extends Table {
  @override
  String get tableName => 'access_key';

  /// Access key id (`FIOK…`), the one clients send in the signature.
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get secretEncrypted => text()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Level on every bucket; null when the key only reaches the buckets of
  /// [AccessKeyGrantTable].
  TextColumn get allBuckets => textEnum<AccessKeyLevel>().nullable()();

  DateTimeColumn get expiresAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Level of an access key on one bucket.
class AccessKeyGrantTable extends Table {
  @override
  String get tableName => 'access_key_grant';

  TextColumn get keyId => text().references(AccessKeyTable, #id)();

  TextColumn get bucketName => text().references(BucketTable, #name)();

  TextColumn get access => textEnum<AccessKeyLevel>()();

  @override
  Set<Column> get primaryKey => {keyId, bucketName};
}

@DriftDatabase(
  tables: [
    AccessKeyGrantTable,
    AccessKeyTable,
    AnonymousRuleTable,
    BucketTable,
    ObjectMetaTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  /// Folder of the database inside `STORAGE_VOLUME_PATH`. It starts with a
  /// dot, so it isn't a valid bucket and isn't listed.
  static const String folderName = '.db';

  static const String fileName = 'feather-io.sqlite';

  /// `STORAGE_VOLUME_PATH/.db/feather-io.sqlite`: the metadata lives in the
  /// same volume as the objects it describes.
  static String get defaultPath =>
      p.join(env.storageVolumePath, folderName, fileName);

  static QueryExecutor _openConnection() {
    final file = File(defaultPath);
    // SQLite creates the file but not its folder
    file.parent.createSync(recursive: true);
    return NativeDatabase.createInBackground(file);
  }
}
