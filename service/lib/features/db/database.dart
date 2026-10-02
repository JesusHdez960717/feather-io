import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:service/feather.dart';

part 'database.g.dart';

//Generar el codigo
//fvm dart run build_runner build

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

/// Metadatos de cada objeto, guardados al escribirlo: su ETag (md5) y las
/// cabeceras con las que se subio (`Content-Type`, `x-amz-meta-*`…). [size] y
/// [modified] son los del fichero en ese momento: si no coinciden con los
/// actuales, el fichero ha cambiado por fuera y el ETag se recalcula
class ObjectMetaTable extends Table {
  @override
  String get tableName => 'object_meta';

  TextColumn get bucketName => text().references(BucketTable, #name)();

  TextColumn get objectKey => text()();

  TextColumn get etag => text()();

  IntColumn get size => integer()();

  /// Fecha de modificacion del fichero en microsegundos desde epoch
  IntColumn get modified => integer()();

  /// Cabeceras del objeto en JSON (`{"content-type": "image/png", …}`)
  TextColumn get headers => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {bucketName, objectKey};
}

@DriftDatabase(tables: [AnonymousRuleTable, BucketTable, ObjectMetaTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return NativeDatabase.createInBackground(
      File('./uploads_local/feather-io.sqlite'),
    );
  }
}
