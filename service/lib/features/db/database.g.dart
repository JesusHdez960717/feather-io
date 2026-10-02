// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AnonymousRuleTableTable extends AnonymousRuleTable
    with TableInfo<$AnonymousRuleTableTable, AnonymousRuleTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnonymousRuleTableTable(this.attachedDatabase, [this._alias]);
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
        $AnonymousRuleTableTable.$converteraccess,
      );
  @override
  List<GeneratedColumn> get $columns => [id, bucketName, prefix, access];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anonymous_rule';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnonymousRuleTableData> instance, {
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
  AnonymousRuleTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnonymousRuleTableData(
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
      access: $AnonymousRuleTableTable.$converteraccess.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}access'],
        )!,
      ),
    );
  }

  @override
  $AnonymousRuleTableTable createAlias(String alias) {
    return $AnonymousRuleTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AnonymousAccessType, String, String>
  $converteraccess = const EnumNameConverter<AnonymousAccessType>(
    AnonymousAccessType.values,
  );
}

class AnonymousRuleTableData extends DataClass
    implements Insertable<AnonymousRuleTableData> {
  final int id;
  final String bucketName;
  final String prefix;
  final AnonymousAccessType access;
  const AnonymousRuleTableData({
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
        $AnonymousRuleTableTable.$converteraccess.toSql(access),
      );
    }
    return map;
  }

  AnonymousRuleTableCompanion toCompanion(bool nullToAbsent) {
    return AnonymousRuleTableCompanion(
      id: Value(id),
      bucketName: Value(bucketName),
      prefix: Value(prefix),
      access: Value(access),
    );
  }

  factory AnonymousRuleTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnonymousRuleTableData(
      id: serializer.fromJson<int>(json['id']),
      bucketName: serializer.fromJson<String>(json['bucketName']),
      prefix: serializer.fromJson<String>(json['prefix']),
      access: $AnonymousRuleTableTable.$converteraccess.fromJson(
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
        $AnonymousRuleTableTable.$converteraccess.toJson(access),
      ),
    };
  }

  AnonymousRuleTableData copyWith({
    int? id,
    String? bucketName,
    String? prefix,
    AnonymousAccessType? access,
  }) => AnonymousRuleTableData(
    id: id ?? this.id,
    bucketName: bucketName ?? this.bucketName,
    prefix: prefix ?? this.prefix,
    access: access ?? this.access,
  );
  AnonymousRuleTableData copyWithCompanion(AnonymousRuleTableCompanion data) {
    return AnonymousRuleTableData(
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
    return (StringBuffer('AnonymousRuleTableData(')
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
      (other is AnonymousRuleTableData &&
          other.id == this.id &&
          other.bucketName == this.bucketName &&
          other.prefix == this.prefix &&
          other.access == this.access);
}

class AnonymousRuleTableCompanion
    extends UpdateCompanion<AnonymousRuleTableData> {
  final Value<int> id;
  final Value<String> bucketName;
  final Value<String> prefix;
  final Value<AnonymousAccessType> access;
  const AnonymousRuleTableCompanion({
    this.id = const Value.absent(),
    this.bucketName = const Value.absent(),
    this.prefix = const Value.absent(),
    this.access = const Value.absent(),
  });
  AnonymousRuleTableCompanion.insert({
    this.id = const Value.absent(),
    required String bucketName,
    required String prefix,
    required AnonymousAccessType access,
  }) : bucketName = Value(bucketName),
       prefix = Value(prefix),
       access = Value(access);
  static Insertable<AnonymousRuleTableData> custom({
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

  AnonymousRuleTableCompanion copyWith({
    Value<int>? id,
    Value<String>? bucketName,
    Value<String>? prefix,
    Value<AnonymousAccessType>? access,
  }) {
    return AnonymousRuleTableCompanion(
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
        $AnonymousRuleTableTable.$converteraccess.toSql(access.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnonymousRuleTableCompanion(')
          ..write('id: $id, ')
          ..write('bucketName: $bucketName, ')
          ..write('prefix: $prefix, ')
          ..write('access: $access')
          ..write(')'))
        .toString();
  }
}

class $BucketTableTable extends BucketTable
    with TableInfo<$BucketTableTable, BucketTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BucketTableTable(this.attachedDatabase, [this._alias]);
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
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const String $name = 'bucket';
  @override
  VerificationContext validateIntegrity(
    Insertable<BucketTableData> instance, {
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
  BucketTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BucketTableData(
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
      ),
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
  $BucketTableTable createAlias(String alias) {
    return $BucketTableTable(attachedDatabase, alias);
  }
}

class BucketTableData extends DataClass implements Insertable<BucketTableData> {
  final String name;
  final String? description;
  final int? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BucketTableData({
    required this.name,
    this.description,
    this.color,
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
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BucketTableCompanion toCompanion(bool nullToAbsent) {
    return BucketTableCompanion(
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BucketTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BucketTableData(
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<int?>(json['color']),
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
      'color': serializer.toJson<int?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BucketTableData copyWith({
    String? name,
    Value<String?> description = const Value.absent(),
    Value<int?> color = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BucketTableData(
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BucketTableData copyWithCompanion(BucketTableCompanion data) {
    return BucketTableData(
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
    return (StringBuffer('BucketTableData(')
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
      (other is BucketTableData &&
          other.name == this.name &&
          other.description == this.description &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BucketTableCompanion extends UpdateCompanion<BucketTableData> {
  final Value<String> name;
  final Value<String?> description;
  final Value<int?> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BucketTableCompanion({
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BucketTableCompanion.insert({
    required String name,
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<BucketTableData> custom({
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

  BucketTableCompanion copyWith({
    Value<String>? name,
    Value<String?>? description,
    Value<int?>? color,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BucketTableCompanion(
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
    return (StringBuffer('BucketTableCompanion(')
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

class $ObjectMetaTableTable extends ObjectMetaTable
    with TableInfo<$ObjectMetaTableTable, ObjectMetaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObjectMetaTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _objectKeyMeta = const VerificationMeta(
    'objectKey',
  );
  @override
  late final GeneratedColumn<String> objectKey = GeneratedColumn<String>(
    'object_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<int> modified = GeneratedColumn<int>(
    'modified',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headersMeta = const VerificationMeta(
    'headers',
  );
  @override
  late final GeneratedColumn<String> headers = GeneratedColumn<String>(
    'headers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    bucketName,
    objectKey,
    etag,
    size,
    modified,
    headers,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'object_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObjectMetaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bucket_name')) {
      context.handle(
        _bucketNameMeta,
        bucketName.isAcceptableOrUnknown(data['bucket_name']!, _bucketNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bucketNameMeta);
    }
    if (data.containsKey('object_key')) {
      context.handle(
        _objectKeyMeta,
        objectKey.isAcceptableOrUnknown(data['object_key']!, _objectKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_objectKeyMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    } else if (isInserting) {
      context.missing(_etagMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedMeta);
    }
    if (data.containsKey('headers')) {
      context.handle(
        _headersMeta,
        headers.isAcceptableOrUnknown(data['headers']!, _headersMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bucketName, objectKey};
  @override
  ObjectMetaTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObjectMetaTableData(
      bucketName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket_name'],
      )!,
      objectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_key'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified'],
      )!,
      headers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers'],
      )!,
    );
  }

  @override
  $ObjectMetaTableTable createAlias(String alias) {
    return $ObjectMetaTableTable(attachedDatabase, alias);
  }
}

class ObjectMetaTableData extends DataClass
    implements Insertable<ObjectMetaTableData> {
  final String bucketName;
  final String objectKey;
  final String etag;
  final int size;

  /// Fecha de modificacion del fichero en microsegundos desde epoch
  final int modified;

  /// Cabeceras del objeto en JSON (`{"content-type": "image/png", …}`)
  final String headers;
  const ObjectMetaTableData({
    required this.bucketName,
    required this.objectKey,
    required this.etag,
    required this.size,
    required this.modified,
    required this.headers,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bucket_name'] = Variable<String>(bucketName);
    map['object_key'] = Variable<String>(objectKey);
    map['etag'] = Variable<String>(etag);
    map['size'] = Variable<int>(size);
    map['modified'] = Variable<int>(modified);
    map['headers'] = Variable<String>(headers);
    return map;
  }

  ObjectMetaTableCompanion toCompanion(bool nullToAbsent) {
    return ObjectMetaTableCompanion(
      bucketName: Value(bucketName),
      objectKey: Value(objectKey),
      etag: Value(etag),
      size: Value(size),
      modified: Value(modified),
      headers: Value(headers),
    );
  }

  factory ObjectMetaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObjectMetaTableData(
      bucketName: serializer.fromJson<String>(json['bucketName']),
      objectKey: serializer.fromJson<String>(json['objectKey']),
      etag: serializer.fromJson<String>(json['etag']),
      size: serializer.fromJson<int>(json['size']),
      modified: serializer.fromJson<int>(json['modified']),
      headers: serializer.fromJson<String>(json['headers']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bucketName': serializer.toJson<String>(bucketName),
      'objectKey': serializer.toJson<String>(objectKey),
      'etag': serializer.toJson<String>(etag),
      'size': serializer.toJson<int>(size),
      'modified': serializer.toJson<int>(modified),
      'headers': serializer.toJson<String>(headers),
    };
  }

  ObjectMetaTableData copyWith({
    String? bucketName,
    String? objectKey,
    String? etag,
    int? size,
    int? modified,
    String? headers,
  }) => ObjectMetaTableData(
    bucketName: bucketName ?? this.bucketName,
    objectKey: objectKey ?? this.objectKey,
    etag: etag ?? this.etag,
    size: size ?? this.size,
    modified: modified ?? this.modified,
    headers: headers ?? this.headers,
  );
  ObjectMetaTableData copyWithCompanion(ObjectMetaTableCompanion data) {
    return ObjectMetaTableData(
      bucketName: data.bucketName.present
          ? data.bucketName.value
          : this.bucketName,
      objectKey: data.objectKey.present ? data.objectKey.value : this.objectKey,
      etag: data.etag.present ? data.etag.value : this.etag,
      size: data.size.present ? data.size.value : this.size,
      modified: data.modified.present ? data.modified.value : this.modified,
      headers: data.headers.present ? data.headers.value : this.headers,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObjectMetaTableData(')
          ..write('bucketName: $bucketName, ')
          ..write('objectKey: $objectKey, ')
          ..write('etag: $etag, ')
          ..write('size: $size, ')
          ..write('modified: $modified, ')
          ..write('headers: $headers')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(bucketName, objectKey, etag, size, modified, headers);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObjectMetaTableData &&
          other.bucketName == this.bucketName &&
          other.objectKey == this.objectKey &&
          other.etag == this.etag &&
          other.size == this.size &&
          other.modified == this.modified &&
          other.headers == this.headers);
}

class ObjectMetaTableCompanion extends UpdateCompanion<ObjectMetaTableData> {
  final Value<String> bucketName;
  final Value<String> objectKey;
  final Value<String> etag;
  final Value<int> size;
  final Value<int> modified;
  final Value<String> headers;
  final Value<int> rowid;
  const ObjectMetaTableCompanion({
    this.bucketName = const Value.absent(),
    this.objectKey = const Value.absent(),
    this.etag = const Value.absent(),
    this.size = const Value.absent(),
    this.modified = const Value.absent(),
    this.headers = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ObjectMetaTableCompanion.insert({
    required String bucketName,
    required String objectKey,
    required String etag,
    required int size,
    required int modified,
    this.headers = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bucketName = Value(bucketName),
       objectKey = Value(objectKey),
       etag = Value(etag),
       size = Value(size),
       modified = Value(modified);
  static Insertable<ObjectMetaTableData> custom({
    Expression<String>? bucketName,
    Expression<String>? objectKey,
    Expression<String>? etag,
    Expression<int>? size,
    Expression<int>? modified,
    Expression<String>? headers,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bucketName != null) 'bucket_name': bucketName,
      if (objectKey != null) 'object_key': objectKey,
      if (etag != null) 'etag': etag,
      if (size != null) 'size': size,
      if (modified != null) 'modified': modified,
      if (headers != null) 'headers': headers,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ObjectMetaTableCompanion copyWith({
    Value<String>? bucketName,
    Value<String>? objectKey,
    Value<String>? etag,
    Value<int>? size,
    Value<int>? modified,
    Value<String>? headers,
    Value<int>? rowid,
  }) {
    return ObjectMetaTableCompanion(
      bucketName: bucketName ?? this.bucketName,
      objectKey: objectKey ?? this.objectKey,
      etag: etag ?? this.etag,
      size: size ?? this.size,
      modified: modified ?? this.modified,
      headers: headers ?? this.headers,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bucketName.present) {
      map['bucket_name'] = Variable<String>(bucketName.value);
    }
    if (objectKey.present) {
      map['object_key'] = Variable<String>(objectKey.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (modified.present) {
      map['modified'] = Variable<int>(modified.value);
    }
    if (headers.present) {
      map['headers'] = Variable<String>(headers.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObjectMetaTableCompanion(')
          ..write('bucketName: $bucketName, ')
          ..write('objectKey: $objectKey, ')
          ..write('etag: $etag, ')
          ..write('size: $size, ')
          ..write('modified: $modified, ')
          ..write('headers: $headers, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnonymousRuleTableTable anonymousRuleTable =
      $AnonymousRuleTableTable(this);
  late final $BucketTableTable bucketTable = $BucketTableTable(this);
  late final $ObjectMetaTableTable objectMetaTable = $ObjectMetaTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    anonymousRuleTable,
    bucketTable,
    objectMetaTable,
  ];
}

typedef $$AnonymousRuleTableTableCreateCompanionBuilder =
    AnonymousRuleTableCompanion Function({
      Value<int> id,
      required String bucketName,
      required String prefix,
      required AnonymousAccessType access,
    });
typedef $$AnonymousRuleTableTableUpdateCompanionBuilder =
    AnonymousRuleTableCompanion Function({
      Value<int> id,
      Value<String> bucketName,
      Value<String> prefix,
      Value<AnonymousAccessType> access,
    });

class $$AnonymousRuleTableTableFilterComposer
    extends Composer<_$AppDatabase, $AnonymousRuleTableTable> {
  $$AnonymousRuleTableTableFilterComposer({
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

class $$AnonymousRuleTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AnonymousRuleTableTable> {
  $$AnonymousRuleTableTableOrderingComposer({
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

class $$AnonymousRuleTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnonymousRuleTableTable> {
  $$AnonymousRuleTableTableAnnotationComposer({
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

class $$AnonymousRuleTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnonymousRuleTableTable,
          AnonymousRuleTableData,
          $$AnonymousRuleTableTableFilterComposer,
          $$AnonymousRuleTableTableOrderingComposer,
          $$AnonymousRuleTableTableAnnotationComposer,
          $$AnonymousRuleTableTableCreateCompanionBuilder,
          $$AnonymousRuleTableTableUpdateCompanionBuilder,
          (
            AnonymousRuleTableData,
            BaseReferences<
              _$AppDatabase,
              $AnonymousRuleTableTable,
              AnonymousRuleTableData
            >,
          ),
          AnonymousRuleTableData,
          PrefetchHooks Function()
        > {
  $$AnonymousRuleTableTableTableManager(
    _$AppDatabase db,
    $AnonymousRuleTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnonymousRuleTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnonymousRuleTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnonymousRuleTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bucketName = const Value.absent(),
                Value<String> prefix = const Value.absent(),
                Value<AnonymousAccessType> access = const Value.absent(),
              }) => AnonymousRuleTableCompanion(
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
              }) => AnonymousRuleTableCompanion.insert(
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

typedef $$AnonymousRuleTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnonymousRuleTableTable,
      AnonymousRuleTableData,
      $$AnonymousRuleTableTableFilterComposer,
      $$AnonymousRuleTableTableOrderingComposer,
      $$AnonymousRuleTableTableAnnotationComposer,
      $$AnonymousRuleTableTableCreateCompanionBuilder,
      $$AnonymousRuleTableTableUpdateCompanionBuilder,
      (
        AnonymousRuleTableData,
        BaseReferences<
          _$AppDatabase,
          $AnonymousRuleTableTable,
          AnonymousRuleTableData
        >,
      ),
      AnonymousRuleTableData,
      PrefetchHooks Function()
    >;
typedef $$BucketTableTableCreateCompanionBuilder =
    BucketTableCompanion Function({
      required String name,
      Value<String?> description,
      Value<int?> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BucketTableTableUpdateCompanionBuilder =
    BucketTableCompanion Function({
      Value<String> name,
      Value<String?> description,
      Value<int?> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BucketTableTableFilterComposer
    extends Composer<_$AppDatabase, $BucketTableTable> {
  $$BucketTableTableFilterComposer({
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

class $$BucketTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BucketTableTable> {
  $$BucketTableTableOrderingComposer({
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

class $$BucketTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BucketTableTable> {
  $$BucketTableTableAnnotationComposer({
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

class $$BucketTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BucketTableTable,
          BucketTableData,
          $$BucketTableTableFilterComposer,
          $$BucketTableTableOrderingComposer,
          $$BucketTableTableAnnotationComposer,
          $$BucketTableTableCreateCompanionBuilder,
          $$BucketTableTableUpdateCompanionBuilder,
          (
            BucketTableData,
            BaseReferences<_$AppDatabase, $BucketTableTable, BucketTableData>,
          ),
          BucketTableData,
          PrefetchHooks Function()
        > {
  $$BucketTableTableTableManager(_$AppDatabase db, $BucketTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BucketTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BucketTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BucketTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BucketTableCompanion(
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
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BucketTableCompanion.insert(
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

typedef $$BucketTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BucketTableTable,
      BucketTableData,
      $$BucketTableTableFilterComposer,
      $$BucketTableTableOrderingComposer,
      $$BucketTableTableAnnotationComposer,
      $$BucketTableTableCreateCompanionBuilder,
      $$BucketTableTableUpdateCompanionBuilder,
      (
        BucketTableData,
        BaseReferences<_$AppDatabase, $BucketTableTable, BucketTableData>,
      ),
      BucketTableData,
      PrefetchHooks Function()
    >;
typedef $$ObjectMetaTableTableCreateCompanionBuilder =
    ObjectMetaTableCompanion Function({
      required String bucketName,
      required String objectKey,
      required String etag,
      required int size,
      required int modified,
      Value<String> headers,
      Value<int> rowid,
    });
typedef $$ObjectMetaTableTableUpdateCompanionBuilder =
    ObjectMetaTableCompanion Function({
      Value<String> bucketName,
      Value<String> objectKey,
      Value<String> etag,
      Value<int> size,
      Value<int> modified,
      Value<String> headers,
      Value<int> rowid,
    });

class $$ObjectMetaTableTableFilterComposer
    extends Composer<_$AppDatabase, $ObjectMetaTableTable> {
  $$ObjectMetaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objectKey => $composableBuilder(
    column: $table.objectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ObjectMetaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ObjectMetaTableTable> {
  $$ObjectMetaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objectKey => $composableBuilder(
    column: $table.objectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ObjectMetaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ObjectMetaTableTable> {
  $$ObjectMetaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get objectKey =>
      $composableBuilder(column: $table.objectKey, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get headers =>
      $composableBuilder(column: $table.headers, builder: (column) => column);
}

class $$ObjectMetaTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ObjectMetaTableTable,
          ObjectMetaTableData,
          $$ObjectMetaTableTableFilterComposer,
          $$ObjectMetaTableTableOrderingComposer,
          $$ObjectMetaTableTableAnnotationComposer,
          $$ObjectMetaTableTableCreateCompanionBuilder,
          $$ObjectMetaTableTableUpdateCompanionBuilder,
          (
            ObjectMetaTableData,
            BaseReferences<
              _$AppDatabase,
              $ObjectMetaTableTable,
              ObjectMetaTableData
            >,
          ),
          ObjectMetaTableData,
          PrefetchHooks Function()
        > {
  $$ObjectMetaTableTableTableManager(
    _$AppDatabase db,
    $ObjectMetaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObjectMetaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObjectMetaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObjectMetaTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bucketName = const Value.absent(),
                Value<String> objectKey = const Value.absent(),
                Value<String> etag = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<int> modified = const Value.absent(),
                Value<String> headers = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObjectMetaTableCompanion(
                bucketName: bucketName,
                objectKey: objectKey,
                etag: etag,
                size: size,
                modified: modified,
                headers: headers,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bucketName,
                required String objectKey,
                required String etag,
                required int size,
                required int modified,
                Value<String> headers = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ObjectMetaTableCompanion.insert(
                bucketName: bucketName,
                objectKey: objectKey,
                etag: etag,
                size: size,
                modified: modified,
                headers: headers,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ObjectMetaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ObjectMetaTableTable,
      ObjectMetaTableData,
      $$ObjectMetaTableTableFilterComposer,
      $$ObjectMetaTableTableOrderingComposer,
      $$ObjectMetaTableTableAnnotationComposer,
      $$ObjectMetaTableTableCreateCompanionBuilder,
      $$ObjectMetaTableTableUpdateCompanionBuilder,
      (
        ObjectMetaTableData,
        BaseReferences<
          _$AppDatabase,
          $ObjectMetaTableTable,
          ObjectMetaTableData
        >,
      ),
      ObjectMetaTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnonymousRuleTableTableTableManager get anonymousRuleTable =>
      $$AnonymousRuleTableTableTableManager(_db, _db.anonymousRuleTable);
  $$BucketTableTableTableManager get bucketTable =>
      $$BucketTableTableTableManager(_db, _db.bucketTable);
  $$ObjectMetaTableTableTableManager get objectMetaTable =>
      $$ObjectMetaTableTableTableManager(_db, _db.objectMetaTable);
}
