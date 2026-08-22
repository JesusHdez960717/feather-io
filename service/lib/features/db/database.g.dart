// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BucketTable extends Bucket with TableInfo<$BucketTable, BucketData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BucketTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bucket';
  @override
  VerificationContext validateIntegrity(
    Insertable<BucketData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BucketData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BucketData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $BucketTable createAlias(String alias) {
    return $BucketTable(attachedDatabase, alias);
  }
}

class BucketData extends DataClass implements Insertable<BucketData> {
  final int id;
  final String name;
  const BucketData({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  BucketCompanion toCompanion(bool nullToAbsent) {
    return BucketCompanion(id: Value(id), name: Value(name));
  }

  factory BucketData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BucketData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  BucketData copyWith({int? id, String? name}) =>
      BucketData(id: id ?? this.id, name: name ?? this.name);
  BucketData copyWithCompanion(BucketCompanion data) {
    return BucketData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BucketData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BucketData && other.id == this.id && other.name == this.name);
}

class BucketCompanion extends UpdateCompanion<BucketData> {
  final Value<int> id;
  final Value<String> name;
  const BucketCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  BucketCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<BucketData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  BucketCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return BucketCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BucketCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BucketTable bucket = $BucketTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [bucket];
}

typedef $$BucketTableCreateCompanionBuilder = BucketCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$BucketTableUpdateCompanionBuilder = BucketCompanion Function({
  Value<int> id,
  Value<String> name,
});

class $$BucketTableFilterComposer
    extends Composer<_$AppDatabase, $BucketTable> {
  $$BucketTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BucketTableOrderingComposer
    extends Composer<_$AppDatabase, $BucketTable> {
  $$BucketTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BucketTableAnnotationComposer
    extends Composer<_$AppDatabase, $BucketTable> {
  $$BucketTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$BucketTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BucketTable,
          BucketData,
          $$BucketTableFilterComposer,
          $$BucketTableOrderingComposer,
          $$BucketTableAnnotationComposer,
          $$BucketTableCreateCompanionBuilder,
          $$BucketTableUpdateCompanionBuilder,
          (BucketData, BaseReferences<_$AppDatabase, $BucketTable, BucketData>),
          BucketData,
          PrefetchHooks Function()
        > {
  $$BucketTableTableManager(_$AppDatabase db, $BucketTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BucketTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BucketTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BucketTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) => BucketCompanion(id: id, name: name),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) => BucketCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BucketTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BucketTable,
      BucketData,
      $$BucketTableFilterComposer,
      $$BucketTableOrderingComposer,
      $$BucketTableAnnotationComposer,
      $$BucketTableCreateCompanionBuilder,
      $$BucketTableUpdateCompanionBuilder,
      (BucketData, BaseReferences<_$AppDatabase, $BucketTable, BucketData>),
      BucketData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BucketTableTableManager get bucket =>
      $$BucketTableTableManager(_db, _db.bucket);
}
