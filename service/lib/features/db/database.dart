import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:service/feather.dart';

part 'database.g.dart';

//Generar el codigo
//fvm dart run build_runner build

class AnonymousRulesTable extends Table {
  @override
  String get tableName => 'anonymous_rules';

  IntColumn get id => integer().autoIncrement()();

  TextColumn get bucketName => text().unique()();

  TextColumn get prefix => text()();

  TextColumn get access => textEnum<AnonymousAccessType>()();

  @override
  List<String> get customConstraints => ['UNIQUE (bucket_name, prefix)'];
}

@DriftDatabase(tables: [AnonymousRulesTable])
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
