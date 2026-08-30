// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AnonymousRulesTableTable extends AnonymousRulesTable
    with TableInfo<$AnonymousRulesTableTable, AnonymousRulesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnonymousRulesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _bucketNameMeta = const VerificationMeta(
    'bucketName',
  );
  @override
  late final GeneratedColumn<String> bucketName = GeneratedColumn<String>(
    'bucket_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _prefixMeta = const VerificationMeta('prefix');
  @override
  late final GeneratedColumn<String> prefix = GeneratedColumn<String>(
    'prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AnonymousAccessType, String>
  access =
      GeneratedColumn<String>(
        'access',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AnonymousAccessType>(
        $AnonymousRulesTableTable.$converteraccess,
      );
  @override
  List<GeneratedColumn> get $columns => [id, bucketName, prefix, access];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anonymous_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnonymousRulesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bucket_name')) {
      context.handle(
        _bucketNameMeta,
        bucketName.isAcceptableOrUnknown(data['bucket_name']!, _bucketNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bucketNameMeta);
    }
    if (data.containsKey('prefix')) {
      context.handle(
        _prefixMeta,
        prefix.isAcceptableOrUnknown(data['prefix']!, _prefixMeta),
      );
    } else if (isInserting) {
      context.missing(_prefixMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnonymousRulesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnonymousRulesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bucketName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket_name'],
      )!,
      prefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefix'],
      )!,
      access: $AnonymousRulesTableTable.$converteraccess.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}access'],
        )!,
      ),
    );
  }

  @override
  $AnonymousRulesTableTable createAlias(String alias) {
    return $AnonymousRulesTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AnonymousAccessType, String, String>
  $converteraccess = const EnumNameConverter<AnonymousAccessType>(
    AnonymousAccessType.values,
  );
}

