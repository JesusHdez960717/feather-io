// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccessKeyTableTable extends AccessKeyTable
    with TableInfo<$AccessKeyTableTable, AccessKeyTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccessKeyTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secretEncryptedMeta = const VerificationMeta(
    'secretEncrypted',
  );
  @override
  late final GeneratedColumn<String> secretEncrypted = GeneratedColumn<String>(
    'secret_encrypted',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccessKeyLevel?, String>
  allBuckets = GeneratedColumn<String>(
    'all_buckets',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<AccessKeyLevel?>($AccessKeyTableTable.$converterallBucketsn);
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    secretEncrypted,
    enabled,
    allBuckets,
    expiresAt,
    createdAt,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'access_key';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccessKeyTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('secret_encrypted')) {
      context.handle(
        _secretEncryptedMeta,
        secretEncrypted.isAcceptableOrUnknown(
          data['secret_encrypted']!,
          _secretEncryptedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_secretEncryptedMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccessKeyTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccessKeyTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      secretEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_encrypted'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      allBuckets: $AccessKeyTableTable.$converterallBucketsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}all_buckets'],
        ),
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
    );
  }

  @override
  $AccessKeyTableTable createAlias(String alias) {
    return $AccessKeyTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccessKeyLevel, String, String>
  $converterallBuckets = const EnumNameConverter<AccessKeyLevel>(
    AccessKeyLevel.values,
  );
  static JsonTypeConverter2<AccessKeyLevel?, String?, String?>
  $converterallBucketsn = JsonTypeConverter2.asNullable($converterallBuckets);
}

