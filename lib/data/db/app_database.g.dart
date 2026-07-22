// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HouseholdsTable extends Households
    with TableInfo<$HouseholdsTable, Household> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inviteCodeMeta = const VerificationMeta(
    'inviteCode',
  );
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
    'invite_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ownerUserId,
    inviteCode,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'households';
  @override
  VerificationContext validateIntegrity(
    Insertable<Household> instance, {
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
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUserIdMeta);
    }
    if (data.containsKey('invite_code')) {
      context.handle(
        _inviteCodeMeta,
        inviteCode.isAcceptableOrUnknown(data['invite_code']!, _inviteCodeMeta),
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Household map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Household(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      )!,
      inviteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_code'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $HouseholdsTable createAlias(String alias) {
    return $HouseholdsTable(attachedDatabase, alias);
  }
}

class Household extends DataClass implements Insertable<Household> {
  final String id;
  final String name;
  final String ownerUserId;

  /// Kurzcode zum Beitreten, wird ab v0.8 serverseitig vergeben.
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  const Household({
    required this.id,
    required this.name,
    required this.ownerUserId,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['owner_user_id'] = Variable<String>(ownerUserId);
    if (!nullToAbsent || inviteCode != null) {
      map['invite_code'] = Variable<String>(inviteCode);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  HouseholdsCompanion toCompanion(bool nullToAbsent) {
    return HouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      ownerUserId: Value(ownerUserId),
      inviteCode: inviteCode == null && nullToAbsent
          ? const Value.absent()
          : Value(inviteCode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }

  factory Household.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Household(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerUserId: serializer.fromJson<String>(json['ownerUserId']),
      inviteCode: serializer.fromJson<String?>(json['inviteCode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'ownerUserId': serializer.toJson<String>(ownerUserId),
      'inviteCode': serializer.toJson<String?>(inviteCode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  Household copyWith({
    String? id,
    String? name,
    String? ownerUserId,
    Value<String?> inviteCode = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? isDirty,
  }) => Household(
    id: id ?? this.id,
    name: name ?? this.name,
    ownerUserId: ownerUserId ?? this.ownerUserId,
    inviteCode: inviteCode.present ? inviteCode.value : this.inviteCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    isDirty: isDirty ?? this.isDirty,
  );
  Household copyWithCompanion(HouseholdsCompanion data) {
    return Household(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      inviteCode: data.inviteCode.present
          ? data.inviteCode.value
          : this.inviteCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Household(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    ownerUserId,
    inviteCode,
    createdAt,
    updatedAt,
    deletedAt,
    isDirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Household &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerUserId == this.ownerUserId &&
          other.inviteCode == this.inviteCode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isDirty == this.isDirty);
}

class HouseholdsCompanion extends UpdateCompanion<Household> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> ownerUserId;
  final Value<String?> inviteCode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const HouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String ownerUserId,
    this.inviteCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       ownerUserId = Value(ownerUserId);
  static Insertable<Household> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerUserId,
    Expression<String>? inviteCode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? ownerUserId,
    Value<String?>? inviteCode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? isDirty,
    Value<int>? rowid,
  }) {
    return HouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDirty: isDirty ?? this.isDirty,
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
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HouseholdMembersTable extends HouseholdMembers
    with TableInfo<$HouseholdMembersTable, HouseholdMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    userId,
    displayName,
    role,
    joinedAt,
    updatedAt,
    deletedAt,
    isDirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<HouseholdMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HouseholdMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
    );
  }

  @override
  $HouseholdMembersTable createAlias(String alias) {
    return $HouseholdMembersTable(attachedDatabase, alias);
  }
}

class HouseholdMember extends DataClass implements Insertable<HouseholdMember> {
  final String id;
  final String householdId;
  final String userId;
  final String displayName;

  /// Name der [HouseholdRole].
  final String role;
  final DateTime joinedAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isDirty;
  const HouseholdMember({
    required this.id,
    required this.householdId,
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isDirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['user_id'] = Variable<String>(userId);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    map['joined_at'] = Variable<DateTime>(joinedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  HouseholdMembersCompanion toCompanion(bool nullToAbsent) {
    return HouseholdMembersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      userId: Value(userId),
      displayName: Value(displayName),
      role: Value(role),
      joinedAt: Value(joinedAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isDirty: Value(isDirty),
    );
  }

  factory HouseholdMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdMember(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  HouseholdMember copyWith({
    String? id,
    String? householdId,
    String? userId,
    String? displayName,
    String? role,
    DateTime? joinedAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    bool? isDirty,
  }) => HouseholdMember(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    joinedAt: joinedAt ?? this.joinedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    isDirty: isDirty ?? this.isDirty,
  );
  HouseholdMember copyWithCompanion(HouseholdMembersCompanion data) {
    return HouseholdMember(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMember(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    userId,
    displayName,
    role,
    joinedAt,
    updatedAt,
    deletedAt,
    isDirty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdMember &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.joinedAt == this.joinedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isDirty == this.isDirty);
}

class HouseholdMembersCompanion extends UpdateCompanion<HouseholdMember> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> userId;
  final Value<String> displayName;
  final Value<String> role;
  final Value<DateTime> joinedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const HouseholdMembersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdMembersCompanion.insert({
    this.id = const Value.absent(),
    required String householdId,
    required String userId,
    required String displayName,
    required String role,
    this.joinedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : householdId = Value(householdId),
       userId = Value(userId),
       displayName = Value(displayName),
       role = Value(role);
  static Insertable<HouseholdMember> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<DateTime>? joinedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? userId,
    Value<String>? displayName,
    Value<String>? role,
    Value<DateTime>? joinedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<bool>? isDirty,
    Value<int>? rowid,
  }) {
    return HouseholdMembersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDirty: isDirty ?? this.isDirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMembersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditEntriesTable extends AuditEntries
    with TableInfo<$AuditEntriesTable, AuditEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorNameMeta = const VerificationMeta(
    'actorName',
  );
  @override
  late final GeneratedColumn<String> actorName = GeneratedColumn<String>(
    'actor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    entityType,
    entityId,
    action,
    summary,
    actorName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('actor_name')) {
      context.handle(
        _actorNameMeta,
        actorName.isAcceptableOrUnknown(data['actor_name']!, _actorNameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      actorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_name'],
      ),
    );
  }

  @override
  $AuditEntriesTable createAlias(String alias) {
    return $AuditEntriesTable(attachedDatabase, alias);
  }
}

class AuditEntry extends DataClass implements Insertable<AuditEntry> {
  final String id;

  /// 'personal' oder 'household'.
  final String scopeKind;

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  final String scopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Wurde lokal geändert und noch nicht zum Server geschickt.
  final bool isDirty;

  /// z.B. 'inventory_item', 'med_plan'.
  final String entityType;
  final String entityId;

  /// 'create', 'update', 'delete'.
  final String action;

  /// Menschenlesbare Zusammenfassung, z.B. "Milch von 2 auf 1 reduziert".
  final String summary;
  final String? actorName;
  const AuditEntry({
    required this.id,
    required this.scopeKind,
    required this.scopeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    required this.isDirty,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.summary,
    this.actorName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || actorName != null) {
      map['actor_name'] = Variable<String>(actorName);
    }
    return map;
  }

  AuditEntriesCompanion toCompanion(bool nullToAbsent) {
    return AuditEntriesCompanion(
      id: Value(id),
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDirty: Value(isDirty),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      summary: Value(summary),
      actorName: actorName == null && nullToAbsent
          ? const Value.absent()
          : Value(actorName),
    );
  }

  factory AuditEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditEntry(
      id: serializer.fromJson<String>(json['id']),
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      summary: serializer.fromJson<String>(json['summary']),
      actorName: serializer.fromJson<String?>(json['actorName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'summary': serializer.toJson<String>(summary),
      'actorName': serializer.toJson<String?>(actorName),
    };
  }

  AuditEntry copyWith({
    String? id,
    String? scopeKind,
    String? scopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    bool? isDirty,
    String? entityType,
    String? entityId,
    String? action,
    String? summary,
    Value<String?> actorName = const Value.absent(),
  }) => AuditEntry(
    id: id ?? this.id,
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    isDirty: isDirty ?? this.isDirty,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    summary: summary ?? this.summary,
    actorName: actorName.present ? actorName.value : this.actorName,
  );
  AuditEntry copyWithCompanion(AuditEntriesCompanion data) {
    return AuditEntry(
      id: data.id.present ? data.id.value : this.id,
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      summary: data.summary.present ? data.summary.value : this.summary,
      actorName: data.actorName.present ? data.actorName.value : this.actorName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditEntry(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('summary: $summary, ')
          ..write('actorName: $actorName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    entityType,
    entityId,
    action,
    summary,
    actorName,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditEntry &&
          other.id == this.id &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDirty == this.isDirty &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.summary == this.summary &&
          other.actorName == this.actorName);
}

class AuditEntriesCompanion extends UpdateCompanion<AuditEntry> {
  final Value<String> id;
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDirty;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> summary;
  final Value<String?> actorName;
  final Value<int> rowid;
  const AuditEntriesCompanion({
    this.id = const Value.absent(),
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.summary = const Value.absent(),
    this.actorName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String scopeKind,
    required String scopeId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    required String entityType,
    required String entityId,
    required String action,
    required String summary,
    this.actorName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       summary = Value(summary);
  static Insertable<AuditEntry> custom({
    Expression<String>? id,
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDirty,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? summary,
    Expression<String>? actorName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (summary != null) 'summary': summary,
      if (actorName != null) 'actor_name': actorName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<bool>? isDirty,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<String>? summary,
    Value<String?>? actorName,
    Value<int>? rowid,
  }) {
    return AuditEntriesCompanion(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDirty: isDirty ?? this.isDirty,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      summary: summary ?? this.summary,
      actorName: actorName ?? this.actorName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (actorName.present) {
      map['actor_name'] = Variable<String>(actorName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditEntriesCompanion(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('summary: $summary, ')
          ..write('actorName: $actorName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StorageLocationsTable extends StorageLocations
    with TableInfo<$StorageLocationsTable, StorageLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorageLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('shelf'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    name,
    iconKey,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorageLocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StorageLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageLocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $StorageLocationsTable createAlias(String alias) {
    return $StorageLocationsTable(attachedDatabase, alias);
  }
}

class StorageLocation extends DataClass implements Insertable<StorageLocation> {
  final String id;

  /// 'personal' oder 'household'.
  final String scopeKind;

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  final String scopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Wurde lokal geändert und noch nicht zum Server geschickt.
  final bool isDirty;
  final String name;

  /// Schlüssel aus [storageIcons], nicht der Icon-Codepoint selbst, damit die
  /// Zeile ohne Flutter-Abhängigkeit synchronisiert werden kann.
  final String iconKey;
  final int sortOrder;
  const StorageLocation({
    required this.id,
    required this.scopeKind,
    required this.scopeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    required this.isDirty,
    required this.name,
    required this.iconKey,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['name'] = Variable<String>(name);
    map['icon_key'] = Variable<String>(iconKey);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  StorageLocationsCompanion toCompanion(bool nullToAbsent) {
    return StorageLocationsCompanion(
      id: Value(id),
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDirty: Value(isDirty),
      name: Value(name),
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory StorageLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageLocation(
      id: serializer.fromJson<String>(json['id']),
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String>(iconKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  StorageLocation copyWith({
    String? id,
    String? scopeKind,
    String? scopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    bool? isDirty,
    String? name,
    String? iconKey,
    int? sortOrder,
  }) => StorageLocation(
    id: id ?? this.id,
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    isDirty: isDirty ?? this.isDirty,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  StorageLocation copyWithCompanion(StorageLocationsCompanion data) {
    return StorageLocation(
      id: data.id.present ? data.id.value : this.id,
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorageLocation(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    name,
    iconKey,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageLocation &&
          other.id == this.id &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDirty == this.isDirty &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.sortOrder == this.sortOrder);
}

class StorageLocationsCompanion extends UpdateCompanion<StorageLocation> {
  final Value<String> id;
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDirty;
  final Value<String> name;
  final Value<String> iconKey;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const StorageLocationsCompanion({
    this.id = const Value.absent(),
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorageLocationsCompanion.insert({
    this.id = const Value.absent(),
    required String scopeKind,
    required String scopeId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    required String name,
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId),
       name = Value(name);
  static Insertable<StorageLocation> custom({
    Expression<String>? id,
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDirty,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorageLocationsCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<bool>? isDirty,
    Value<String>? name,
    Value<String>? iconKey,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return StorageLocationsCompanion(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDirty: isDirty ?? this.isDirty,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageLocationsCompanion(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultUnitMeta = const VerificationMeta(
    'defaultUnit',
  );
  @override
  late final GeneratedColumn<String> defaultUnit = GeneratedColumn<String>(
    'default_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('piece'),
  );
  static const VerificationMeta _defaultQuantityMeta = const VerificationMeta(
    'defaultQuantity',
  );
  @override
  late final GeneratedColumn<double> defaultQuantity = GeneratedColumn<double>(
    'default_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    barcode,
    name,
    brand,
    imageUrl,
    category,
    defaultUnit,
    defaultQuantity,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('default_unit')) {
      context.handle(
        _defaultUnitMeta,
        defaultUnit.isAcceptableOrUnknown(
          data['default_unit']!,
          _defaultUnitMeta,
        ),
      );
    }
    if (data.containsKey('default_quantity')) {
      context.handle(
        _defaultQuantityMeta,
        defaultQuantity.isAcceptableOrUnknown(
          data['default_quantity']!,
          _defaultQuantityMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      defaultUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_unit'],
      )!,
      defaultQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_quantity'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;

  /// 'personal' oder 'household'.
  final String scopeKind;

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  final String scopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Wurde lokal geändert und noch nicht zum Server geschickt.
  final bool isDirty;
  final String? barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? category;
  final String defaultUnit;
  final double defaultQuantity;

  /// 'local' oder 'openfoodfacts'.
  final String source;
  const Product({
    required this.id,
    required this.scopeKind,
    required this.scopeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    required this.isDirty,
    this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.category,
    required this.defaultUnit,
    required this.defaultQuantity,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['default_unit'] = Variable<String>(defaultUnit);
    map['default_quantity'] = Variable<double>(defaultQuantity);
    map['source'] = Variable<String>(source);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDirty: Value(isDirty),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      defaultUnit: Value(defaultUnit),
      defaultQuantity: Value(defaultQuantity),
      source: Value(source),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      category: serializer.fromJson<String?>(json['category']),
      defaultUnit: serializer.fromJson<String>(json['defaultUnit']),
      defaultQuantity: serializer.fromJson<double>(json['defaultQuantity']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'barcode': serializer.toJson<String?>(barcode),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'category': serializer.toJson<String?>(category),
      'defaultUnit': serializer.toJson<String>(defaultUnit),
      'defaultQuantity': serializer.toJson<double>(defaultQuantity),
      'source': serializer.toJson<String>(source),
    };
  }

  Product copyWith({
    String? id,
    String? scopeKind,
    String? scopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    bool? isDirty,
    Value<String?> barcode = const Value.absent(),
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? defaultUnit,
    double? defaultQuantity,
    String? source,
  }) => Product(
    id: id ?? this.id,
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    isDirty: isDirty ?? this.isDirty,
    barcode: barcode.present ? barcode.value : this.barcode,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    category: category.present ? category.value : this.category,
    defaultUnit: defaultUnit ?? this.defaultUnit,
    defaultQuantity: defaultQuantity ?? this.defaultQuantity,
    source: source ?? this.source,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      category: data.category.present ? data.category.value : this.category,
      defaultUnit: data.defaultUnit.present
          ? data.defaultUnit.value
          : this.defaultUnit,
      defaultQuantity: data.defaultQuantity.present
          ? data.defaultQuantity.value
          : this.defaultQuantity,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('category: $category, ')
          ..write('defaultUnit: $defaultUnit, ')
          ..write('defaultQuantity: $defaultQuantity, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    barcode,
    name,
    brand,
    imageUrl,
    category,
    defaultUnit,
    defaultQuantity,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDirty == this.isDirty &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.imageUrl == this.imageUrl &&
          other.category == this.category &&
          other.defaultUnit == this.defaultUnit &&
          other.defaultQuantity == this.defaultQuantity &&
          other.source == this.source);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDirty;
  final Value<String?> barcode;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String?> imageUrl;
  final Value<String?> category;
  final Value<String> defaultUnit;
  final Value<double> defaultQuantity;
  final Value<String> source;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.defaultUnit = const Value.absent(),
    this.defaultQuantity = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String scopeKind,
    required String scopeId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.barcode = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.category = const Value.absent(),
    this.defaultUnit = const Value.absent(),
    this.defaultQuantity = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId),
       name = Value(name);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDirty,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? imageUrl,
    Expression<String>? category,
    Expression<String>? defaultUnit,
    Expression<double>? defaultQuantity,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (imageUrl != null) 'image_url': imageUrl,
      if (category != null) 'category': category,
      if (defaultUnit != null) 'default_unit': defaultUnit,
      if (defaultQuantity != null) 'default_quantity': defaultQuantity,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<bool>? isDirty,
    Value<String?>? barcode,
    Value<String>? name,
    Value<String?>? brand,
    Value<String?>? imageUrl,
    Value<String?>? category,
    Value<String>? defaultUnit,
    Value<double>? defaultQuantity,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDirty: isDirty ?? this.isDirty,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (defaultUnit.present) {
      map['default_unit'] = Variable<String>(defaultUnit.value);
    }
    if (defaultQuantity.present) {
      map['default_quantity'] = Variable<double>(defaultQuantity.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('category: $category, ')
          ..write('defaultUnit: $defaultUnit, ')
          ..write('defaultQuantity: $defaultQuantity, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES storage_locations (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('piece'),
  );
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
  static const VerificationMeta _minQuantityMeta = const VerificationMeta(
    'minQuantity',
  );
  @override
  late final GeneratedColumn<double> minQuantity = GeneratedColumn<double>(
    'min_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindOnExpiryMeta = const VerificationMeta(
    'remindOnExpiry',
  );
  @override
  late final GeneratedColumn<bool> remindOnExpiry = GeneratedColumn<bool>(
    'remind_on_expiry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remind_on_expiry" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    productId,
    locationId,
    name,
    barcode,
    quantity,
    unit,
    expiresAt,
    minQuantity,
    note,
    remindOnExpiry,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('min_quantity')) {
      context.handle(
        _minQuantityMeta,
        minQuantity.isAcceptableOrUnknown(
          data['min_quantity']!,
          _minQuantityMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('remind_on_expiry')) {
      context.handle(
        _remindOnExpiryMeta,
        remindOnExpiry.isAcceptableOrUnknown(
          data['remind_on_expiry']!,
          _remindOnExpiryMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      minQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_quantity'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      remindOnExpiry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remind_on_expiry'],
      )!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  final String id;

  /// 'personal' oder 'household'.
  final String scopeKind;

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  final String scopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Wurde lokal geändert und noch nicht zum Server geschickt.
  final bool isDirty;
  final String? productId;
  final String? locationId;
  final String name;
  final String? barcode;
  final double quantity;
  final String unit;
  final DateTime? expiresAt;

  /// Ab dieser Menge gilt der Vorrat als knapp.
  final double? minQuantity;
  final String? note;

  /// Erinnerung für genau diesen Artikel abschaltbar, unabhängig von der
  /// globalen Einstellung für Ablaufwarnungen.
  final bool remindOnExpiry;
  const InventoryItem({
    required this.id,
    required this.scopeKind,
    required this.scopeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    required this.isDirty,
    this.productId,
    this.locationId,
    required this.name,
    this.barcode,
    required this.quantity,
    required this.unit,
    this.expiresAt,
    this.minQuantity,
    this.note,
    required this.remindOnExpiry,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    if (!nullToAbsent || minQuantity != null) {
      map['min_quantity'] = Variable<double>(minQuantity);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['remind_on_expiry'] = Variable<bool>(remindOnExpiry);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDirty: Value(isDirty),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      name: Value(name),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      quantity: Value(quantity),
      unit: Value(unit),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      minQuantity: minQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(minQuantity),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      remindOnExpiry: Value(remindOnExpiry),
    );
  }

  factory InventoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      id: serializer.fromJson<String>(json['id']),
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      productId: serializer.fromJson<String?>(json['productId']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      name: serializer.fromJson<String>(json['name']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      minQuantity: serializer.fromJson<double?>(json['minQuantity']),
      note: serializer.fromJson<String?>(json['note']),
      remindOnExpiry: serializer.fromJson<bool>(json['remindOnExpiry']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'productId': serializer.toJson<String?>(productId),
      'locationId': serializer.toJson<String?>(locationId),
      'name': serializer.toJson<String>(name),
      'barcode': serializer.toJson<String?>(barcode),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'minQuantity': serializer.toJson<double?>(minQuantity),
      'note': serializer.toJson<String?>(note),
      'remindOnExpiry': serializer.toJson<bool>(remindOnExpiry),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? scopeKind,
    String? scopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    bool? isDirty,
    Value<String?> productId = const Value.absent(),
    Value<String?> locationId = const Value.absent(),
    String? name,
    Value<String?> barcode = const Value.absent(),
    double? quantity,
    String? unit,
    Value<DateTime?> expiresAt = const Value.absent(),
    Value<double?> minQuantity = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? remindOnExpiry,
  }) => InventoryItem(
    id: id ?? this.id,
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    isDirty: isDirty ?? this.isDirty,
    productId: productId.present ? productId.value : this.productId,
    locationId: locationId.present ? locationId.value : this.locationId,
    name: name ?? this.name,
    barcode: barcode.present ? barcode.value : this.barcode,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    minQuantity: minQuantity.present ? minQuantity.value : this.minQuantity,
    note: note.present ? note.value : this.note,
    remindOnExpiry: remindOnExpiry ?? this.remindOnExpiry,
  );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      id: data.id.present ? data.id.value : this.id,
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      productId: data.productId.present ? data.productId.value : this.productId,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      name: data.name.present ? data.name.value : this.name,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      minQuantity: data.minQuantity.present
          ? data.minQuantity.value
          : this.minQuantity,
      note: data.note.present ? data.note.value : this.note,
      remindOnExpiry: data.remindOnExpiry.present
          ? data.remindOnExpiry.value
          : this.remindOnExpiry,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('productId: $productId, ')
          ..write('locationId: $locationId, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('note: $note, ')
          ..write('remindOnExpiry: $remindOnExpiry')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    productId,
    locationId,
    name,
    barcode,
    quantity,
    unit,
    expiresAt,
    minQuantity,
    note,
    remindOnExpiry,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.id == this.id &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDirty == this.isDirty &&
          other.productId == this.productId &&
          other.locationId == this.locationId &&
          other.name == this.name &&
          other.barcode == this.barcode &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.expiresAt == this.expiresAt &&
          other.minQuantity == this.minQuantity &&
          other.note == this.note &&
          other.remindOnExpiry == this.remindOnExpiry);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<String> id;
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDirty;
  final Value<String?> productId;
  final Value<String?> locationId;
  final Value<String> name;
  final Value<String?> barcode;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<DateTime?> expiresAt;
  final Value<double?> minQuantity;
  final Value<String?> note;
  final Value<bool> remindOnExpiry;
  final Value<int> rowid;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.productId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.name = const Value.absent(),
    this.barcode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.minQuantity = const Value.absent(),
    this.note = const Value.absent(),
    this.remindOnExpiry = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String scopeKind,
    required String scopeId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.productId = const Value.absent(),
    this.locationId = const Value.absent(),
    required String name,
    this.barcode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.minQuantity = const Value.absent(),
    this.note = const Value.absent(),
    this.remindOnExpiry = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId),
       name = Value(name);
  static Insertable<InventoryItem> custom({
    Expression<String>? id,
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDirty,
    Expression<String>? productId,
    Expression<String>? locationId,
    Expression<String>? name,
    Expression<String>? barcode,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<DateTime>? expiresAt,
    Expression<double>? minQuantity,
    Expression<String>? note,
    Expression<bool>? remindOnExpiry,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (productId != null) 'product_id': productId,
      if (locationId != null) 'location_id': locationId,
      if (name != null) 'name': name,
      if (barcode != null) 'barcode': barcode,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (minQuantity != null) 'min_quantity': minQuantity,
      if (note != null) 'note': note,
      if (remindOnExpiry != null) 'remind_on_expiry': remindOnExpiry,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<bool>? isDirty,
    Value<String?>? productId,
    Value<String?>? locationId,
    Value<String>? name,
    Value<String?>? barcode,
    Value<double>? quantity,
    Value<String>? unit,
    Value<DateTime?>? expiresAt,
    Value<double?>? minQuantity,
    Value<String?>? note,
    Value<bool>? remindOnExpiry,
    Value<int>? rowid,
  }) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDirty: isDirty ?? this.isDirty,
      productId: productId ?? this.productId,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiresAt: expiresAt ?? this.expiresAt,
      minQuantity: minQuantity ?? this.minQuantity,
      note: note ?? this.note,
      remindOnExpiry: remindOnExpiry ?? this.remindOnExpiry,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (minQuantity.present) {
      map['min_quantity'] = Variable<double>(minQuantity.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (remindOnExpiry.present) {
      map['remind_on_expiry'] = Variable<bool>(remindOnExpiry.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('productId: $productId, ')
          ..write('locationId: $locationId, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('note: $note, ')
          ..write('remindOnExpiry: $remindOnExpiry, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListsTable extends ShoppingLists
    with TableInfo<$ShoppingListsTable, ShoppingList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    name,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ShoppingListsTable createAlias(String alias) {
    return $ShoppingListsTable(attachedDatabase, alias);
  }
}

class ShoppingList extends DataClass implements Insertable<ShoppingList> {
  final String id;

  /// 'personal' oder 'household'.
  final String scopeKind;

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  final String scopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Wurde lokal geändert und noch nicht zum Server geschickt.
  final bool isDirty;
  final String name;
  final int sortOrder;
  const ShoppingList({
    required this.id,
    required this.scopeKind,
    required this.scopeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    required this.isDirty,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListsCompanion(
      id: Value(id),
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDirty: Value(isDirty),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory ShoppingList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingList(
      id: serializer.fromJson<String>(json['id']),
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ShoppingList copyWith({
    String? id,
    String? scopeKind,
    String? scopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    bool? isDirty,
    String? name,
    int? sortOrder,
  }) => ShoppingList(
    id: id ?? this.id,
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    isDirty: isDirty ?? this.isDirty,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ShoppingList copyWithCompanion(ShoppingListsCompanion data) {
    return ShoppingList(
      id: data.id.present ? data.id.value : this.id,
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingList(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    name,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingList &&
          other.id == this.id &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDirty == this.isDirty &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class ShoppingListsCompanion extends UpdateCompanion<ShoppingList> {
  final Value<String> id;
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDirty;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ShoppingListsCompanion({
    this.id = const Value.absent(),
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListsCompanion.insert({
    this.id = const Value.absent(),
    required String scopeKind,
    required String scopeId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId),
       name = Value(name);
  static Insertable<ShoppingList> custom({
    Expression<String>? id,
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDirty,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListsCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<bool>? isDirty,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ShoppingListsCompanion(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDirty: isDirty ?? this.isDirty,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingItemsTable extends ShoppingItems
    with TableInfo<$ShoppingItemsTable, ShoppingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shopping_lists (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('piece'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCheckedMeta = const VerificationMeta(
    'isChecked',
  );
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
    'is_checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  @override
  late final GeneratedColumn<DateTime> checkedAt = GeneratedColumn<DateTime>(
    'checked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedByMeta = const VerificationMeta(
    'checkedBy',
  );
  @override
  late final GeneratedColumn<String> checkedBy = GeneratedColumn<String>(
    'checked_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inventoryItemIdMeta = const VerificationMeta(
    'inventoryItemId',
  );
  @override
  late final GeneratedColumn<String> inventoryItemId = GeneratedColumn<String>(
    'inventory_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES inventory_items (id)',
    ),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    listId,
    name,
    quantity,
    unit,
    category,
    note,
    isChecked,
    checkedAt,
    checkedBy,
    inventoryItemId,
    barcode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_checked')) {
      context.handle(
        _isCheckedMeta,
        isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta),
      );
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    }
    if (data.containsKey('checked_by')) {
      context.handle(
        _checkedByMeta,
        checkedBy.isAcceptableOrUnknown(data['checked_by']!, _checkedByMeta),
      );
    }
    if (data.containsKey('inventory_item_id')) {
      context.handle(
        _inventoryItemIdMeta,
        inventoryItemId.isAcceptableOrUnknown(
          data['inventory_item_id']!,
          _inventoryItemIdMeta,
        ),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_checked'],
      )!,
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_at'],
      ),
      checkedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checked_by'],
      ),
      inventoryItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inventory_item_id'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
    );
  }

  @override
  $ShoppingItemsTable createAlias(String alias) {
    return $ShoppingItemsTable(attachedDatabase, alias);
  }
}

class ShoppingItem extends DataClass implements Insertable<ShoppingItem> {
  final String id;

  /// 'personal' oder 'household'.
  final String scopeKind;

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  final String scopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Wurde lokal geändert und noch nicht zum Server geschickt.
  final bool isDirty;
  final String listId;
  final String name;
  final double quantity;
  final String unit;

  /// Name der [ShoppingCategory], für die Gruppierung im Laden.
  final String category;
  final String? note;
  final bool isChecked;
  final DateTime? checkedAt;
  final String? checkedBy;

  /// Gesetzt, wenn der Posten aus einem knappen Vorrat entstanden ist.
  /// Beim Übernehmen wird dann der Bestand erhöht statt ein neuer Artikel
  /// angelegt.
  final String? inventoryItemId;
  final String? barcode;
  const ShoppingItem({
    required this.id,
    required this.scopeKind,
    required this.scopeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    required this.isDirty,
    required this.listId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.note,
    required this.isChecked,
    this.checkedAt,
    this.checkedBy,
    this.inventoryItemId,
    this.barcode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['list_id'] = Variable<String>(listId);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_checked'] = Variable<bool>(isChecked);
    if (!nullToAbsent || checkedAt != null) {
      map['checked_at'] = Variable<DateTime>(checkedAt);
    }
    if (!nullToAbsent || checkedBy != null) {
      map['checked_by'] = Variable<String>(checkedBy);
    }
    if (!nullToAbsent || inventoryItemId != null) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    return map;
  }

  ShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingItemsCompanion(
      id: Value(id),
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDirty: Value(isDirty),
      listId: Value(listId),
      name: Value(name),
      quantity: Value(quantity),
      unit: Value(unit),
      category: Value(category),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isChecked: Value(isChecked),
      checkedAt: checkedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedAt),
      checkedBy: checkedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedBy),
      inventoryItemId: inventoryItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(inventoryItemId),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
    );
  }

  factory ShoppingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingItem(
      id: serializer.fromJson<String>(json['id']),
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      listId: serializer.fromJson<String>(json['listId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      category: serializer.fromJson<String>(json['category']),
      note: serializer.fromJson<String?>(json['note']),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      checkedAt: serializer.fromJson<DateTime?>(json['checkedAt']),
      checkedBy: serializer.fromJson<String?>(json['checkedBy']),
      inventoryItemId: serializer.fromJson<String?>(json['inventoryItemId']),
      barcode: serializer.fromJson<String?>(json['barcode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'listId': serializer.toJson<String>(listId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'category': serializer.toJson<String>(category),
      'note': serializer.toJson<String?>(note),
      'isChecked': serializer.toJson<bool>(isChecked),
      'checkedAt': serializer.toJson<DateTime?>(checkedAt),
      'checkedBy': serializer.toJson<String?>(checkedBy),
      'inventoryItemId': serializer.toJson<String?>(inventoryItemId),
      'barcode': serializer.toJson<String?>(barcode),
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? scopeKind,
    String? scopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    bool? isDirty,
    String? listId,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    Value<String?> note = const Value.absent(),
    bool? isChecked,
    Value<DateTime?> checkedAt = const Value.absent(),
    Value<String?> checkedBy = const Value.absent(),
    Value<String?> inventoryItemId = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
  }) => ShoppingItem(
    id: id ?? this.id,
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    isDirty: isDirty ?? this.isDirty,
    listId: listId ?? this.listId,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    category: category ?? this.category,
    note: note.present ? note.value : this.note,
    isChecked: isChecked ?? this.isChecked,
    checkedAt: checkedAt.present ? checkedAt.value : this.checkedAt,
    checkedBy: checkedBy.present ? checkedBy.value : this.checkedBy,
    inventoryItemId: inventoryItemId.present
        ? inventoryItemId.value
        : this.inventoryItemId,
    barcode: barcode.present ? barcode.value : this.barcode,
  );
  ShoppingItem copyWithCompanion(ShoppingItemsCompanion data) {
    return ShoppingItem(
      id: data.id.present ? data.id.value : this.id,
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      listId: data.listId.present ? data.listId.value : this.listId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      category: data.category.present ? data.category.value : this.category,
      note: data.note.present ? data.note.value : this.note,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
      checkedBy: data.checkedBy.present ? data.checkedBy.value : this.checkedBy,
      inventoryItemId: data.inventoryItemId.present
          ? data.inventoryItemId.value
          : this.inventoryItemId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItem(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('isChecked: $isChecked, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('checkedBy: $checkedBy, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('barcode: $barcode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    listId,
    name,
    quantity,
    unit,
    category,
    note,
    isChecked,
    checkedAt,
    checkedBy,
    inventoryItemId,
    barcode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingItem &&
          other.id == this.id &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDirty == this.isDirty &&
          other.listId == this.listId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.category == this.category &&
          other.note == this.note &&
          other.isChecked == this.isChecked &&
          other.checkedAt == this.checkedAt &&
          other.checkedBy == this.checkedBy &&
          other.inventoryItemId == this.inventoryItemId &&
          other.barcode == this.barcode);
}

class ShoppingItemsCompanion extends UpdateCompanion<ShoppingItem> {
  final Value<String> id;
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDirty;
  final Value<String> listId;
  final Value<String> name;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<String> category;
  final Value<String?> note;
  final Value<bool> isChecked;
  final Value<DateTime?> checkedAt;
  final Value<String?> checkedBy;
  final Value<String?> inventoryItemId;
  final Value<String?> barcode;
  final Value<int> rowid;
  const ShoppingItemsCompanion({
    this.id = const Value.absent(),
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.listId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.checkedBy = const Value.absent(),
    this.inventoryItemId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingItemsCompanion.insert({
    this.id = const Value.absent(),
    required String scopeKind,
    required String scopeId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    required String listId,
    required String name,
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.category = const Value.absent(),
    this.note = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.checkedBy = const Value.absent(),
    this.inventoryItemId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId),
       listId = Value(listId),
       name = Value(name);
  static Insertable<ShoppingItem> custom({
    Expression<String>? id,
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDirty,
    Expression<String>? listId,
    Expression<String>? name,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? category,
    Expression<String>? note,
    Expression<bool>? isChecked,
    Expression<DateTime>? checkedAt,
    Expression<String>? checkedBy,
    Expression<String>? inventoryItemId,
    Expression<String>? barcode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (listId != null) 'list_id': listId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (category != null) 'category': category,
      if (note != null) 'note': note,
      if (isChecked != null) 'is_checked': isChecked,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (checkedBy != null) 'checked_by': checkedBy,
      if (inventoryItemId != null) 'inventory_item_id': inventoryItemId,
      if (barcode != null) 'barcode': barcode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<bool>? isDirty,
    Value<String>? listId,
    Value<String>? name,
    Value<double>? quantity,
    Value<String>? unit,
    Value<String>? category,
    Value<String?>? note,
    Value<bool>? isChecked,
    Value<DateTime?>? checkedAt,
    Value<String?>? checkedBy,
    Value<String?>? inventoryItemId,
    Value<String?>? barcode,
    Value<int>? rowid,
  }) {
    return ShoppingItemsCompanion(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDirty: isDirty ?? this.isDirty,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      note: note ?? this.note,
      isChecked: isChecked ?? this.isChecked,
      checkedAt: checkedAt ?? this.checkedAt,
      checkedBy: checkedBy ?? this.checkedBy,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      barcode: barcode ?? this.barcode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<DateTime>(checkedAt.value);
    }
    if (checkedBy.present) {
      map['checked_by'] = Variable<String>(checkedBy.value);
    }
    if (inventoryItemId.present) {
      map['inventory_item_id'] = Variable<String>(inventoryItemId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItemsCompanion(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('category: $category, ')
          ..write('note: $note, ')
          ..write('isChecked: $isChecked, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('checkedBy: $checkedBy, ')
          ..write('inventoryItemId: $inventoryItemId, ')
          ..write('barcode: $barcode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isChecklistMeta = const VerificationMeta(
    'isChecklist',
  );
  @override
  late final GeneratedColumn<bool> isChecklist = GeneratedColumn<bool>(
    'is_checklist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checklist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorKeyMeta = const VerificationMeta(
    'colorKey',
  );
  @override
  late final GeneratedColumn<String> colorKey = GeneratedColumn<String>(
    'color_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    title,
    body,
    isChecklist,
    isPinned,
    colorKey,
    tags,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('is_checklist')) {
      context.handle(
        _isChecklistMeta,
        isChecklist.isAcceptableOrUnknown(
          data['is_checklist']!,
          _isChecklistMeta,
        ),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('color_key')) {
      context.handle(
        _colorKeyMeta,
        colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      isChecklist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_checklist'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      colorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_key'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;

  /// 'personal' oder 'household'.
  final String scopeKind;

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  final String scopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Wurde lokal geändert und noch nicht zum Server geschickt.
  final bool isDirty;
  final String title;
  final String body;
  final bool isChecklist;
  final bool isPinned;

  /// Schluessel aus [noteColors].
  final String colorKey;

  /// Kommagetrennte Tags, klein geschrieben. Fuer eine einfache Suche reicht
  /// das; eine eigene Tag-Tabelle waere hier ueberdimensioniert.
  final String tags;
  const Note({
    required this.id,
    required this.scopeKind,
    required this.scopeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    required this.isDirty,
    required this.title,
    required this.body,
    required this.isChecklist,
    required this.isPinned,
    required this.colorKey,
    required this.tags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['is_checklist'] = Variable<bool>(isChecklist);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['color_key'] = Variable<String>(colorKey);
    map['tags'] = Variable<String>(tags);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDirty: Value(isDirty),
      title: Value(title),
      body: Value(body),
      isChecklist: Value(isChecklist),
      isPinned: Value(isPinned),
      colorKey: Value(colorKey),
      tags: Value(tags),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      isChecklist: serializer.fromJson<bool>(json['isChecklist']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      colorKey: serializer.fromJson<String>(json['colorKey']),
      tags: serializer.fromJson<String>(json['tags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'isChecklist': serializer.toJson<bool>(isChecklist),
      'isPinned': serializer.toJson<bool>(isPinned),
      'colorKey': serializer.toJson<String>(colorKey),
      'tags': serializer.toJson<String>(tags),
    };
  }

  Note copyWith({
    String? id,
    String? scopeKind,
    String? scopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    bool? isDirty,
    String? title,
    String? body,
    bool? isChecklist,
    bool? isPinned,
    String? colorKey,
    String? tags,
  }) => Note(
    id: id ?? this.id,
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    isDirty: isDirty ?? this.isDirty,
    title: title ?? this.title,
    body: body ?? this.body,
    isChecklist: isChecklist ?? this.isChecklist,
    isPinned: isPinned ?? this.isPinned,
    colorKey: colorKey ?? this.colorKey,
    tags: tags ?? this.tags,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      isChecklist: data.isChecklist.present
          ? data.isChecklist.value
          : this.isChecklist,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      tags: data.tags.present ? data.tags.value : this.tags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('isChecklist: $isChecklist, ')
          ..write('isPinned: $isPinned, ')
          ..write('colorKey: $colorKey, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    title,
    body,
    isChecklist,
    isPinned,
    colorKey,
    tags,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDirty == this.isDirty &&
          other.title == this.title &&
          other.body == this.body &&
          other.isChecklist == this.isChecklist &&
          other.isPinned == this.isPinned &&
          other.colorKey == this.colorKey &&
          other.tags == this.tags);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDirty;
  final Value<String> title;
  final Value<String> body;
  final Value<bool> isChecklist;
  final Value<bool> isPinned;
  final Value<String> colorKey;
  final Value<String> tags;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.isChecklist = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String scopeKind,
    required String scopeId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.isChecklist = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.tags = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDirty,
    Expression<String>? title,
    Expression<String>? body,
    Expression<bool>? isChecklist,
    Expression<bool>? isPinned,
    Expression<String>? colorKey,
    Expression<String>? tags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (isChecklist != null) 'is_checklist': isChecklist,
      if (isPinned != null) 'is_pinned': isPinned,
      if (colorKey != null) 'color_key': colorKey,
      if (tags != null) 'tags': tags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<bool>? isDirty,
    Value<String>? title,
    Value<String>? body,
    Value<bool>? isChecklist,
    Value<bool>? isPinned,
    Value<String>? colorKey,
    Value<String>? tags,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDirty: isDirty ?? this.isDirty,
      title: title ?? this.title,
      body: body ?? this.body,
      isChecklist: isChecklist ?? this.isChecklist,
      isPinned: isPinned ?? this.isPinned,
      colorKey: colorKey ?? this.colorKey,
      tags: tags ?? this.tags,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (isChecklist.present) {
      map['is_checklist'] = Variable<bool>(isChecklist.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (colorKey.present) {
      map['color_key'] = Variable<String>(colorKey.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('isChecklist: $isChecklist, ')
          ..write('isPinned: $isPinned, ')
          ..write('colorKey: $colorKey, ')
          ..write('tags: $tags, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteChecklistItemsTable extends NoteChecklistItems
    with TableInfo<$NoteChecklistItemsTable, NoteChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: uuid.v4,
  );
  static const VerificationMeta _scopeKindMeta = const VerificationMeta(
    'scopeKind',
  );
  @override
  late final GeneratedColumn<String> scopeKind = GeneratedColumn<String>(
    'scope_kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notes (id)',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 400,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    noteId,
    content,
    isDone,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_checklist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteChecklistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scope_kind')) {
      context.handle(
        _scopeKindMeta,
        scopeKind.isAcceptableOrUnknown(data['scope_kind']!, _scopeKindMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeIdMeta);
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
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteChecklistItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scopeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $NoteChecklistItemsTable createAlias(String alias) {
    return $NoteChecklistItemsTable(attachedDatabase, alias);
  }
}

class NoteChecklistItem extends DataClass
    implements Insertable<NoteChecklistItem> {
  final String id;

  /// 'personal' oder 'household'.
  final String scopeKind;

  /// Nutzer-ID bei personal, Haushalts-ID bei household.
  final String scopeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? createdBy;
  final String? updatedBy;

  /// Wurde lokal geändert und noch nicht zum Server geschickt.
  final bool isDirty;
  final String noteId;
  final String content;
  final bool isDone;
  final int position;
  const NoteChecklistItem({
    required this.id,
    required this.scopeKind,
    required this.scopeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.createdBy,
    this.updatedBy,
    required this.isDirty,
    required this.noteId,
    required this.content,
    required this.isDone,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scope_kind'] = Variable<String>(scopeKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || updatedBy != null) {
      map['updated_by'] = Variable<String>(updatedBy);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    map['note_id'] = Variable<String>(noteId);
    map['content'] = Variable<String>(content);
    map['is_done'] = Variable<bool>(isDone);
    map['position'] = Variable<int>(position);
    return map;
  }

  NoteChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return NoteChecklistItemsCompanion(
      id: Value(id),
      scopeKind: Value(scopeKind),
      scopeId: Value(scopeId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      updatedBy: updatedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedBy),
      isDirty: Value(isDirty),
      noteId: Value(noteId),
      content: Value(content),
      isDone: Value(isDone),
      position: Value(position),
    );
  }

  factory NoteChecklistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteChecklistItem(
      id: serializer.fromJson<String>(json['id']),
      scopeKind: serializer.fromJson<String>(json['scopeKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      updatedBy: serializer.fromJson<String?>(json['updatedBy']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      noteId: serializer.fromJson<String>(json['noteId']),
      content: serializer.fromJson<String>(json['content']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scopeKind': serializer.toJson<String>(scopeKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'createdBy': serializer.toJson<String?>(createdBy),
      'updatedBy': serializer.toJson<String?>(updatedBy),
      'isDirty': serializer.toJson<bool>(isDirty),
      'noteId': serializer.toJson<String>(noteId),
      'content': serializer.toJson<String>(content),
      'isDone': serializer.toJson<bool>(isDone),
      'position': serializer.toJson<int>(position),
    };
  }

  NoteChecklistItem copyWith({
    String? id,
    String? scopeKind,
    String? scopeId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<String?> updatedBy = const Value.absent(),
    bool? isDirty,
    String? noteId,
    String? content,
    bool? isDone,
    int? position,
  }) => NoteChecklistItem(
    id: id ?? this.id,
    scopeKind: scopeKind ?? this.scopeKind,
    scopeId: scopeId ?? this.scopeId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    updatedBy: updatedBy.present ? updatedBy.value : this.updatedBy,
    isDirty: isDirty ?? this.isDirty,
    noteId: noteId ?? this.noteId,
    content: content ?? this.content,
    isDone: isDone ?? this.isDone,
    position: position ?? this.position,
  );
  NoteChecklistItem copyWithCompanion(NoteChecklistItemsCompanion data) {
    return NoteChecklistItem(
      id: data.id.present ? data.id.value : this.id,
      scopeKind: data.scopeKind.present ? data.scopeKind.value : this.scopeKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      content: data.content.present ? data.content.value : this.content,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteChecklistItem(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('noteId: $noteId, ')
          ..write('content: $content, ')
          ..write('isDone: $isDone, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scopeKind,
    scopeId,
    createdAt,
    updatedAt,
    deletedAt,
    createdBy,
    updatedBy,
    isDirty,
    noteId,
    content,
    isDone,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteChecklistItem &&
          other.id == this.id &&
          other.scopeKind == this.scopeKind &&
          other.scopeId == this.scopeId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdBy == this.createdBy &&
          other.updatedBy == this.updatedBy &&
          other.isDirty == this.isDirty &&
          other.noteId == this.noteId &&
          other.content == this.content &&
          other.isDone == this.isDone &&
          other.position == this.position);
}

class NoteChecklistItemsCompanion extends UpdateCompanion<NoteChecklistItem> {
  final Value<String> id;
  final Value<String> scopeKind;
  final Value<String> scopeId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> createdBy;
  final Value<String?> updatedBy;
  final Value<bool> isDirty;
  final Value<String> noteId;
  final Value<String> content;
  final Value<bool> isDone;
  final Value<int> position;
  final Value<int> rowid;
  const NoteChecklistItemsCompanion({
    this.id = const Value.absent(),
    this.scopeKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.noteId = const Value.absent(),
    this.content = const Value.absent(),
    this.isDone = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteChecklistItemsCompanion.insert({
    this.id = const Value.absent(),
    required String scopeKind,
    required String scopeId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.isDirty = const Value.absent(),
    required String noteId,
    required String content,
    this.isDone = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scopeKind = Value(scopeKind),
       scopeId = Value(scopeId),
       noteId = Value(noteId),
       content = Value(content);
  static Insertable<NoteChecklistItem> custom({
    Expression<String>? id,
    Expression<String>? scopeKind,
    Expression<String>? scopeId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? createdBy,
    Expression<String>? updatedBy,
    Expression<bool>? isDirty,
    Expression<String>? noteId,
    Expression<String>? content,
    Expression<bool>? isDone,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scopeKind != null) 'scope_kind': scopeKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (isDirty != null) 'is_dirty': isDirty,
      if (noteId != null) 'note_id': noteId,
      if (content != null) 'content': content,
      if (isDone != null) 'is_done': isDone,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteChecklistItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? scopeKind,
    Value<String>? scopeId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? createdBy,
    Value<String?>? updatedBy,
    Value<bool>? isDirty,
    Value<String>? noteId,
    Value<String>? content,
    Value<bool>? isDone,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return NoteChecklistItemsCompanion(
      id: id ?? this.id,
      scopeKind: scopeKind ?? this.scopeKind,
      scopeId: scopeId ?? this.scopeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDirty: isDirty ?? this.isDirty,
      noteId: noteId ?? this.noteId,
      content: content ?? this.content,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scopeKind.present) {
      map['scope_kind'] = Variable<String>(scopeKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteChecklistItemsCompanion(')
          ..write('id: $id, ')
          ..write('scopeKind: $scopeKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('isDirty: $isDirty, ')
          ..write('noteId: $noteId, ')
          ..write('content: $content, ')
          ..write('isDone: $isDone, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HouseholdsTable households = $HouseholdsTable(this);
  late final $HouseholdMembersTable householdMembers = $HouseholdMembersTable(
    this,
  );
  late final $AuditEntriesTable auditEntries = $AuditEntriesTable(this);
  late final $StorageLocationsTable storageLocations = $StorageLocationsTable(
    this,
  );
  late final $ProductsTable products = $ProductsTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $ShoppingListsTable shoppingLists = $ShoppingListsTable(this);
  late final $ShoppingItemsTable shoppingItems = $ShoppingItemsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $NoteChecklistItemsTable noteChecklistItems =
      $NoteChecklistItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    households,
    householdMembers,
    auditEntries,
    storageLocations,
    products,
    inventoryItems,
    shoppingLists,
    shoppingItems,
    notes,
    noteChecklistItems,
  ];
}

typedef $$HouseholdsTableCreateCompanionBuilder =
    HouseholdsCompanion Function({
      Value<String> id,
      required String name,
      required String ownerUserId,
      Value<String?> inviteCode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });
typedef $$HouseholdsTableUpdateCompanionBuilder =
    HouseholdsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> ownerUserId,
      Value<String?> inviteCode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });

final class $$HouseholdsTableReferences
    extends BaseReferences<_$AppDatabase, $HouseholdsTable, Household> {
  $$HouseholdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HouseholdMembersTable, List<HouseholdMember>>
  _householdMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.householdMembers,
    aliasName: 'households__id__household_members__household_id',
  );

  $$HouseholdMembersTableProcessedTableManager get householdMembersRefs {
    final manager = $$HouseholdMembersTableTableManager(
      $_db,
      $_db.householdMembers,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _householdMembersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableFilterComposer({
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

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> householdMembersRefs(
    Expression<bool> Function($$HouseholdMembersTableFilterComposer f) f,
  ) {
    final $$HouseholdMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableFilterComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableOrderingComposer({
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

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableAnnotationComposer({
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

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  Expression<T> householdMembersRefs<T extends Object>(
    Expression<T> Function($$HouseholdMembersTableAnnotationComposer a) f,
  ) {
    final $$HouseholdMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdsTable,
          Household,
          $$HouseholdsTableFilterComposer,
          $$HouseholdsTableOrderingComposer,
          $$HouseholdsTableAnnotationComposer,
          $$HouseholdsTableCreateCompanionBuilder,
          $$HouseholdsTableUpdateCompanionBuilder,
          (Household, $$HouseholdsTableReferences),
          Household,
          PrefetchHooks Function({bool householdMembersRefs})
        > {
  $$HouseholdsTableTableManager(_$AppDatabase db, $HouseholdsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ownerUserId = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdsCompanion(
                id: id,
                name: name,
                ownerUserId: ownerUserId,
                inviteCode: inviteCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String ownerUserId,
                Value<String?> inviteCode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdsCompanion.insert(
                id: id,
                name: name,
                ownerUserId: ownerUserId,
                inviteCode: inviteCode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HouseholdsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({householdMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (householdMembersRefs) db.householdMembers,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (householdMembersRefs)
                    await $_getPrefetchedData<
                      Household,
                      $HouseholdsTable,
                      HouseholdMember
                    >(
                      currentTable: table,
                      referencedTable: $$HouseholdsTableReferences
                          ._householdMembersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$HouseholdsTableReferences(
                            db,
                            table,
                            p0,
                          ).householdMembersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.householdId == item.id,
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

typedef $$HouseholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdsTable,
      Household,
      $$HouseholdsTableFilterComposer,
      $$HouseholdsTableOrderingComposer,
      $$HouseholdsTableAnnotationComposer,
      $$HouseholdsTableCreateCompanionBuilder,
      $$HouseholdsTableUpdateCompanionBuilder,
      (Household, $$HouseholdsTableReferences),
      Household,
      PrefetchHooks Function({bool householdMembersRefs})
    >;
typedef $$HouseholdMembersTableCreateCompanionBuilder =
    HouseholdMembersCompanion Function({
      Value<String> id,
      required String householdId,
      required String userId,
      required String displayName,
      required String role,
      Value<DateTime> joinedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });
typedef $$HouseholdMembersTableUpdateCompanionBuilder =
    HouseholdMembersCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> userId,
      Value<String> displayName,
      Value<String> role,
      Value<DateTime> joinedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<bool> isDirty,
      Value<int> rowid,
    });

final class $$HouseholdMembersTableReferences
    extends
        BaseReferences<_$AppDatabase, $HouseholdMembersTable, HouseholdMember> {
  $$HouseholdMembersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) => db.households
      .createAlias('household_members__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HouseholdMembersTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HouseholdMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HouseholdMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HouseholdMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdMembersTable,
          HouseholdMember,
          $$HouseholdMembersTableFilterComposer,
          $$HouseholdMembersTableOrderingComposer,
          $$HouseholdMembersTableAnnotationComposer,
          $$HouseholdMembersTableCreateCompanionBuilder,
          $$HouseholdMembersTableUpdateCompanionBuilder,
          (HouseholdMember, $$HouseholdMembersTableReferences),
          HouseholdMember,
          PrefetchHooks Function({bool householdId})
        > {
  $$HouseholdMembersTableTableManager(
    _$AppDatabase db,
    $HouseholdMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdMembersCompanion(
                id: id,
                householdId: householdId,
                userId: userId,
                displayName: displayName,
                role: role,
                joinedAt: joinedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String householdId,
                required String userId,
                required String displayName,
                required String role,
                Value<DateTime> joinedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdMembersCompanion.insert(
                id: id,
                householdId: householdId,
                userId: userId,
                displayName: displayName,
                role: role,
                joinedAt: joinedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                isDirty: isDirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HouseholdMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({householdId = false}) {
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
                    if (householdId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.householdId,
                                referencedTable:
                                    $$HouseholdMembersTableReferences
                                        ._householdIdTable(db),
                                referencedColumn:
                                    $$HouseholdMembersTableReferences
                                        ._householdIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$HouseholdMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdMembersTable,
      HouseholdMember,
      $$HouseholdMembersTableFilterComposer,
      $$HouseholdMembersTableOrderingComposer,
      $$HouseholdMembersTableAnnotationComposer,
      $$HouseholdMembersTableCreateCompanionBuilder,
      $$HouseholdMembersTableUpdateCompanionBuilder,
      (HouseholdMember, $$HouseholdMembersTableReferences),
      HouseholdMember,
      PrefetchHooks Function({bool householdId})
    >;
typedef $$AuditEntriesTableCreateCompanionBuilder =
    AuditEntriesCompanion Function({
      Value<String> id,
      required String scopeKind,
      required String scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      required String entityType,
      required String entityId,
      required String action,
      required String summary,
      Value<String?> actorName,
      Value<int> rowid,
    });
typedef $$AuditEntriesTableUpdateCompanionBuilder =
    AuditEntriesCompanion Function({
      Value<String> id,
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> action,
      Value<String> summary,
      Value<String?> actorName,
      Value<int> rowid,
    });

class $$AuditEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableFilterComposer({
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

  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorName => $composableBuilder(
    column: $table.actorName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorName => $composableBuilder(
    column: $table.actorName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditEntriesTable> {
  $$AuditEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get actorName =>
      $composableBuilder(column: $table.actorName, builder: (column) => column);
}

class $$AuditEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditEntriesTable,
          AuditEntry,
          $$AuditEntriesTableFilterComposer,
          $$AuditEntriesTableOrderingComposer,
          $$AuditEntriesTableAnnotationComposer,
          $$AuditEntriesTableCreateCompanionBuilder,
          $$AuditEntriesTableUpdateCompanionBuilder,
          (
            AuditEntry,
            BaseReferences<_$AppDatabase, $AuditEntriesTable, AuditEntry>,
          ),
          AuditEntry,
          PrefetchHooks Function()
        > {
  $$AuditEntriesTableTableManager(_$AppDatabase db, $AuditEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String?> actorName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEntriesCompanion(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                entityType: entityType,
                entityId: entityId,
                action: action,
                summary: summary,
                actorName: actorName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String scopeKind,
                required String scopeId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required String entityType,
                required String entityId,
                required String action,
                required String summary,
                Value<String?> actorName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEntriesCompanion.insert(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                entityType: entityType,
                entityId: entityId,
                action: action,
                summary: summary,
                actorName: actorName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditEntriesTable,
      AuditEntry,
      $$AuditEntriesTableFilterComposer,
      $$AuditEntriesTableOrderingComposer,
      $$AuditEntriesTableAnnotationComposer,
      $$AuditEntriesTableCreateCompanionBuilder,
      $$AuditEntriesTableUpdateCompanionBuilder,
      (
        AuditEntry,
        BaseReferences<_$AppDatabase, $AuditEntriesTable, AuditEntry>,
      ),
      AuditEntry,
      PrefetchHooks Function()
    >;
typedef $$StorageLocationsTableCreateCompanionBuilder =
    StorageLocationsCompanion Function({
      Value<String> id,
      required String scopeKind,
      required String scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      required String name,
      Value<String> iconKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$StorageLocationsTableUpdateCompanionBuilder =
    StorageLocationsCompanion Function({
      Value<String> id,
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String> name,
      Value<String> iconKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$StorageLocationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $StorageLocationsTable, StorageLocation> {
  $$StorageLocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$InventoryItemsTable, List<InventoryItem>>
  _inventoryItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoryItems,
    aliasName: 'storage_locations__id__inventory_items__location_id',
  );

  $$InventoryItemsTableProcessedTableManager get inventoryItemsRefs {
    final manager = $$InventoryItemsTableTableManager(
      $_db,
      $_db.inventoryItems,
    ).filter((f) => f.locationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inventoryItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StorageLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $StorageLocationsTable> {
  $$StorageLocationsTableFilterComposer({
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

  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> inventoryItemsRefs(
    Expression<bool> Function($$InventoryItemsTableFilterComposer f) f,
  ) {
    final $$InventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.locationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StorageLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $StorageLocationsTable> {
  $$StorageLocationsTableOrderingComposer({
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

  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StorageLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StorageLocationsTable> {
  $$StorageLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> inventoryItemsRefs<T extends Object>(
    Expression<T> Function($$InventoryItemsTableAnnotationComposer a) f,
  ) {
    final $$InventoryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.locationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StorageLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StorageLocationsTable,
          StorageLocation,
          $$StorageLocationsTableFilterComposer,
          $$StorageLocationsTableOrderingComposer,
          $$StorageLocationsTableAnnotationComposer,
          $$StorageLocationsTableCreateCompanionBuilder,
          $$StorageLocationsTableUpdateCompanionBuilder,
          (StorageLocation, $$StorageLocationsTableReferences),
          StorageLocation,
          PrefetchHooks Function({bool inventoryItemsRefs})
        > {
  $$StorageLocationsTableTableManager(
    _$AppDatabase db,
    $StorageLocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StorageLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StorageLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StorageLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageLocationsCompanion(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                name: name,
                iconKey: iconKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String scopeKind,
                required String scopeId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required String name,
                Value<String> iconKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageLocationsCompanion.insert(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                name: name,
                iconKey: iconKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StorageLocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (inventoryItemsRefs) db.inventoryItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (inventoryItemsRefs)
                    await $_getPrefetchedData<
                      StorageLocation,
                      $StorageLocationsTable,
                      InventoryItem
                    >(
                      currentTable: table,
                      referencedTable: $$StorageLocationsTableReferences
                          ._inventoryItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StorageLocationsTableReferences(
                            db,
                            table,
                            p0,
                          ).inventoryItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.locationId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StorageLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StorageLocationsTable,
      StorageLocation,
      $$StorageLocationsTableFilterComposer,
      $$StorageLocationsTableOrderingComposer,
      $$StorageLocationsTableAnnotationComposer,
      $$StorageLocationsTableCreateCompanionBuilder,
      $$StorageLocationsTableUpdateCompanionBuilder,
      (StorageLocation, $$StorageLocationsTableReferences),
      StorageLocation,
      PrefetchHooks Function({bool inventoryItemsRefs})
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      required String scopeKind,
      required String scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String?> barcode,
      required String name,
      Value<String?> brand,
      Value<String?> imageUrl,
      Value<String?> category,
      Value<String> defaultUnit,
      Value<double> defaultQuantity,
      Value<String> source,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String?> barcode,
      Value<String> name,
      Value<String?> brand,
      Value<String?> imageUrl,
      Value<String?> category,
      Value<String> defaultUnit,
      Value<double> defaultQuantity,
      Value<String> source,
      Value<int> rowid,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InventoryItemsTable, List<InventoryItem>>
  _inventoryItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inventoryItems,
    aliasName: 'products__id__inventory_items__product_id',
  );

  $$InventoryItemsTableProcessedTableManager get inventoryItemsRefs {
    final manager = $$InventoryItemsTableTableManager(
      $_db,
      $_db.inventoryItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inventoryItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
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

  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultQuantity => $composableBuilder(
    column: $table.defaultQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> inventoryItemsRefs(
    Expression<bool> Function($$InventoryItemsTableFilterComposer f) f,
  ) {
    final $$InventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultQuantity => $composableBuilder(
    column: $table.defaultQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get defaultQuantity => $composableBuilder(
    column: $table.defaultQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  Expression<T> inventoryItemsRefs<T extends Object>(
    Expression<T> Function($$InventoryItemsTableAnnotationComposer a) f,
  ) {
    final $$InventoryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({bool inventoryItemsRefs})
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> defaultUnit = const Value.absent(),
                Value<double> defaultQuantity = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                barcode: barcode,
                name: name,
                brand: brand,
                imageUrl: imageUrl,
                category: category,
                defaultUnit: defaultUnit,
                defaultQuantity: defaultQuantity,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String scopeKind,
                required String scopeId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> defaultUnit = const Value.absent(),
                Value<double> defaultQuantity = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                barcode: barcode,
                name: name,
                brand: brand,
                imageUrl: imageUrl,
                category: category,
                defaultUnit: defaultUnit,
                defaultQuantity: defaultQuantity,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({inventoryItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (inventoryItemsRefs) db.inventoryItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (inventoryItemsRefs)
                    await $_getPrefetchedData<
                      Product,
                      $ProductsTable,
                      InventoryItem
                    >(
                      currentTable: table,
                      referencedTable: $$ProductsTableReferences
                          ._inventoryItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProductsTableReferences(
                        db,
                        table,
                        p0,
                      ).inventoryItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.productId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({bool inventoryItemsRefs})
    >;
typedef $$InventoryItemsTableCreateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<String> id,
      required String scopeKind,
      required String scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String?> productId,
      Value<String?> locationId,
      required String name,
      Value<String?> barcode,
      Value<double> quantity,
      Value<String> unit,
      Value<DateTime?> expiresAt,
      Value<double?> minQuantity,
      Value<String?> note,
      Value<bool> remindOnExpiry,
      Value<int> rowid,
    });
typedef $$InventoryItemsTableUpdateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<String> id,
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String?> productId,
      Value<String?> locationId,
      Value<String> name,
      Value<String?> barcode,
      Value<double> quantity,
      Value<String> unit,
      Value<DateTime?> expiresAt,
      Value<double?> minQuantity,
      Value<String?> note,
      Value<bool> remindOnExpiry,
      Value<int> rowid,
    });

final class $$InventoryItemsTableReferences
    extends BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem> {
  $$InventoryItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('inventory_items__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StorageLocationsTable _locationIdTable(_$AppDatabase db) => db
      .storageLocations
      .createAlias('inventory_items__location_id__storage_locations__id');

  $$StorageLocationsTableProcessedTableManager? get locationId {
    final $_column = $_itemColumn<String>('location_id');
    if ($_column == null) return null;
    final manager = $$StorageLocationsTableTableManager(
      $_db,
      $_db.storageLocations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_locationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShoppingItemsTable, List<ShoppingItem>>
  _shoppingItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shoppingItems,
    aliasName: 'inventory_items__id__shopping_items__inventory_item_id',
  );

  $$ShoppingItemsTableProcessedTableManager get shoppingItemsRefs {
    final manager = $$ShoppingItemsTableTableManager($_db, $_db.shoppingItems)
        .filter(
          (f) => f.inventoryItemId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_shoppingItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
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

  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindOnExpiry => $composableBuilder(
    column: $table.remindOnExpiry,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StorageLocationsTableFilterComposer get locationId {
    final $$StorageLocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.storageLocations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StorageLocationsTableFilterComposer(
            $db: $db,
            $table: $db.storageLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shoppingItemsRefs(
    Expression<bool> Function($$ShoppingItemsTableFilterComposer f) f,
  ) {
    final $$ShoppingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.inventoryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
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

  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindOnExpiry => $composableBuilder(
    column: $table.remindOnExpiry,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StorageLocationsTableOrderingComposer get locationId {
    final $$StorageLocationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.storageLocations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StorageLocationsTableOrderingComposer(
            $db: $db,
            $table: $db.storageLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<double> get minQuantity => $composableBuilder(
    column: $table.minQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get remindOnExpiry => $composableBuilder(
    column: $table.remindOnExpiry,
    builder: (column) => column,
  );

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StorageLocationsTableAnnotationComposer get locationId {
    final $$StorageLocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.storageLocations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StorageLocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.storageLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shoppingItemsRefs<T extends Object>(
    Expression<T> Function($$ShoppingItemsTableAnnotationComposer a) f,
  ) {
    final $$ShoppingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.inventoryItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InventoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryItemsTable,
          InventoryItem,
          $$InventoryItemsTableFilterComposer,
          $$InventoryItemsTableOrderingComposer,
          $$InventoryItemsTableAnnotationComposer,
          $$InventoryItemsTableCreateCompanionBuilder,
          $$InventoryItemsTableUpdateCompanionBuilder,
          (InventoryItem, $$InventoryItemsTableReferences),
          InventoryItem,
          PrefetchHooks Function({
            bool productId,
            bool locationId,
            bool shoppingItemsRefs,
          })
        > {
  $$InventoryItemsTableTableManager(
    _$AppDatabase db,
    $InventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> locationId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<double?> minQuantity = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> remindOnExpiry = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                productId: productId,
                locationId: locationId,
                name: name,
                barcode: barcode,
                quantity: quantity,
                unit: unit,
                expiresAt: expiresAt,
                minQuantity: minQuantity,
                note: note,
                remindOnExpiry: remindOnExpiry,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String scopeKind,
                required String scopeId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> locationId = const Value.absent(),
                required String name,
                Value<String?> barcode = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<double?> minQuantity = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> remindOnExpiry = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion.insert(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                productId: productId,
                locationId: locationId,
                name: name,
                barcode: barcode,
                quantity: quantity,
                unit: unit,
                expiresAt: expiresAt,
                minQuantity: minQuantity,
                note: note,
                remindOnExpiry: remindOnExpiry,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InventoryItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                productId = false,
                locationId = false,
                shoppingItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shoppingItemsRefs) db.shoppingItems,
                  ],
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
                        if (productId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.productId,
                                    referencedTable:
                                        $$InventoryItemsTableReferences
                                            ._productIdTable(db),
                                    referencedColumn:
                                        $$InventoryItemsTableReferences
                                            ._productIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (locationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.locationId,
                                    referencedTable:
                                        $$InventoryItemsTableReferences
                                            ._locationIdTable(db),
                                    referencedColumn:
                                        $$InventoryItemsTableReferences
                                            ._locationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shoppingItemsRefs)
                        await $_getPrefetchedData<
                          InventoryItem,
                          $InventoryItemsTable,
                          ShoppingItem
                        >(
                          currentTable: table,
                          referencedTable: $$InventoryItemsTableReferences
                              ._shoppingItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InventoryItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).shoppingItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.inventoryItemId == item.id,
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

typedef $$InventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryItemsTable,
      InventoryItem,
      $$InventoryItemsTableFilterComposer,
      $$InventoryItemsTableOrderingComposer,
      $$InventoryItemsTableAnnotationComposer,
      $$InventoryItemsTableCreateCompanionBuilder,
      $$InventoryItemsTableUpdateCompanionBuilder,
      (InventoryItem, $$InventoryItemsTableReferences),
      InventoryItem,
      PrefetchHooks Function({
        bool productId,
        bool locationId,
        bool shoppingItemsRefs,
      })
    >;
typedef $$ShoppingListsTableCreateCompanionBuilder =
    ShoppingListsCompanion Function({
      Value<String> id,
      required String scopeKind,
      required String scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      required String name,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ShoppingListsTableUpdateCompanionBuilder =
    ShoppingListsCompanion Function({
      Value<String> id,
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$ShoppingListsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingListsTable, ShoppingList> {
  $$ShoppingListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ShoppingItemsTable, List<ShoppingItem>>
  _shoppingItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shoppingItems,
    aliasName: 'shopping_lists__id__shopping_items__list_id',
  );

  $$ShoppingItemsTableProcessedTableManager get shoppingItemsRefs {
    final manager = $$ShoppingItemsTableTableManager(
      $_db,
      $_db.shoppingItems,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shoppingItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShoppingListsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableFilterComposer({
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

  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shoppingItemsRefs(
    Expression<bool> Function($$ShoppingItemsTableFilterComposer f) f,
  ) {
    final $$ShoppingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableOrderingComposer({
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

  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> shoppingItemsRefs<T extends Object>(
    Expression<T> Function($$ShoppingItemsTableAnnotationComposer a) f,
  ) {
    final $$ShoppingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListsTable,
          ShoppingList,
          $$ShoppingListsTableFilterComposer,
          $$ShoppingListsTableOrderingComposer,
          $$ShoppingListsTableAnnotationComposer,
          $$ShoppingListsTableCreateCompanionBuilder,
          $$ShoppingListsTableUpdateCompanionBuilder,
          (ShoppingList, $$ShoppingListsTableReferences),
          ShoppingList,
          PrefetchHooks Function({bool shoppingItemsRefs})
        > {
  $$ShoppingListsTableTableManager(_$AppDatabase db, $ShoppingListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListsCompanion(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String scopeKind,
                required String scopeId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListsCompanion.insert(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShoppingListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shoppingItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (shoppingItemsRefs) db.shoppingItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shoppingItemsRefs)
                    await $_getPrefetchedData<
                      ShoppingList,
                      $ShoppingListsTable,
                      ShoppingItem
                    >(
                      currentTable: table,
                      referencedTable: $$ShoppingListsTableReferences
                          ._shoppingItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ShoppingListsTableReferences(
                            db,
                            table,
                            p0,
                          ).shoppingItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ShoppingListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListsTable,
      ShoppingList,
      $$ShoppingListsTableFilterComposer,
      $$ShoppingListsTableOrderingComposer,
      $$ShoppingListsTableAnnotationComposer,
      $$ShoppingListsTableCreateCompanionBuilder,
      $$ShoppingListsTableUpdateCompanionBuilder,
      (ShoppingList, $$ShoppingListsTableReferences),
      ShoppingList,
      PrefetchHooks Function({bool shoppingItemsRefs})
    >;
typedef $$ShoppingItemsTableCreateCompanionBuilder =
    ShoppingItemsCompanion Function({
      Value<String> id,
      required String scopeKind,
      required String scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      required String listId,
      required String name,
      Value<double> quantity,
      Value<String> unit,
      Value<String> category,
      Value<String?> note,
      Value<bool> isChecked,
      Value<DateTime?> checkedAt,
      Value<String?> checkedBy,
      Value<String?> inventoryItemId,
      Value<String?> barcode,
      Value<int> rowid,
    });
typedef $$ShoppingItemsTableUpdateCompanionBuilder =
    ShoppingItemsCompanion Function({
      Value<String> id,
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String> listId,
      Value<String> name,
      Value<double> quantity,
      Value<String> unit,
      Value<String> category,
      Value<String?> note,
      Value<bool> isChecked,
      Value<DateTime?> checkedAt,
      Value<String?> checkedBy,
      Value<String?> inventoryItemId,
      Value<String?> barcode,
      Value<int> rowid,
    });

final class $$ShoppingItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingItemsTable, ShoppingItem> {
  $$ShoppingItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShoppingListsTable _listIdTable(_$AppDatabase db) => db.shoppingLists
      .createAlias('shopping_items__list_id__shopping_lists__id');

  $$ShoppingListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$ShoppingListsTableTableManager(
      $_db,
      $_db.shoppingLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $InventoryItemsTable _inventoryItemIdTable(_$AppDatabase db) => db
      .inventoryItems
      .createAlias('shopping_items__inventory_item_id__inventory_items__id');

  $$InventoryItemsTableProcessedTableManager? get inventoryItemId {
    final $_column = $_itemColumn<String>('inventory_item_id');
    if ($_column == null) return null;
    final manager = $$InventoryItemsTableTableManager(
      $_db,
      $_db.inventoryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_inventoryItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShoppingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableFilterComposer({
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

  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkedBy => $composableBuilder(
    column: $table.checkedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  $$ShoppingListsTableFilterComposer get listId {
    final $$ShoppingListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$InventoryItemsTableFilterComposer get inventoryItemId {
    final $$InventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableOrderingComposer({
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

  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkedBy => $composableBuilder(
    column: $table.checkedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShoppingListsTableOrderingComposer get listId {
    final $$ShoppingListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableOrderingComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$InventoryItemsTableOrderingComposer get inventoryItemId {
    final $$InventoryItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableOrderingComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<DateTime> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);

  GeneratedColumn<String> get checkedBy =>
      $composableBuilder(column: $table.checkedBy, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  $$ShoppingListsTableAnnotationComposer get listId {
    final $$ShoppingListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$InventoryItemsTableAnnotationComposer get inventoryItemId {
    final $$InventoryItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.inventoryItemId,
      referencedTable: $db.inventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InventoryItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.inventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingItemsTable,
          ShoppingItem,
          $$ShoppingItemsTableFilterComposer,
          $$ShoppingItemsTableOrderingComposer,
          $$ShoppingItemsTableAnnotationComposer,
          $$ShoppingItemsTableCreateCompanionBuilder,
          $$ShoppingItemsTableUpdateCompanionBuilder,
          (ShoppingItem, $$ShoppingItemsTableReferences),
          ShoppingItem,
          PrefetchHooks Function({bool listId, bool inventoryItemId})
        > {
  $$ShoppingItemsTableTableManager(_$AppDatabase db, $ShoppingItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<DateTime?> checkedAt = const Value.absent(),
                Value<String?> checkedBy = const Value.absent(),
                Value<String?> inventoryItemId = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingItemsCompanion(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                listId: listId,
                name: name,
                quantity: quantity,
                unit: unit,
                category: category,
                note: note,
                isChecked: isChecked,
                checkedAt: checkedAt,
                checkedBy: checkedBy,
                inventoryItemId: inventoryItemId,
                barcode: barcode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String scopeKind,
                required String scopeId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required String listId,
                required String name,
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<DateTime?> checkedAt = const Value.absent(),
                Value<String?> checkedBy = const Value.absent(),
                Value<String?> inventoryItemId = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingItemsCompanion.insert(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                listId: listId,
                name: name,
                quantity: quantity,
                unit: unit,
                category: category,
                note: note,
                isChecked: isChecked,
                checkedAt: checkedAt,
                checkedBy: checkedBy,
                inventoryItemId: inventoryItemId,
                barcode: barcode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShoppingItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false, inventoryItemId = false}) {
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
                    if (listId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.listId,
                                referencedTable: $$ShoppingItemsTableReferences
                                    ._listIdTable(db),
                                referencedColumn: $$ShoppingItemsTableReferences
                                    ._listIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (inventoryItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.inventoryItemId,
                                referencedTable: $$ShoppingItemsTableReferences
                                    ._inventoryItemIdTable(db),
                                referencedColumn: $$ShoppingItemsTableReferences
                                    ._inventoryItemIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$ShoppingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingItemsTable,
      ShoppingItem,
      $$ShoppingItemsTableFilterComposer,
      $$ShoppingItemsTableOrderingComposer,
      $$ShoppingItemsTableAnnotationComposer,
      $$ShoppingItemsTableCreateCompanionBuilder,
      $$ShoppingItemsTableUpdateCompanionBuilder,
      (ShoppingItem, $$ShoppingItemsTableReferences),
      ShoppingItem,
      PrefetchHooks Function({bool listId, bool inventoryItemId})
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      required String scopeKind,
      required String scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String> title,
      Value<String> body,
      Value<bool> isChecklist,
      Value<bool> isPinned,
      Value<String> colorKey,
      Value<String> tags,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String> title,
      Value<String> body,
      Value<bool> isChecklist,
      Value<bool> isPinned,
      Value<String> colorKey,
      Value<String> tags,
      Value<int> rowid,
    });

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, Note> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NoteChecklistItemsTable, List<NoteChecklistItem>>
  _noteChecklistItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.noteChecklistItems,
        aliasName: 'notes__id__note_checklist_items__note_id',
      );

  $$NoteChecklistItemsTableProcessedTableManager get noteChecklistItemsRefs {
    final manager = $$NoteChecklistItemsTableTableManager(
      $_db,
      $_db.noteChecklistItems,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _noteChecklistItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isChecklist => $composableBuilder(
    column: $table.isChecklist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> noteChecklistItemsRefs(
    Expression<bool> Function($$NoteChecklistItemsTableFilterComposer f) f,
  ) {
    final $$NoteChecklistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteChecklistItems,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteChecklistItemsTableFilterComposer(
            $db: $db,
            $table: $db.noteChecklistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isChecklist => $composableBuilder(
    column: $table.isChecklist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorKey => $composableBuilder(
    column: $table.colorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get isChecklist => $composableBuilder(
    column: $table.isChecklist,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<String> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  Expression<T> noteChecklistItemsRefs<T extends Object>(
    Expression<T> Function($$NoteChecklistItemsTableAnnotationComposer a) f,
  ) {
    final $$NoteChecklistItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.noteChecklistItems,
          getReferencedColumn: (t) => t.noteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NoteChecklistItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.noteChecklistItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, $$NotesTableReferences),
          Note,
          PrefetchHooks Function({bool noteChecklistItemsRefs})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<bool> isChecklist = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String> colorKey = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                title: title,
                body: body,
                isChecklist: isChecklist,
                isPinned: isPinned,
                colorKey: colorKey,
                tags: tags,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String scopeKind,
                required String scopeId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<bool> isChecklist = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String> colorKey = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                title: title,
                body: body,
                isChecklist: isChecklist,
                isPinned: isPinned,
                colorKey: colorKey,
                tags: tags,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NotesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({noteChecklistItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (noteChecklistItemsRefs) db.noteChecklistItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (noteChecklistItemsRefs)
                    await $_getPrefetchedData<
                      Note,
                      $NotesTable,
                      NoteChecklistItem
                    >(
                      currentTable: table,
                      referencedTable: $$NotesTableReferences
                          ._noteChecklistItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $$NotesTableReferences(
                        db,
                        table,
                        p0,
                      ).noteChecklistItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.noteId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, $$NotesTableReferences),
      Note,
      PrefetchHooks Function({bool noteChecklistItemsRefs})
    >;
typedef $$NoteChecklistItemsTableCreateCompanionBuilder =
    NoteChecklistItemsCompanion Function({
      Value<String> id,
      required String scopeKind,
      required String scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      required String noteId,
      required String content,
      Value<bool> isDone,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$NoteChecklistItemsTableUpdateCompanionBuilder =
    NoteChecklistItemsCompanion Function({
      Value<String> id,
      Value<String> scopeKind,
      Value<String> scopeId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> createdBy,
      Value<String?> updatedBy,
      Value<bool> isDirty,
      Value<String> noteId,
      Value<String> content,
      Value<bool> isDone,
      Value<int> position,
      Value<int> rowid,
    });

final class $$NoteChecklistItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $NoteChecklistItemsTable,
          NoteChecklistItem
        > {
  $$NoteChecklistItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotesTable _noteIdTable(_$AppDatabase db) =>
      db.notes.createAlias('note_checklist_items__note_id__notes__id');

  $$NotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NoteChecklistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $NoteChecklistItemsTable> {
  $$NoteChecklistItemsTableFilterComposer({
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

  ColumnFilters<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$NotesTableFilterComposer get noteId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteChecklistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteChecklistItemsTable> {
  $$NoteChecklistItemsTableOrderingComposer({
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

  ColumnOrderings<String> get scopeKind => $composableBuilder(
    column: $table.scopeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
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

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotesTableOrderingComposer get noteId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteChecklistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteChecklistItemsTable> {
  $$NoteChecklistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scopeKind =>
      $composableBuilder(column: $table.scopeKind, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$NotesTableAnnotationComposer get noteId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteChecklistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteChecklistItemsTable,
          NoteChecklistItem,
          $$NoteChecklistItemsTableFilterComposer,
          $$NoteChecklistItemsTableOrderingComposer,
          $$NoteChecklistItemsTableAnnotationComposer,
          $$NoteChecklistItemsTableCreateCompanionBuilder,
          $$NoteChecklistItemsTableUpdateCompanionBuilder,
          (NoteChecklistItem, $$NoteChecklistItemsTableReferences),
          NoteChecklistItem,
          PrefetchHooks Function({bool noteId})
        > {
  $$NoteChecklistItemsTableTableManager(
    _$AppDatabase db,
    $NoteChecklistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteChecklistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteChecklistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteChecklistItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scopeKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteChecklistItemsCompanion(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                noteId: noteId,
                content: content,
                isDone: isDone,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String scopeKind,
                required String scopeId,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<String?> updatedBy = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                required String noteId,
                required String content,
                Value<bool> isDone = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteChecklistItemsCompanion.insert(
                id: id,
                scopeKind: scopeKind,
                scopeId: scopeId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdBy: createdBy,
                updatedBy: updatedBy,
                isDirty: isDirty,
                noteId: noteId,
                content: content,
                isDone: isDone,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NoteChecklistItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
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
                    if (noteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.noteId,
                                referencedTable:
                                    $$NoteChecklistItemsTableReferences
                                        ._noteIdTable(db),
                                referencedColumn:
                                    $$NoteChecklistItemsTableReferences
                                        ._noteIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$NoteChecklistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteChecklistItemsTable,
      NoteChecklistItem,
      $$NoteChecklistItemsTableFilterComposer,
      $$NoteChecklistItemsTableOrderingComposer,
      $$NoteChecklistItemsTableAnnotationComposer,
      $$NoteChecklistItemsTableCreateCompanionBuilder,
      $$NoteChecklistItemsTableUpdateCompanionBuilder,
      (NoteChecklistItem, $$NoteChecklistItemsTableReferences),
      NoteChecklistItem,
      PrefetchHooks Function({bool noteId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db, _db.households);
  $$HouseholdMembersTableTableManager get householdMembers =>
      $$HouseholdMembersTableTableManager(_db, _db.householdMembers);
  $$AuditEntriesTableTableManager get auditEntries =>
      $$AuditEntriesTableTableManager(_db, _db.auditEntries);
  $$StorageLocationsTableTableManager get storageLocations =>
      $$StorageLocationsTableTableManager(_db, _db.storageLocations);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db, _db.shoppingLists);
  $$ShoppingItemsTableTableManager get shoppingItems =>
      $$ShoppingItemsTableTableManager(_db, _db.shoppingItems);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$NoteChecklistItemsTableTableManager get noteChecklistItems =>
      $$NoteChecklistItemsTableTableManager(_db, _db.noteChecklistItems);
}
