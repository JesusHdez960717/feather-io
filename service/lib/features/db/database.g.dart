// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AnonymousRulesTableTable extends AnonymousRuleTable
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

class $BucketsTableTable extends BucketTable
    with TableInfo<$BucketsTableTable, BucketsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BucketsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    description,
    color,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'buckets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BucketsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  BucketsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BucketsTableData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BucketsTableTable createAlias(String alias) {
    return $BucketsTableTable(attachedDatabase, alias);
  }
}

class BucketsTableData extends DataClass
    implements Insertable<BucketsTableData> {
  final String name;
  final String? description;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BucketsTableData({
    required this.name,
    this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['color'] = Variable<int>(color);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BucketsTableCompanion toCompanion(bool nullToAbsent) {
    return BucketsTableCompanion(
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      color: Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BucketsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BucketsTableData(
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<int>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'color': serializer.toJson<int>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BucketsTableData copyWith({
    String? name,
    Value<String?> description = const Value.absent(),
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BucketsTableData(
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    color: color ?? this.color,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BucketsTableData copyWithCompanion(BucketsTableCompanion data) {
    return BucketsTableData(
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BucketsTableData(')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(name, description, color, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BucketsTableData &&
          other.name == this.name &&
          other.description == this.description &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BucketsTableCompanion extends UpdateCompanion<BucketsTableData> {
  final Value<String> name;
  final Value<String?> description;
  final Value<int> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BucketsTableCompanion({
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BucketsTableCompanion.insert({
    required String name,
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<BucketsTableData> custom({
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BucketsTableCompanion copyWith({
    Value<String>? name,
    Value<String?>? description,
    Value<int>? color,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BucketsTableCompanion(
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BucketsTableCompanion(')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnonymousRulesTableTable anonymousRulesTable =
      $AnonymousRulesTableTable(this);
  late final $BucketsTableTable bucketsTable = $BucketsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    anonymousRulesTable,
    bucketsTable,
  ];
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
typedef $$BucketsTableTableCreateCompanionBuilder =
    BucketsTableCompanion Function({
      required String name,
      Value<String?> description,
      Value<int> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BucketsTableTableUpdateCompanionBuilder =
    BucketsTableCompanion Function({
      Value<String> name,
      Value<String?> description,
      Value<int> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BucketsTableTableFilterComposer
    extends Composer<_$AppDatabase, $BucketsTableTable> {
  $$BucketsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BucketsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BucketsTableTable> {
  $$BucketsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BucketsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BucketsTableTable> {
  $$BucketsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BucketsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BucketsTableTable,
          BucketsTableData,
          $$BucketsTableTableFilterComposer,
          $$BucketsTableTableOrderingComposer,
          $$BucketsTableTableAnnotationComposer,
          $$BucketsTableTableCreateCompanionBuilder,
          $$BucketsTableTableUpdateCompanionBuilder,
          (
            BucketsTableData,
            BaseReferences<_$AppDatabase, $BucketsTableTable, BucketsTableData>,
          ),
          BucketsTableData,
          PrefetchHooks Function()
        > {
  $$BucketsTableTableTableManager(_$AppDatabase db, $BucketsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BucketsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BucketsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BucketsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BucketsTableCompanion(
                name: name,
                description: description,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BucketsTableCompanion.insert(
                name: name,
                description: description,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BucketsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BucketsTableTable,
      BucketsTableData,
      $$BucketsTableTableFilterComposer,
      $$BucketsTableTableOrderingComposer,
      $$BucketsTableTableAnnotationComposer,
      $$BucketsTableTableCreateCompanionBuilder,
      $$BucketsTableTableUpdateCompanionBuilder,
      (
        BucketsTableData,
        BaseReferences<_$AppDatabase, $BucketsTableTable, BucketsTableData>,
      ),
      BucketsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnonymousRulesTableTableTableManager get anonymousRulesTable =>
      $$AnonymousRulesTableTableTableManager(_db, _db.anonymousRulesTable);
  $$BucketsTableTableTableManager get bucketsTable =>
      $$BucketsTableTableTableManager(_db, _db.bucketsTable);
}