class AccessKeyTableData extends DataClass
    implements Insertable<AccessKeyTableData> {
  /// Access key id (`FIOK…`), the one clients send in the signature.
  final String id;
  final String name;
  final String secretEncrypted;
  final bool enabled;

  /// Level on every bucket; null when the key only reaches the buckets of
  /// [AccessKeyGrantTable].
  final AccessKeyLevel? allBuckets;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  const AccessKeyTableData({
    required this.id,
    required this.name,
    required this.secretEncrypted,
    required this.enabled,
    this.allBuckets,
    this.expiresAt,
    required this.createdAt,
    this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['secret_encrypted'] = Variable<String>(secretEncrypted);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || allBuckets != null) {
      map['all_buckets'] = Variable<String>(
        $AccessKeyTableTable.$converterallBucketsn.toSql(allBuckets),
      );
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    return map;
  }

  AccessKeyTableCompanion toCompanion(bool nullToAbsent) {
    return AccessKeyTableCompanion(
      id: Value(id),
      name: Value(name),
      secretEncrypted: Value(secretEncrypted),
      enabled: Value(enabled),
      allBuckets: allBuckets == null && nullToAbsent
          ? const Value.absent()
          : Value(allBuckets),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: Value(createdAt),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
    );
  }

  factory AccessKeyTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccessKeyTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      secretEncrypted: serializer.fromJson<String>(json['secretEncrypted']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      allBuckets: $AccessKeyTableTable.$converterallBucketsn.fromJson(
        serializer.fromJson<String?>(json['allBuckets']),
      ),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'secretEncrypted': serializer.toJson<String>(secretEncrypted),
      'enabled': serializer.toJson<bool>(enabled),
      'allBuckets': serializer.toJson<String?>(
        $AccessKeyTableTable.$converterallBucketsn.toJson(allBuckets),
      ),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
    };
  }

  AccessKeyTableData copyWith({
    String? id,
    String? name,
    String? secretEncrypted,
    bool? enabled,
    Value<AccessKeyLevel?> allBuckets = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastUsedAt = const Value.absent(),
  }) => AccessKeyTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    secretEncrypted: secretEncrypted ?? this.secretEncrypted,
    enabled: enabled ?? this.enabled,
    allBuckets: allBuckets.present ? allBuckets.value : this.allBuckets,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
  );
  AccessKeyTableData copyWithCompanion(AccessKeyTableCompanion data) {
    return AccessKeyTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      secretEncrypted: data.secretEncrypted.present
          ? data.secretEncrypted.value
          : this.secretEncrypted,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      allBuckets: data.allBuckets.present
          ? data.allBuckets.value
          : this.allBuckets,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccessKeyTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('secretEncrypted: $secretEncrypted, ')
          ..write('enabled: $enabled, ')
          ..write('allBuckets: $allBuckets, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    secretEncrypted,
    enabled,
    allBuckets,
    expiresAt,
    createdAt,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccessKeyTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.secretEncrypted == this.secretEncrypted &&
          other.enabled == this.enabled &&
          other.allBuckets == this.allBuckets &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class AccessKeyTableCompanion extends UpdateCompanion<AccessKeyTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> secretEncrypted;
  final Value<bool> enabled;
  final Value<AccessKeyLevel?> allBuckets;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastUsedAt;
  final Value<int> rowid;
  const AccessKeyTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.secretEncrypted = const Value.absent(),
    this.enabled = const Value.absent(),
    this.allBuckets = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccessKeyTableCompanion.insert({
    required String id,
    required String name,
    required String secretEncrypted,
    this.enabled = const Value.absent(),
    this.allBuckets = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       secretEncrypted = Value(secretEncrypted);
  static Insertable<AccessKeyTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? secretEncrypted,
    Expression<bool>? enabled,
    Expression<String>? allBuckets,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (secretEncrypted != null) 'secret_encrypted': secretEncrypted,
      if (enabled != null) 'enabled': enabled,
      if (allBuckets != null) 'all_buckets': allBuckets,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccessKeyTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? secretEncrypted,
    Value<bool>? enabled,
    Value<AccessKeyLevel?>? allBuckets,
    Value<DateTime?>? expiresAt,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return AccessKeyTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      secretEncrypted: secretEncrypted ?? this.secretEncrypted,
      enabled: enabled ?? this.enabled,
      allBuckets: allBuckets ?? this.allBuckets,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (secretEncrypted.present) {
      map['secret_encrypted'] = Variable<String>(secretEncrypted.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (allBuckets.present) {
      map['all_buckets'] = Variable<String>(
        $AccessKeyTableTable.$converterallBucketsn.toSql(allBuckets.value),
      );
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccessKeyTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('secretEncrypted: $secretEncrypted, ')
          ..write('enabled: $enabled, ')
          ..write('allBuckets: $allBuckets, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
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

class $AccessKeyGrantTableTable extends AccessKeyGrantTable
    with TableInfo<$AccessKeyGrantTableTable, AccessKeyGrantTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccessKeyGrantTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<String> keyId = GeneratedColumn<String>(
    'key_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES access_key (id)',
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bucket (name)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccessKeyLevel, String> access =
      GeneratedColumn<String>(
        'access',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccessKeyLevel>(
        $AccessKeyGrantTableTable.$converteraccess,
      );
  @override
  List<GeneratedColumn> get $columns => [keyId, bucketName, access];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'access_key_grant';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccessKeyGrantTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key_id')) {
      context.handle(
        _keyIdMeta,
        keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_keyIdMeta);
    }
    if (data.containsKey('bucket_name')) {
      context.handle(
        _bucketNameMeta,
        bucketName.isAcceptableOrUnknown(data['bucket_name']!, _bucketNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bucketNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyId, bucketName};
  @override
  AccessKeyGrantTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccessKeyGrantTableData(
      keyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_id'],
      )!,
      bucketName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket_name'],
      )!,
      access: $AccessKeyGrantTableTable.$converteraccess.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}access'],
        )!,
      ),
    );
  }

  @override
  $AccessKeyGrantTableTable createAlias(String alias) {
    return $AccessKeyGrantTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccessKeyLevel, String, String> $converteraccess =
      const EnumNameConverter<AccessKeyLevel>(AccessKeyLevel.values);
}

class AccessKeyGrantTableData extends DataClass
    implements Insertable<AccessKeyGrantTableData> {
  final String keyId;
  final String bucketName;
  final AccessKeyLevel access;
  const AccessKeyGrantTableData({
    required this.keyId,
    required this.bucketName,
    required this.access,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key_id'] = Variable<String>(keyId);
    map['bucket_name'] = Variable<String>(bucketName);
    {
      map['access'] = Variable<String>(
        $AccessKeyGrantTableTable.$converteraccess.toSql(access),
      );
    }
    return map;
  }

  AccessKeyGrantTableCompanion toCompanion(bool nullToAbsent) {
    return AccessKeyGrantTableCompanion(
      keyId: Value(keyId),
      bucketName: Value(bucketName),
      access: Value(access),
    );
  }

  factory AccessKeyGrantTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccessKeyGrantTableData(
      keyId: serializer.fromJson<String>(json['keyId']),
      bucketName: serializer.fromJson<String>(json['bucketName']),
      access: $AccessKeyGrantTableTable.$converteraccess.fromJson(
        serializer.fromJson<String>(json['access']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'keyId': serializer.toJson<String>(keyId),
      'bucketName': serializer.toJson<String>(bucketName),
      'access': serializer.toJson<String>(
        $AccessKeyGrantTableTable.$converteraccess.toJson(access),
      ),
    };
  }

  AccessKeyGrantTableData copyWith({
    String? keyId,
    String? bucketName,
    AccessKeyLevel? access,
  }) => AccessKeyGrantTableData(
    keyId: keyId ?? this.keyId,
    bucketName: bucketName ?? this.bucketName,
    access: access ?? this.access,
  );
  AccessKeyGrantTableData copyWithCompanion(AccessKeyGrantTableCompanion data) {
    return AccessKeyGrantTableData(
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      bucketName: data.bucketName.present
          ? data.bucketName.value
          : this.bucketName,
      access: data.access.present ? data.access.value : this.access,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccessKeyGrantTableData(')
          ..write('keyId: $keyId, ')
          ..write('bucketName: $bucketName, ')
          ..write('access: $access')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(keyId, bucketName, access);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccessKeyGrantTableData &&
          other.keyId == this.keyId &&
          other.bucketName == this.bucketName &&
          other.access == this.access);
}

class AccessKeyGrantTableCompanion
    extends UpdateCompanion<AccessKeyGrantTableData> {
  final Value<String> keyId;
  final Value<String> bucketName;
  final Value<AccessKeyLevel> access;
  final Value<int> rowid;
  const AccessKeyGrantTableCompanion({
    this.keyId = const Value.absent(),
    this.bucketName = const Value.absent(),
    this.access = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccessKeyGrantTableCompanion.insert({
    required String keyId,
    required String bucketName,
    required AccessKeyLevel access,
    this.rowid = const Value.absent(),
  }) : keyId = Value(keyId),
       bucketName = Value(bucketName),
       access = Value(access);
  static Insertable<AccessKeyGrantTableData> custom({
    Expression<String>? keyId,
    Expression<String>? bucketName,
    Expression<String>? access,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (keyId != null) 'key_id': keyId,
      if (bucketName != null) 'bucket_name': bucketName,
      if (access != null) 'access': access,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccessKeyGrantTableCompanion copyWith({
    Value<String>? keyId,
    Value<String>? bucketName,
    Value<AccessKeyLevel>? access,
    Value<int>? rowid,
  }) {
    return AccessKeyGrantTableCompanion(
      keyId: keyId ?? this.keyId,
      bucketName: bucketName ?? this.bucketName,
      access: access ?? this.access,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (keyId.present) {
      map['key_id'] = Variable<String>(keyId.value);
    }
    if (bucketName.present) {
      map['bucket_name'] = Variable<String>(bucketName.value);
    }
    if (access.present) {
      map['access'] = Variable<String>(
        $AccessKeyGrantTableTable.$converteraccess.toSql(access.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccessKeyGrantTableCompanion(')
          ..write('keyId: $keyId, ')
          ..write('bucketName: $bucketName, ')
          ..write('access: $access, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bucket (name)',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bucket (name)',
    ),
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

  /// File modification time, in microseconds since the epoch.
  final int modified;

  /// Object headers as JSON (`{"content-type": "image/png", …}`).
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
  late final $AccessKeyTableTable accessKeyTable = $AccessKeyTableTable(this);
  late final $BucketTableTable bucketTable = $BucketTableTable(this);
  late final $AccessKeyGrantTableTable accessKeyGrantTable =
      $AccessKeyGrantTableTable(this);
  late final $AnonymousRuleTableTable anonymousRuleTable =
      $AnonymousRuleTableTable(this);
  late final $ObjectMetaTableTable objectMetaTable = $ObjectMetaTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accessKeyTable,
    bucketTable,
    accessKeyGrantTable,
    anonymousRuleTable,
    objectMetaTable,
  ];
}

typedef $$AccessKeyTableTableCreateCompanionBuilder =
    AccessKeyTableCompanion Function({
      required String id,
      required String name,
      required String secretEncrypted,
      Value<bool> enabled,
      Value<AccessKeyLevel?> allBuckets,
      Value<DateTime?> expiresAt,
      Value<DateTime> createdAt,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });
typedef $$AccessKeyTableTableUpdateCompanionBuilder =
    AccessKeyTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> secretEncrypted,
      Value<bool> enabled,
      Value<AccessKeyLevel?> allBuckets,
      Value<DateTime?> expiresAt,
      Value<DateTime> createdAt,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });

final class $$AccessKeyTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AccessKeyTableTable,
          AccessKeyTableData
        > {
  $$AccessKeyTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $AccessKeyGrantTableTable,
    List<AccessKeyGrantTableData>
  >
  _accessKeyGrantTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accessKeyGrantTable,
        aliasName: 'access_key__id__access_key_grant__key_id',
      );

  $$AccessKeyGrantTableTableProcessedTableManager get accessKeyGrantTableRefs {
    final manager = $$AccessKeyGrantTableTableTableManager(
      $_db,
      $_db.accessKeyGrantTable,
    ).filter((f) => f.keyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accessKeyGrantTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccessKeyTableTableFilterComposer
    extends Composer<_$AppDatabase, $AccessKeyTableTable> {
  $$AccessKeyTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretEncrypted => $composableBuilder(
    column: $table.secretEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccessKeyLevel?, AccessKeyLevel, String>
  get allBuckets => $composableBuilder(
    column: $table.allBuckets,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accessKeyGrantTableRefs(
    Expression<bool> Function($$AccessKeyGrantTableTableFilterComposer f) f,
  ) {
    final $$AccessKeyGrantTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accessKeyGrantTable,
      getReferencedColumn: (t) => t.keyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccessKeyGrantTableTableFilterComposer(
            $db: $db,
            $table: $db.accessKeyGrantTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccessKeyTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AccessKeyTableTable> {
  $$AccessKeyTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretEncrypted => $composableBuilder(
    column: $table.secretEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allBuckets => $composableBuilder(
    column: $table.allBuckets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccessKeyTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccessKeyTableTable> {
  $$AccessKeyTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get secretEncrypted => $composableBuilder(
    column: $table.secretEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccessKeyLevel?, String> get allBuckets =>
      $composableBuilder(
        column: $table.allBuckets,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  Expression<T> accessKeyGrantTableRefs<T extends Object>(
    Expression<T> Function($$AccessKeyGrantTableTableAnnotationComposer a) f,
  ) {
    final $$AccessKeyGrantTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.accessKeyGrantTable,
          getReferencedColumn: (t) => t.keyId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccessKeyGrantTableTableAnnotationComposer(
                $db: $db,
                $table: $db.accessKeyGrantTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AccessKeyTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccessKeyTableTable,
          AccessKeyTableData,
          $$AccessKeyTableTableFilterComposer,
          $$AccessKeyTableTableOrderingComposer,
          $$AccessKeyTableTableAnnotationComposer,
          $$AccessKeyTableTableCreateCompanionBuilder,
          $$AccessKeyTableTableUpdateCompanionBuilder,
          (AccessKeyTableData, $$AccessKeyTableTableReferences),
          AccessKeyTableData,
          PrefetchHooks Function({bool accessKeyGrantTableRefs})
        > {
  $$AccessKeyTableTableTableManager(
    _$AppDatabase db,
    $AccessKeyTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccessKeyTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccessKeyTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccessKeyTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> secretEncrypted = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<AccessKeyLevel?> allBuckets = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccessKeyTableCompanion(
                id: id,
                name: name,
                secretEncrypted: secretEncrypted,
                enabled: enabled,
                allBuckets: allBuckets,
                expiresAt: expiresAt,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String secretEncrypted,
                Value<bool> enabled = const Value.absent(),
                Value<AccessKeyLevel?> allBuckets = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccessKeyTableCompanion.insert(
                id: id,
                name: name,
                secretEncrypted: secretEncrypted,
                enabled: enabled,
                allBuckets: allBuckets,
                expiresAt: expiresAt,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccessKeyTableTable, AccessKeyTableData>(table),
                  $$AccessKeyTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accessKeyGrantTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (accessKeyGrantTableRefs) db.accessKeyGrantTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accessKeyGrantTableRefs)
                    await $_getPrefetchedData<
                      AccessKeyTableData,
                      $AccessKeyTableTable,
                      AccessKeyGrantTableData
                    >(
                      currentTable: table,
                      referencedTable: $$AccessKeyTableTableReferences
                          ._accessKeyGrantTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AccessKeyTableTableReferences(
                            db,
                            table,
                            p0,
                          ).accessKeyGrantTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.keyId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccessKeyTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccessKeyTableTable,
      AccessKeyTableData,
      $$AccessKeyTableTableFilterComposer,
      $$AccessKeyTableTableOrderingComposer,
      $$AccessKeyTableTableAnnotationComposer,
      $$AccessKeyTableTableCreateCompanionBuilder,
      $$AccessKeyTableTableUpdateCompanionBuilder,
      (AccessKeyTableData, $$AccessKeyTableTableReferences),
      AccessKeyTableData,
      PrefetchHooks Function({bool accessKeyGrantTableRefs})
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

final class $$BucketTableTableReferences
    extends BaseReferences<_$AppDatabase, $BucketTableTable, BucketTableData> {
  $$BucketTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $AccessKeyGrantTableTable,
    List<AccessKeyGrantTableData>
  >
  _accessKeyGrantTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.accessKeyGrantTable,
        aliasName: 'bucket__name__access_key_grant__bucket_name',
      );

  $$AccessKeyGrantTableTableProcessedTableManager get accessKeyGrantTableRefs {
    final manager = $$AccessKeyGrantTableTableTableManager(
      $_db,
      $_db.accessKeyGrantTable,
    ).filter((f) => f.bucketName.name.sqlEquals($_itemColumn<String>('name')!));

    final cache = $_typedResult.readTableOrNull(
      _accessKeyGrantTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AnonymousRuleTableTable,
    List<AnonymousRuleTableData>
  >
  _anonymousRuleTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.anonymousRuleTable,
        aliasName: 'bucket__name__anonymous_rule__bucket_name',
      );

  $$AnonymousRuleTableTableProcessedTableManager get anonymousRuleTableRefs {
    final manager = $$AnonymousRuleTableTableTableManager(
      $_db,
      $_db.anonymousRuleTable,
    ).filter((f) => f.bucketName.name.sqlEquals($_itemColumn<String>('name')!));

    final cache = $_typedResult.readTableOrNull(
      _anonymousRuleTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ObjectMetaTableTable, List<ObjectMetaTableData>>
  _objectMetaTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.objectMetaTable,
    aliasName: 'bucket__name__object_meta__bucket_name',
  );

  $$ObjectMetaTableTableProcessedTableManager get objectMetaTableRefs {
    final manager = $$ObjectMetaTableTableTableManager(
      $_db,
      $_db.objectMetaTable,
    ).filter((f) => f.bucketName.name.sqlEquals($_itemColumn<String>('name')!));

    final cache = $_typedResult.readTableOrNull(
      _objectMetaTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  Expression<bool> accessKeyGrantTableRefs(
    Expression<bool> Function($$AccessKeyGrantTableTableFilterComposer f) f,
  ) {
    final $$AccessKeyGrantTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.name,
      referencedTable: $db.accessKeyGrantTable,
      getReferencedColumn: (t) => t.bucketName,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccessKeyGrantTableTableFilterComposer(
            $db: $db,
            $table: $db.accessKeyGrantTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> anonymousRuleTableRefs(
    Expression<bool> Function($$AnonymousRuleTableTableFilterComposer f) f,
  ) {
    final $$AnonymousRuleTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.name,
      referencedTable: $db.anonymousRuleTable,
      getReferencedColumn: (t) => t.bucketName,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnonymousRuleTableTableFilterComposer(
            $db: $db,
            $table: $db.anonymousRuleTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> objectMetaTableRefs(
    Expression<bool> Function($$ObjectMetaTableTableFilterComposer f) f,
  ) {
    final $$ObjectMetaTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.name,
      referencedTable: $db.objectMetaTable,
      getReferencedColumn: (t) => t.bucketName,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObjectMetaTableTableFilterComposer(
            $db: $db,
            $table: $db.objectMetaTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  Expression<T> accessKeyGrantTableRefs<T extends Object>(
    Expression<T> Function($$AccessKeyGrantTableTableAnnotationComposer a) f,
  ) {
    final $$AccessKeyGrantTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.name,
          referencedTable: $db.accessKeyGrantTable,
          getReferencedColumn: (t) => t.bucketName,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AccessKeyGrantTableTableAnnotationComposer(
                $db: $db,
                $table: $db.accessKeyGrantTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> anonymousRuleTableRefs<T extends Object>(
    Expression<T> Function($$AnonymousRuleTableTableAnnotationComposer a) f,
  ) {
    final $$AnonymousRuleTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.name,
          referencedTable: $db.anonymousRuleTable,
          getReferencedColumn: (t) => t.bucketName,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnonymousRuleTableTableAnnotationComposer(
                $db: $db,
                $table: $db.anonymousRuleTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> objectMetaTableRefs<T extends Object>(
    Expression<T> Function($$ObjectMetaTableTableAnnotationComposer a) f,
  ) {
    final $$ObjectMetaTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.name,
      referencedTable: $db.objectMetaTable,
      getReferencedColumn: (t) => t.bucketName,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObjectMetaTableTableAnnotationComposer(
            $db: $db,
            $table: $db.objectMetaTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (BucketTableData, $$BucketTableTableReferences),
          BucketTableData,
          PrefetchHooks Function({
            bool accessKeyGrantTableRefs,
            bool anonymousRuleTableRefs,
            bool objectMetaTableRefs,
          })
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
              .map(
                (e) => (
                  e.readTable<$BucketTableTable, BucketTableData>(table),
                  $$BucketTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accessKeyGrantTableRefs = false,
                anonymousRuleTableRefs = false,
                objectMetaTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (accessKeyGrantTableRefs) db.accessKeyGrantTable,
                    if (anonymousRuleTableRefs) db.anonymousRuleTable,
                    if (objectMetaTableRefs) db.objectMetaTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accessKeyGrantTableRefs)
                        await $_getPrefetchedData<
                          BucketTableData,
                          $BucketTableTable,
                          AccessKeyGrantTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BucketTableTableReferences
                              ._accessKeyGrantTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BucketTableTableReferences(
                                db,
                                table,
                                p0,
                              ).accessKeyGrantTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bucketName == item.name,
                              ),
                          typedResults: items,
                        ),
                      if (anonymousRuleTableRefs)
                        await $_getPrefetchedData<
                          BucketTableData,
                          $BucketTableTable,
                          AnonymousRuleTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BucketTableTableReferences
                              ._anonymousRuleTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BucketTableTableReferences(
                                db,
                                table,
                                p0,
                              ).anonymousRuleTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bucketName == item.name,
                              ),
                          typedResults: items,
                        ),
                      if (objectMetaTableRefs)
                        await $_getPrefetchedData<
                          BucketTableData,
                          $BucketTableTable,
                          ObjectMetaTableData
                        >(
                          currentTable: table,
                          referencedTable: $$BucketTableTableReferences
                              ._objectMetaTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BucketTableTableReferences(
                                db,
                                table,
                                p0,
                              ).objectMetaTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bucketName == item.name,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (BucketTableData, $$BucketTableTableReferences),
      BucketTableData,
      PrefetchHooks Function({
        bool accessKeyGrantTableRefs,
        bool anonymousRuleTableRefs,
        bool objectMetaTableRefs,
      })
    >;
typedef $$AccessKeyGrantTableTableCreateCompanionBuilder =
    AccessKeyGrantTableCompanion Function({
      required String keyId,
      required String bucketName,
      required AccessKeyLevel access,
      Value<int> rowid,
    });
typedef $$AccessKeyGrantTableTableUpdateCompanionBuilder =
    AccessKeyGrantTableCompanion Function({
      Value<String> keyId,
      Value<String> bucketName,
      Value<AccessKeyLevel> access,
      Value<int> rowid,
    });

final class $$AccessKeyGrantTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AccessKeyGrantTableTable,
          AccessKeyGrantTableData
        > {
  $$AccessKeyGrantTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccessKeyTableTable _keyIdTable(_$AppDatabase db) =>
      db.accessKeyTable.createAlias('access_key_grant__key_id__access_key__id');

  $$AccessKeyTableTableProcessedTableManager get keyId {
    final $_column = $_itemColumn<String>('key_id')!;

    final manager = $$AccessKeyTableTableTableManager(
      $_db,
      $_db.accessKeyTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BucketTableTable _bucketNameTable(_$AppDatabase db) =>
      db.bucketTable.createAlias('access_key_grant__bucket_name__bucket__name');

  $$BucketTableTableProcessedTableManager get bucketName {
    final $_column = $_itemColumn<String>('bucket_name')!;

    final manager = $$BucketTableTableTableManager(
      $_db,
      $_db.bucketTable,
    ).filter((f) => f.name.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bucketNameTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AccessKeyGrantTableTableFilterComposer
    extends Composer<_$AppDatabase, $AccessKeyGrantTableTable> {
  $$AccessKeyGrantTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<AccessKeyLevel, AccessKeyLevel, String>
  get access => $composableBuilder(
    column: $table.access,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$AccessKeyTableTableFilterComposer get keyId {
    final $$AccessKeyTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyId,
      referencedTable: $db.accessKeyTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccessKeyTableTableFilterComposer(
            $db: $db,
            $table: $db.accessKeyTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BucketTableTableFilterComposer get bucketName {
    final $$BucketTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableFilterComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccessKeyGrantTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AccessKeyGrantTableTable> {
  $$AccessKeyGrantTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get access => $composableBuilder(
    column: $table.access,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccessKeyTableTableOrderingComposer get keyId {
    final $$AccessKeyTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyId,
      referencedTable: $db.accessKeyTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccessKeyTableTableOrderingComposer(
            $db: $db,
            $table: $db.accessKeyTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BucketTableTableOrderingComposer get bucketName {
    final $$BucketTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableOrderingComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccessKeyGrantTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccessKeyGrantTableTable> {
  $$AccessKeyGrantTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<AccessKeyLevel, String> get access =>
      $composableBuilder(column: $table.access, builder: (column) => column);

  $$AccessKeyTableTableAnnotationComposer get keyId {
    final $$AccessKeyTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyId,
      referencedTable: $db.accessKeyTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccessKeyTableTableAnnotationComposer(
            $db: $db,
            $table: $db.accessKeyTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BucketTableTableAnnotationComposer get bucketName {
    final $$BucketTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableAnnotationComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccessKeyGrantTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccessKeyGrantTableTable,
          AccessKeyGrantTableData,
          $$AccessKeyGrantTableTableFilterComposer,
          $$AccessKeyGrantTableTableOrderingComposer,
          $$AccessKeyGrantTableTableAnnotationComposer,
          $$AccessKeyGrantTableTableCreateCompanionBuilder,
          $$AccessKeyGrantTableTableUpdateCompanionBuilder,
          (AccessKeyGrantTableData, $$AccessKeyGrantTableTableReferences),
          AccessKeyGrantTableData,
          PrefetchHooks Function({bool keyId, bool bucketName})
        > {
  $$AccessKeyGrantTableTableTableManager(
    _$AppDatabase db,
    $AccessKeyGrantTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccessKeyGrantTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccessKeyGrantTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AccessKeyGrantTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> keyId = const Value.absent(),
                Value<String> bucketName = const Value.absent(),
                Value<AccessKeyLevel> access = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccessKeyGrantTableCompanion(
                keyId: keyId,
                bucketName: bucketName,
                access: access,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String keyId,
                required String bucketName,
                required AccessKeyLevel access,
                Value<int> rowid = const Value.absent(),
              }) => AccessKeyGrantTableCompanion.insert(
                keyId: keyId,
                bucketName: bucketName,
                access: access,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $AccessKeyGrantTableTable,
                    AccessKeyGrantTableData
                  >(table),
                  $$AccessKeyGrantTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({keyId = false, bucketName = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (keyId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.keyId,
                        referencedTable: $$AccessKeyGrantTableTableReferences
                            ._keyIdTable(db),
                        referencedColumn: $$AccessKeyGrantTableTableReferences
                            ._keyIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (bucketName) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bucketName,
                        referencedTable: $$AccessKeyGrantTableTableReferences
                            ._bucketNameTable(db),
                        referencedColumn: $$AccessKeyGrantTableTableReferences
                            ._bucketNameTable(db)
                            .name,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AccessKeyGrantTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccessKeyGrantTableTable,
      AccessKeyGrantTableData,
      $$AccessKeyGrantTableTableFilterComposer,
      $$AccessKeyGrantTableTableOrderingComposer,
      $$AccessKeyGrantTableTableAnnotationComposer,
      $$AccessKeyGrantTableTableCreateCompanionBuilder,
      $$AccessKeyGrantTableTableUpdateCompanionBuilder,
      (AccessKeyGrantTableData, $$AccessKeyGrantTableTableReferences),
      AccessKeyGrantTableData,
      PrefetchHooks Function({bool keyId, bool bucketName})
    >;
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

final class $$AnonymousRuleTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AnonymousRuleTableTable,
          AnonymousRuleTableData
        > {
  $$AnonymousRuleTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BucketTableTable _bucketNameTable(_$AppDatabase db) =>
      db.bucketTable.createAlias('anonymous_rule__bucket_name__bucket__name');

  $$BucketTableTableProcessedTableManager get bucketName {
    final $_column = $_itemColumn<String>('bucket_name')!;

    final manager = $$BucketTableTableTableManager(
      $_db,
      $_db.bucketTable,
    ).filter((f) => f.name.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bucketNameTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  $$BucketTableTableFilterComposer get bucketName {
    final $$BucketTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableFilterComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get access => $composableBuilder(
    column: $table.access,
    builder: (column) => ColumnOrderings(column),
  );

  $$BucketTableTableOrderingComposer get bucketName {
    final $$BucketTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableOrderingComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get prefix =>
      $composableBuilder(column: $table.prefix, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AnonymousAccessType, String> get access =>
      $composableBuilder(column: $table.access, builder: (column) => column);

  $$BucketTableTableAnnotationComposer get bucketName {
    final $$BucketTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableAnnotationComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (AnonymousRuleTableData, $$AnonymousRuleTableTableReferences),
          AnonymousRuleTableData,
          PrefetchHooks Function({bool bucketName})
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
              .map(
                (e) => (
                  e.readTable<$AnonymousRuleTableTable, AnonymousRuleTableData>(
                    table,
                  ),
                  $$AnonymousRuleTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bucketName = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bucketName) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bucketName,
                        referencedTable: $$AnonymousRuleTableTableReferences
                            ._bucketNameTable(db),
                        referencedColumn: $$AnonymousRuleTableTableReferences
                            ._bucketNameTable(db)
                            .name,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
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
      (AnonymousRuleTableData, $$AnonymousRuleTableTableReferences),
      AnonymousRuleTableData,
      PrefetchHooks Function({bool bucketName})
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

final class $$ObjectMetaTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ObjectMetaTableTable,
          ObjectMetaTableData
        > {
  $$ObjectMetaTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BucketTableTable _bucketNameTable(_$AppDatabase db) =>
      db.bucketTable.createAlias('object_meta__bucket_name__bucket__name');

  $$BucketTableTableProcessedTableManager get bucketName {
    final $_column = $_itemColumn<String>('bucket_name')!;

    final manager = $$BucketTableTableTableManager(
      $_db,
      $_db.bucketTable,
    ).filter((f) => f.name.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bucketNameTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ObjectMetaTableTableFilterComposer
    extends Composer<_$AppDatabase, $ObjectMetaTableTable> {
  $$ObjectMetaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
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

  $$BucketTableTableFilterComposer get bucketName {
    final $$BucketTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableFilterComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$BucketTableTableOrderingComposer get bucketName {
    final $$BucketTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableOrderingComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  $$BucketTableTableAnnotationComposer get bucketName {
    final $$BucketTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bucketName,
      referencedTable: $db.bucketTable,
      getReferencedColumn: (t) => t.name,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BucketTableTableAnnotationComposer(
            $db: $db,
            $table: $db.bucketTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (ObjectMetaTableData, $$ObjectMetaTableTableReferences),
          ObjectMetaTableData,
          PrefetchHooks Function({bool bucketName})
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
              .map(
                (e) => (
                  e.readTable<$ObjectMetaTableTable, ObjectMetaTableData>(
                    table,
                  ),
                  $$ObjectMetaTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bucketName = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bucketName) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bucketName,
                        referencedTable: $$ObjectMetaTableTableReferences
                            ._bucketNameTable(db),
                        referencedColumn: $$ObjectMetaTableTableReferences
                            ._bucketNameTable(db)
                            .name,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
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
      (ObjectMetaTableData, $$ObjectMetaTableTableReferences),
      ObjectMetaTableData,
      PrefetchHooks Function({bool bucketName})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccessKeyTableTableTableManager get accessKeyTable =>
      $$AccessKeyTableTableTableManager(_db, _db.accessKeyTable);
  $$BucketTableTableTableManager get bucketTable =>
      $$BucketTableTableTableManager(_db, _db.bucketTable);
  $$AccessKeyGrantTableTableTableManager get accessKeyGrantTable =>
      $$AccessKeyGrantTableTableTableManager(_db, _db.accessKeyGrantTable);
  $$AnonymousRuleTableTableTableManager get anonymousRuleTable =>
      $$AnonymousRuleTableTableTableManager(_db, _db.anonymousRuleTable);
  $$ObjectMetaTableTableTableManager get objectMetaTable =>
      $$ObjectMetaTableTableTableManager(_db, _db.objectMetaTable);
}