class AnonymousRulesTableData extends DataClass
    implements Insertable<AnonymousRulesTableData> {
  final int id;
  final String bucketName;
  final String prefix;
  final AnonymousAccessType access;
  const AnonymousRulesTableData({
    required this.id,
    required this.bucketName,
    required this.prefix,
    required this.access,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bucket_name'] = Variable<String>(bucketName);
    map['prefix'] = Variable<String>(prefix);
    {
      map['access'] = Variable<String>(
        $AnonymousRulesTableTable.$converteraccess.toSql(access),
      );
    }
    return map;
  }

  AnonymousRulesTableCompanion toCompanion(bool nullToAbsent) {
    return AnonymousRulesTableCompanion(
      id: Value(id),
      bucketName: Value(bucketName),
      prefix: Value(prefix),
      access: Value(access),
    );
  }

  factory AnonymousRulesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnonymousRulesTableData(
      id: serializer.fromJson<int>(json['id']),
      bucketName: serializer.fromJson<String>(json['bucketName']),
      prefix: serializer.fromJson<String>(json['prefix']),
      access: $AnonymousRulesTableTable.$converteraccess.fromJson(
        serializer.fromJson<String>(json['access']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bucketName': serializer.toJson<String>(bucketName),
      'prefix': serializer.toJson<String>(prefix),
      'access': serializer.toJson<String>(
        $AnonymousRulesTableTable.$converteraccess.toJson(access),
      ),
    };
  }

  AnonymousRulesTableData copyWith({
    int? id,
    String? bucketName,
    String? prefix,
    AnonymousAccessType? access,
  }) => AnonymousRulesTableData(
    id: id ?? this.id,
    bucketName: bucketName ?? this.bucketName,
    prefix: prefix ?? this.prefix,
    access: access ?? this.access,
  );
  AnonymousRulesTableData copyWithCompanion(AnonymousRulesTableCompanion data) {
    return AnonymousRulesTableData(
      id: data.id.present ? data.id.value : this.id,
      bucketName: data.bucketName.present
          ? data.bucketName.value
          : this.bucketName,
      prefix: data.prefix.present ? data.prefix.value : this.prefix,
      access: data.access.present ? data.access.value : this.access,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnonymousRulesTableData(')
          ..write('id: $id, ')
          ..write('bucketName: $bucketName, ')
          ..write('prefix: $prefix, ')
          ..write('access: $access')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bucketName, prefix, access);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnonymousRulesTableData &&
          other.id == this.id &&
          other.bucketName == this.bucketName &&
          other.prefix == this.prefix &&
          other.access == this.access);
}

class AnonymousRulesTableCompanion
    extends UpdateCompanion<AnonymousRulesTableData> {
  final Value<int> id;
  final Value<String> bucketName;
  final Value<String> prefix;
  final Value<AnonymousAccessType> access;
  const AnonymousRulesTableCompanion({
    this.id = const Value.absent(),
    this.bucketName = const Value.absent(),
    this.prefix = const Value.absent(),
    this.access = const Value.absent(),
  });
  AnonymousRulesTableCompanion.insert({
    this.id = const Value.absent(),
    required String bucketName,
    required String prefix,
    required AnonymousAccessType access,
  }) : bucketName = Value(bucketName),
       prefix = Value(prefix),
       access = Value(access);
  static Insertable<AnonymousRulesTableData> custom({
    Expression<int>? id,
    Expression<String>? bucketName,
    Expression<String>? prefix,
    Expression<String>? access,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bucketName != null) 'bucket_name': bucketName,
      if (prefix != null) 'prefix': prefix,
      if (access != null) 'access': access,
    });
  }

  AnonymousRulesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? bucketName,
    Value<String>? prefix,
    Value<AnonymousAccessType>? access,
  }) {
    return AnonymousRulesTableCompanion(
      id: id ?? this.id,
      bucketName: bucketName ?? this.bucketName,
      prefix: prefix ?? this.prefix,
      access: access ?? this.access,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bucketName.present) {
      map['bucket_name'] = Variable<String>(bucketName.value);
    }
    if (prefix.present) {
      map['prefix'] = Variable<String>(prefix.value);
    }
    if (access.present) {
      map['access'] = Variable<String>(
        $AnonymousRulesTableTable.$converteraccess.toSql(access.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnonymousRulesTableCompanion(')
          ..write('id: $id, ')
          ..write('bucketName: $bucketName, ')
          ..write('prefix: $prefix, ')
          ..write('access: $access')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnonymousRulesTableTable anonymousRulesTable =
      $AnonymousRulesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [anonymousRulesTable];
}

typedef $$AnonymousRulesTableTableCreateCompanionBuilder =
    AnonymousRulesTableCompanion Function({
      Value<int> id,
      required String bucketName,
      required String prefix,
      required AnonymousAccessType access,
    });
typedef $$AnonymousRulesTableTableUpdateCompanionBuilder =
    AnonymousRulesTableCompanion Function({
      Value<int> id,
      Value<String> bucketName,
      Value<String> prefix,
      Value<AnonymousAccessType> access,
    });

class $$AnonymousRulesTableTableFilterComposer
    extends Composer<_$AppDatabase, $AnonymousRulesTableTable> {
  $$AnonymousRulesTableTableFilterComposer({
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

  ColumnFilters<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    AnonymousAccessType,
    AnonymousAccessType,
    String
  >
  get access => $composableBuilder(
    column: $table.access,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$AnonymousRulesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AnonymousRulesTableTable> {
  $$AnonymousRulesTableTableOrderingComposer({
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

  ColumnOrderings<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get access => $composableBuilder(
    column: $table.access,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnonymousRulesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnonymousRulesTableTable> {
  $$AnonymousRulesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prefix =>
      $composableBuilder(column: $table.prefix, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AnonymousAccessType, String> get access =>
      $composableBuilder(column: $table.access, builder: (column) => column);
}

class $$AnonymousRulesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnonymousRulesTableTable,
          AnonymousRulesTableData,
          $$AnonymousRulesTableTableFilterComposer,
          $$AnonymousRulesTableTableOrderingComposer,
          $$AnonymousRulesTableTableAnnotationComposer,
          $$AnonymousRulesTableTableCreateCompanionBuilder,
          $$AnonymousRulesTableTableUpdateCompanionBuilder,
          (
            AnonymousRulesTableData,
            BaseReferences<
              _$AppDatabase,
              $AnonymousRulesTableTable,
              AnonymousRulesTableData
            >,
          ),
          AnonymousRulesTableData,
          PrefetchHooks Function()
        > {
  $$AnonymousRulesTableTableTableManager(
    _$AppDatabase db,
    $AnonymousRulesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnonymousRulesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnonymousRulesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AnonymousRulesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bucketName = const Value.absent(),
                Value<String> prefix = const Value.absent(),
                Value<AnonymousAccessType> access = const Value.absent(),
              }) => AnonymousRulesTableCompanion(
                id: id,
                bucketName: bucketName,
                prefix: prefix,
                access: access,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String bucketName,
                required String prefix,
                required AnonymousAccessType access,
              }) => AnonymousRulesTableCompanion.insert(
                id: id,
                bucketName: bucketName,
                prefix: prefix,
                access: access,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnonymousRulesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnonymousRulesTableTable,
      AnonymousRulesTableData,
      $$AnonymousRulesTableTableFilterComposer,
      $$AnonymousRulesTableTableOrderingComposer,
      $$AnonymousRulesTableTableAnnotationComposer,
      $$AnonymousRulesTableTableCreateCompanionBuilder,
      $$AnonymousRulesTableTableUpdateCompanionBuilder,
      (
        AnonymousRulesTableData,
        BaseReferences<
          _$AppDatabase,
          $AnonymousRulesTableTable,
          AnonymousRulesTableData
        >,
      ),
      AnonymousRulesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnonymousRulesTableTableTableManager get anonymousRulesTable =>
      $$AnonymousRulesTableTableTableManager(_db, _db.anonymousRulesTable);
}
