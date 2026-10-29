// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateOfBirthMeta = const VerificationMeta(
    'dateOfBirth',
  );
  @override
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
    'date_of_birth',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingCompleteMeta =
      const VerificationMeta('onboardingComplete');
  @override
  late final GeneratedColumn<bool> onboardingComplete = GeneratedColumn<bool>(
    'onboarding_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    currencyCode,
    locale,
    timezone,
    dateOfBirth,
    onboardingComplete,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
        _dateOfBirthMeta,
        dateOfBirth.isAcceptableOrUnknown(
          data['date_of_birth']!,
          _dateOfBirthMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_complete')) {
      context.handle(
        _onboardingCompleteMeta,
        onboardingComplete.isAcceptableOrUnknown(
          data['onboarding_complete']!,
          _onboardingCompleteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      dateOfBirth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_of_birth'],
      ),
      onboardingComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_complete'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final String displayName;
  final String currencyCode;
  final String locale;
  final String timezone;
  final String? dateOfBirth;
  final bool onboardingComplete;
  final int createdAt;
  final int updatedAt;
  const ProfileRow({
    required this.id,
    required this.displayName,
    required this.currencyCode,
    required this.locale,
    required this.timezone,
    this.dateOfBirth,
    required this.onboardingComplete,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['currency_code'] = Variable<String>(currencyCode);
    map['locale'] = Variable<String>(locale);
    map['timezone'] = Variable<String>(timezone);
    if (!nullToAbsent || dateOfBirth != null) {
      map['date_of_birth'] = Variable<String>(dateOfBirth);
    }
    map['onboarding_complete'] = Variable<bool>(onboardingComplete);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      currencyCode: Value(currencyCode),
      locale: Value(locale),
      timezone: Value(timezone),
      dateOfBirth: dateOfBirth == null && nullToAbsent
          ? const Value.absent()
          : Value(dateOfBirth),
      onboardingComplete: Value(onboardingComplete),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      locale: serializer.fromJson<String>(json['locale']),
      timezone: serializer.fromJson<String>(json['timezone']),
      dateOfBirth: serializer.fromJson<String?>(json['dateOfBirth']),
      onboardingComplete: serializer.fromJson<bool>(json['onboardingComplete']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'locale': serializer.toJson<String>(locale),
      'timezone': serializer.toJson<String>(timezone),
      'dateOfBirth': serializer.toJson<String?>(dateOfBirth),
      'onboardingComplete': serializer.toJson<bool>(onboardingComplete),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProfileRow copyWith({
    int? id,
    String? displayName,
    String? currencyCode,
    String? locale,
    String? timezone,
    Value<String?> dateOfBirth = const Value.absent(),
    bool? onboardingComplete,
    int? createdAt,
    int? updatedAt,
  }) => ProfileRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    currencyCode: currencyCode ?? this.currencyCode,
    locale: locale ?? this.locale,
    timezone: timezone ?? this.timezone,
    dateOfBirth: dateOfBirth.present ? dateOfBirth.value : this.dateOfBirth,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      locale: data.locale.present ? data.locale.value : this.locale,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      dateOfBirth: data.dateOfBirth.present
          ? data.dateOfBirth.value
          : this.dateOfBirth,
      onboardingComplete: data.onboardingComplete.present
          ? data.onboardingComplete.value
          : this.onboardingComplete,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('locale: $locale, ')
          ..write('timezone: $timezone, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    currencyCode,
    locale,
    timezone,
    dateOfBirth,
    onboardingComplete,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.currencyCode == this.currencyCode &&
          other.locale == this.locale &&
          other.timezone == this.timezone &&
          other.dateOfBirth == this.dateOfBirth &&
          other.onboardingComplete == this.onboardingComplete &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String> currencyCode;
  final Value<String> locale;
  final Value<String> timezone;
  final Value<String?> dateOfBirth;
  final Value<bool> onboardingComplete;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.locale = const Value.absent(),
    this.timezone = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    required String currencyCode,
    required String locale,
    required String timezone,
    this.dateOfBirth = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : displayName = Value(displayName),
       currencyCode = Value(currencyCode),
       locale = Value(locale),
       timezone = Value(timezone),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileRow> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? currencyCode,
    Expression<String>? locale,
    Expression<String>? timezone,
    Expression<String>? dateOfBirth,
    Expression<bool>? onboardingComplete,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (locale != null) 'locale': locale,
      if (timezone != null) 'timezone': timezone,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (onboardingComplete != null) 'onboarding_complete': onboardingComplete,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String>? currencyCode,
    Value<String>? locale,
    Value<String>? timezone,
    Value<String?>? dateOfBirth,
    Value<bool>? onboardingComplete,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      currencyCode: currencyCode ?? this.currencyCode,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    if (onboardingComplete.present) {
      map['onboarding_complete'] = Variable<bool>(onboardingComplete.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('locale: $locale, ')
          ..write('timezone: $timezone, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  final int updatedAt;
  const SettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SettingRow copyWith({String? key, String? value, int? updatedAt}) =>
      SettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncomeSourcesTable extends IncomeSources
    with TableInfo<$IncomeSourcesTable, IncomeSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomeSourcesTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customCategoryMeta = const VerificationMeta(
    'customCategory',
  );
  @override
  late final GeneratedColumn<String> customCategory = GeneratedColumn<String>(
    'custom_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accrualPolicyMeta = const VerificationMeta(
    'accrualPolicy',
  );
  @override
  late final GeneratedColumn<String> accrualPolicy = GeneratedColumn<String>(
    'accrual_policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workWeekdayMaskMeta = const VerificationMeta(
    'workWeekdayMask',
  );
  @override
  late final GeneratedColumn<int> workWeekdayMask = GeneratedColumn<int>(
    'work_weekday_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workStartMinuteMeta = const VerificationMeta(
    'workStartMinute',
  );
  @override
  late final GeneratedColumn<int> workStartMinute = GeneratedColumn<int>(
    'work_start_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workEndMinuteMeta = const VerificationMeta(
    'workEndMinute',
  );
  @override
  late final GeneratedColumn<int> workEndMinute = GeneratedColumn<int>(
    'work_end_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payRuleMeta = const VerificationMeta(
    'payRule',
  );
  @override
  late final GeneratedColumn<String> payRule = GeneratedColumn<String>(
    'pay_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payDayMeta = const VerificationMeta('payDay');
  @override
  late final GeneratedColumn<int> payDay = GeneratedColumn<int>(
    'pay_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payOffsetMonthsMeta = const VerificationMeta(
    'payOffsetMonths',
  );
  @override
  late final GeneratedColumn<int> payOffsetMonths = GeneratedColumn<int>(
    'pay_offset_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekendAdjustMeta = const VerificationMeta(
    'weekendAdjust',
  );
  @override
  late final GeneratedColumn<String> weekendAdjust = GeneratedColumn<String>(
    'weekend_adjust',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedPayDateMeta = const VerificationMeta(
    'expectedPayDate',
  );
  @override
  late final GeneratedColumn<String> expectedPayDate = GeneratedColumn<String>(
    'expected_pay_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedTotalMinorMeta = const VerificationMeta(
    'fixedTotalMinor',
  );
  @override
  late final GeneratedColumn<int> fixedTotalMinor = GeneratedColumn<int>(
    'fixed_total_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedTotalAccrualMeta = const VerificationMeta(
    'fixedTotalAccrual',
  );
  @override
  late final GeneratedColumn<String> fixedTotalAccrual =
      GeneratedColumn<String>(
        'fixed_total_accrual',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _forecastMethodMeta = const VerificationMeta(
    'forecastMethod',
  );
  @override
  late final GeneratedColumn<String> forecastMethod = GeneratedColumn<String>(
    'forecast_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _employerMeta = const VerificationMeta(
    'employer',
  );
  @override
  late final GeneratedColumn<String> employer = GeneratedColumn<String>(
    'employer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _takeHomeMinorMeta = const VerificationMeta(
    'takeHomeMinor',
  );
  @override
  late final GeneratedColumn<int> takeHomeMinor = GeneratedColumn<int>(
    'take_home_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSampleMeta = const VerificationMeta(
    'isSample',
  );
  @override
  late final GeneratedColumn<bool> isSample = GeneratedColumn<bool>(
    'is_sample',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sample" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    category,
    customCategory,
    status,
    currencyCode,
    startDate,
    endDate,
    accrualPolicy,
    workWeekdayMask,
    workStartMinute,
    workEndMinute,
    payRule,
    payDay,
    payOffsetMonths,
    weekendAdjust,
    expectedPayDate,
    fixedTotalMinor,
    fixedTotalAccrual,
    forecastMethod,
    employer,
    takeHomeMinor,
    notes,
    colorIndex,
    isSample,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'income_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncomeSourceRow> instance, {
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('custom_category')) {
      context.handle(
        _customCategoryMeta,
        customCategory.isAcceptableOrUnknown(
          data['custom_category']!,
          _customCategoryMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('accrual_policy')) {
      context.handle(
        _accrualPolicyMeta,
        accrualPolicy.isAcceptableOrUnknown(
          data['accrual_policy']!,
          _accrualPolicyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accrualPolicyMeta);
    }
    if (data.containsKey('work_weekday_mask')) {
      context.handle(
        _workWeekdayMaskMeta,
        workWeekdayMask.isAcceptableOrUnknown(
          data['work_weekday_mask']!,
          _workWeekdayMaskMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workWeekdayMaskMeta);
    }
    if (data.containsKey('work_start_minute')) {
      context.handle(
        _workStartMinuteMeta,
        workStartMinute.isAcceptableOrUnknown(
          data['work_start_minute']!,
          _workStartMinuteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workStartMinuteMeta);
    }
    if (data.containsKey('work_end_minute')) {
      context.handle(
        _workEndMinuteMeta,
        workEndMinute.isAcceptableOrUnknown(
          data['work_end_minute']!,
          _workEndMinuteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workEndMinuteMeta);
    }
    if (data.containsKey('pay_rule')) {
      context.handle(
        _payRuleMeta,
        payRule.isAcceptableOrUnknown(data['pay_rule']!, _payRuleMeta),
      );
    } else if (isInserting) {
      context.missing(_payRuleMeta);
    }
    if (data.containsKey('pay_day')) {
      context.handle(
        _payDayMeta,
        payDay.isAcceptableOrUnknown(data['pay_day']!, _payDayMeta),
      );
    } else if (isInserting) {
      context.missing(_payDayMeta);
    }
    if (data.containsKey('pay_offset_months')) {
      context.handle(
        _payOffsetMonthsMeta,
        payOffsetMonths.isAcceptableOrUnknown(
          data['pay_offset_months']!,
          _payOffsetMonthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payOffsetMonthsMeta);
    }
    if (data.containsKey('weekend_adjust')) {
      context.handle(
        _weekendAdjustMeta,
        weekendAdjust.isAcceptableOrUnknown(
          data['weekend_adjust']!,
          _weekendAdjustMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weekendAdjustMeta);
    }
    if (data.containsKey('expected_pay_date')) {
      context.handle(
        _expectedPayDateMeta,
        expectedPayDate.isAcceptableOrUnknown(
          data['expected_pay_date']!,
          _expectedPayDateMeta,
        ),
      );
    }
    if (data.containsKey('fixed_total_minor')) {
      context.handle(
        _fixedTotalMinorMeta,
        fixedTotalMinor.isAcceptableOrUnknown(
          data['fixed_total_minor']!,
          _fixedTotalMinorMeta,
        ),
      );
    }
    if (data.containsKey('fixed_total_accrual')) {
      context.handle(
        _fixedTotalAccrualMeta,
        fixedTotalAccrual.isAcceptableOrUnknown(
          data['fixed_total_accrual']!,
          _fixedTotalAccrualMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fixedTotalAccrualMeta);
    }
    if (data.containsKey('forecast_method')) {
      context.handle(
        _forecastMethodMeta,
        forecastMethod.isAcceptableOrUnknown(
          data['forecast_method']!,
          _forecastMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_forecastMethodMeta);
    }
    if (data.containsKey('employer')) {
      context.handle(
        _employerMeta,
        employer.isAcceptableOrUnknown(data['employer']!, _employerMeta),
      );
    }
    if (data.containsKey('take_home_minor')) {
      context.handle(
        _takeHomeMinorMeta,
        takeHomeMinor.isAcceptableOrUnknown(
          data['take_home_minor']!,
          _takeHomeMinorMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('is_sample')) {
      context.handle(
        _isSampleMeta,
        isSample.isAcceptableOrUnknown(data['is_sample']!, _isSampleMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncomeSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncomeSourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      customCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_category'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      accrualPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accrual_policy'],
      )!,
      workWeekdayMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}work_weekday_mask'],
      )!,
      workStartMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}work_start_minute'],
      )!,
      workEndMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}work_end_minute'],
      )!,
      payRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pay_rule'],
      )!,
      payDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pay_day'],
      )!,
      payOffsetMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pay_offset_months'],
      )!,
      weekendAdjust: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekend_adjust'],
      )!,
      expectedPayDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_pay_date'],
      ),
      fixedTotalMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fixed_total_minor'],
      ),
      fixedTotalAccrual: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_total_accrual'],
      )!,
      forecastMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forecast_method'],
      )!,
      employer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}employer'],
      ),
      takeHomeMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}take_home_minor'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      isSample: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sample'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $IncomeSourcesTable createAlias(String alias) {
    return $IncomeSourcesTable(attachedDatabase, alias);
  }
}

class IncomeSourceRow extends DataClass implements Insertable<IncomeSourceRow> {
  final String id;
  final String name;
  final String kind;
  final String category;
  final String? customCategory;
  final String status;
  final String currencyCode;
  final String startDate;
  final String? endDate;
  final String accrualPolicy;
  final int workWeekdayMask;
  final int workStartMinute;
  final int workEndMinute;
  final String payRule;
  final int payDay;
  final int payOffsetMonths;
  final String weekendAdjust;
  final String? expectedPayDate;
  final int? fixedTotalMinor;
  final String fixedTotalAccrual;
  final String forecastMethod;
  final String? employer;
  final int? takeHomeMinor;
  final String? notes;
  final int colorIndex;
  final bool isSample;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const IncomeSourceRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.category,
    this.customCategory,
    required this.status,
    required this.currencyCode,
    required this.startDate,
    this.endDate,
    required this.accrualPolicy,
    required this.workWeekdayMask,
    required this.workStartMinute,
    required this.workEndMinute,
    required this.payRule,
    required this.payDay,
    required this.payOffsetMonths,
    required this.weekendAdjust,
    this.expectedPayDate,
    this.fixedTotalMinor,
    required this.fixedTotalAccrual,
    required this.forecastMethod,
    this.employer,
    this.takeHomeMinor,
    this.notes,
    required this.colorIndex,
    required this.isSample,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || customCategory != null) {
      map['custom_category'] = Variable<String>(customCategory);
    }
    map['status'] = Variable<String>(status);
    map['currency_code'] = Variable<String>(currencyCode);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['accrual_policy'] = Variable<String>(accrualPolicy);
    map['work_weekday_mask'] = Variable<int>(workWeekdayMask);
    map['work_start_minute'] = Variable<int>(workStartMinute);
    map['work_end_minute'] = Variable<int>(workEndMinute);
    map['pay_rule'] = Variable<String>(payRule);
    map['pay_day'] = Variable<int>(payDay);
    map['pay_offset_months'] = Variable<int>(payOffsetMonths);
    map['weekend_adjust'] = Variable<String>(weekendAdjust);
    if (!nullToAbsent || expectedPayDate != null) {
      map['expected_pay_date'] = Variable<String>(expectedPayDate);
    }
    if (!nullToAbsent || fixedTotalMinor != null) {
      map['fixed_total_minor'] = Variable<int>(fixedTotalMinor);
    }
    map['fixed_total_accrual'] = Variable<String>(fixedTotalAccrual);
    map['forecast_method'] = Variable<String>(forecastMethod);
    if (!nullToAbsent || employer != null) {
      map['employer'] = Variable<String>(employer);
    }
    if (!nullToAbsent || takeHomeMinor != null) {
      map['take_home_minor'] = Variable<int>(takeHomeMinor);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['color_index'] = Variable<int>(colorIndex);
    map['is_sample'] = Variable<bool>(isSample);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  IncomeSourcesCompanion toCompanion(bool nullToAbsent) {
    return IncomeSourcesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      category: Value(category),
      customCategory: customCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(customCategory),
      status: Value(status),
      currencyCode: Value(currencyCode),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      accrualPolicy: Value(accrualPolicy),
      workWeekdayMask: Value(workWeekdayMask),
      workStartMinute: Value(workStartMinute),
      workEndMinute: Value(workEndMinute),
      payRule: Value(payRule),
      payDay: Value(payDay),
      payOffsetMonths: Value(payOffsetMonths),
      weekendAdjust: Value(weekendAdjust),
      expectedPayDate: expectedPayDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedPayDate),
      fixedTotalMinor: fixedTotalMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedTotalMinor),
      fixedTotalAccrual: Value(fixedTotalAccrual),
      forecastMethod: Value(forecastMethod),
      employer: employer == null && nullToAbsent
          ? const Value.absent()
          : Value(employer),
      takeHomeMinor: takeHomeMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(takeHomeMinor),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      colorIndex: Value(colorIndex),
      isSample: Value(isSample),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory IncomeSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncomeSourceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      category: serializer.fromJson<String>(json['category']),
      customCategory: serializer.fromJson<String?>(json['customCategory']),
      status: serializer.fromJson<String>(json['status']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      accrualPolicy: serializer.fromJson<String>(json['accrualPolicy']),
      workWeekdayMask: serializer.fromJson<int>(json['workWeekdayMask']),
      workStartMinute: serializer.fromJson<int>(json['workStartMinute']),
      workEndMinute: serializer.fromJson<int>(json['workEndMinute']),
      payRule: serializer.fromJson<String>(json['payRule']),
      payDay: serializer.fromJson<int>(json['payDay']),
      payOffsetMonths: serializer.fromJson<int>(json['payOffsetMonths']),
      weekendAdjust: serializer.fromJson<String>(json['weekendAdjust']),
      expectedPayDate: serializer.fromJson<String?>(json['expectedPayDate']),
      fixedTotalMinor: serializer.fromJson<int?>(json['fixedTotalMinor']),
      fixedTotalAccrual: serializer.fromJson<String>(json['fixedTotalAccrual']),
      forecastMethod: serializer.fromJson<String>(json['forecastMethod']),
      employer: serializer.fromJson<String?>(json['employer']),
      takeHomeMinor: serializer.fromJson<int?>(json['takeHomeMinor']),
      notes: serializer.fromJson<String?>(json['notes']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      isSample: serializer.fromJson<bool>(json['isSample']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'category': serializer.toJson<String>(category),
      'customCategory': serializer.toJson<String?>(customCategory),
      'status': serializer.toJson<String>(status),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'accrualPolicy': serializer.toJson<String>(accrualPolicy),
      'workWeekdayMask': serializer.toJson<int>(workWeekdayMask),
      'workStartMinute': serializer.toJson<int>(workStartMinute),
      'workEndMinute': serializer.toJson<int>(workEndMinute),
      'payRule': serializer.toJson<String>(payRule),
      'payDay': serializer.toJson<int>(payDay),
      'payOffsetMonths': serializer.toJson<int>(payOffsetMonths),
      'weekendAdjust': serializer.toJson<String>(weekendAdjust),
      'expectedPayDate': serializer.toJson<String?>(expectedPayDate),
      'fixedTotalMinor': serializer.toJson<int?>(fixedTotalMinor),
      'fixedTotalAccrual': serializer.toJson<String>(fixedTotalAccrual),
      'forecastMethod': serializer.toJson<String>(forecastMethod),
      'employer': serializer.toJson<String?>(employer),
      'takeHomeMinor': serializer.toJson<int?>(takeHomeMinor),
      'notes': serializer.toJson<String?>(notes),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'isSample': serializer.toJson<bool>(isSample),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  IncomeSourceRow copyWith({
    String? id,
    String? name,
    String? kind,
    String? category,
    Value<String?> customCategory = const Value.absent(),
    String? status,
    String? currencyCode,
    String? startDate,
    Value<String?> endDate = const Value.absent(),
    String? accrualPolicy,
    int? workWeekdayMask,
    int? workStartMinute,
    int? workEndMinute,
    String? payRule,
    int? payDay,
    int? payOffsetMonths,
    String? weekendAdjust,
    Value<String?> expectedPayDate = const Value.absent(),
    Value<int?> fixedTotalMinor = const Value.absent(),
    String? fixedTotalAccrual,
    String? forecastMethod,
    Value<String?> employer = const Value.absent(),
    Value<int?> takeHomeMinor = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? colorIndex,
    bool? isSample,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => IncomeSourceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    category: category ?? this.category,
    customCategory: customCategory.present
        ? customCategory.value
        : this.customCategory,
    status: status ?? this.status,
    currencyCode: currencyCode ?? this.currencyCode,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    accrualPolicy: accrualPolicy ?? this.accrualPolicy,
    workWeekdayMask: workWeekdayMask ?? this.workWeekdayMask,
    workStartMinute: workStartMinute ?? this.workStartMinute,
    workEndMinute: workEndMinute ?? this.workEndMinute,
    payRule: payRule ?? this.payRule,
    payDay: payDay ?? this.payDay,
    payOffsetMonths: payOffsetMonths ?? this.payOffsetMonths,
    weekendAdjust: weekendAdjust ?? this.weekendAdjust,
    expectedPayDate: expectedPayDate.present
        ? expectedPayDate.value
        : this.expectedPayDate,
    fixedTotalMinor: fixedTotalMinor.present
        ? fixedTotalMinor.value
        : this.fixedTotalMinor,
    fixedTotalAccrual: fixedTotalAccrual ?? this.fixedTotalAccrual,
    forecastMethod: forecastMethod ?? this.forecastMethod,
    employer: employer.present ? employer.value : this.employer,
    takeHomeMinor: takeHomeMinor.present
        ? takeHomeMinor.value
        : this.takeHomeMinor,
    notes: notes.present ? notes.value : this.notes,
    colorIndex: colorIndex ?? this.colorIndex,
    isSample: isSample ?? this.isSample,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  IncomeSourceRow copyWithCompanion(IncomeSourcesCompanion data) {
    return IncomeSourceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      category: data.category.present ? data.category.value : this.category,
      customCategory: data.customCategory.present
          ? data.customCategory.value
          : this.customCategory,
      status: data.status.present ? data.status.value : this.status,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      accrualPolicy: data.accrualPolicy.present
          ? data.accrualPolicy.value
          : this.accrualPolicy,
      workWeekdayMask: data.workWeekdayMask.present
          ? data.workWeekdayMask.value
          : this.workWeekdayMask,
      workStartMinute: data.workStartMinute.present
          ? data.workStartMinute.value
          : this.workStartMinute,
      workEndMinute: data.workEndMinute.present
          ? data.workEndMinute.value
          : this.workEndMinute,
      payRule: data.payRule.present ? data.payRule.value : this.payRule,
      payDay: data.payDay.present ? data.payDay.value : this.payDay,
      payOffsetMonths: data.payOffsetMonths.present
          ? data.payOffsetMonths.value
          : this.payOffsetMonths,
      weekendAdjust: data.weekendAdjust.present
          ? data.weekendAdjust.value
          : this.weekendAdjust,
      expectedPayDate: data.expectedPayDate.present
          ? data.expectedPayDate.value
          : this.expectedPayDate,
      fixedTotalMinor: data.fixedTotalMinor.present
          ? data.fixedTotalMinor.value
          : this.fixedTotalMinor,
      fixedTotalAccrual: data.fixedTotalAccrual.present
          ? data.fixedTotalAccrual.value
          : this.fixedTotalAccrual,
      forecastMethod: data.forecastMethod.present
          ? data.forecastMethod.value
          : this.forecastMethod,
      employer: data.employer.present ? data.employer.value : this.employer,
      takeHomeMinor: data.takeHomeMinor.present
          ? data.takeHomeMinor.value
          : this.takeHomeMinor,
      notes: data.notes.present ? data.notes.value : this.notes,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      isSample: data.isSample.present ? data.isSample.value : this.isSample,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncomeSourceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('category: $category, ')
          ..write('customCategory: $customCategory, ')
          ..write('status: $status, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('accrualPolicy: $accrualPolicy, ')
          ..write('workWeekdayMask: $workWeekdayMask, ')
          ..write('workStartMinute: $workStartMinute, ')
          ..write('workEndMinute: $workEndMinute, ')
          ..write('payRule: $payRule, ')
          ..write('payDay: $payDay, ')
          ..write('payOffsetMonths: $payOffsetMonths, ')
          ..write('weekendAdjust: $weekendAdjust, ')
          ..write('expectedPayDate: $expectedPayDate, ')
          ..write('fixedTotalMinor: $fixedTotalMinor, ')
          ..write('fixedTotalAccrual: $fixedTotalAccrual, ')
          ..write('forecastMethod: $forecastMethod, ')
          ..write('employer: $employer, ')
          ..write('takeHomeMinor: $takeHomeMinor, ')
          ..write('notes: $notes, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('isSample: $isSample, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    kind,
    category,
    customCategory,
    status,
    currencyCode,
    startDate,
    endDate,
    accrualPolicy,
    workWeekdayMask,
    workStartMinute,
    workEndMinute,
    payRule,
    payDay,
    payOffsetMonths,
    weekendAdjust,
    expectedPayDate,
    fixedTotalMinor,
    fixedTotalAccrual,
    forecastMethod,
    employer,
    takeHomeMinor,
    notes,
    colorIndex,
    isSample,
    sortOrder,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncomeSourceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.category == this.category &&
          other.customCategory == this.customCategory &&
          other.status == this.status &&
          other.currencyCode == this.currencyCode &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.accrualPolicy == this.accrualPolicy &&
          other.workWeekdayMask == this.workWeekdayMask &&
          other.workStartMinute == this.workStartMinute &&
          other.workEndMinute == this.workEndMinute &&
          other.payRule == this.payRule &&
          other.payDay == this.payDay &&
          other.payOffsetMonths == this.payOffsetMonths &&
          other.weekendAdjust == this.weekendAdjust &&
          other.expectedPayDate == this.expectedPayDate &&
          other.fixedTotalMinor == this.fixedTotalMinor &&
          other.fixedTotalAccrual == this.fixedTotalAccrual &&
          other.forecastMethod == this.forecastMethod &&
          other.employer == this.employer &&
          other.takeHomeMinor == this.takeHomeMinor &&
          other.notes == this.notes &&
          other.colorIndex == this.colorIndex &&
          other.isSample == this.isSample &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class IncomeSourcesCompanion extends UpdateCompanion<IncomeSourceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> category;
  final Value<String?> customCategory;
  final Value<String> status;
  final Value<String> currencyCode;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<String> accrualPolicy;
  final Value<int> workWeekdayMask;
  final Value<int> workStartMinute;
  final Value<int> workEndMinute;
  final Value<String> payRule;
  final Value<int> payDay;
  final Value<int> payOffsetMonths;
  final Value<String> weekendAdjust;
  final Value<String?> expectedPayDate;
  final Value<int?> fixedTotalMinor;
  final Value<String> fixedTotalAccrual;
  final Value<String> forecastMethod;
  final Value<String?> employer;
  final Value<int?> takeHomeMinor;
  final Value<String?> notes;
  final Value<int> colorIndex;
  final Value<bool> isSample;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const IncomeSourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.category = const Value.absent(),
    this.customCategory = const Value.absent(),
    this.status = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.accrualPolicy = const Value.absent(),
    this.workWeekdayMask = const Value.absent(),
    this.workStartMinute = const Value.absent(),
    this.workEndMinute = const Value.absent(),
    this.payRule = const Value.absent(),
    this.payDay = const Value.absent(),
    this.payOffsetMonths = const Value.absent(),
    this.weekendAdjust = const Value.absent(),
    this.expectedPayDate = const Value.absent(),
    this.fixedTotalMinor = const Value.absent(),
    this.fixedTotalAccrual = const Value.absent(),
    this.forecastMethod = const Value.absent(),
    this.employer = const Value.absent(),
    this.takeHomeMinor = const Value.absent(),
    this.notes = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.isSample = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncomeSourcesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    required String category,
    this.customCategory = const Value.absent(),
    required String status,
    required String currencyCode,
    required String startDate,
    this.endDate = const Value.absent(),
    required String accrualPolicy,
    required int workWeekdayMask,
    required int workStartMinute,
    required int workEndMinute,
    required String payRule,
    required int payDay,
    required int payOffsetMonths,
    required String weekendAdjust,
    this.expectedPayDate = const Value.absent(),
    this.fixedTotalMinor = const Value.absent(),
    required String fixedTotalAccrual,
    required String forecastMethod,
    this.employer = const Value.absent(),
    this.takeHomeMinor = const Value.absent(),
    this.notes = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.isSample = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       category = Value(category),
       status = Value(status),
       currencyCode = Value(currencyCode),
       startDate = Value(startDate),
       accrualPolicy = Value(accrualPolicy),
       workWeekdayMask = Value(workWeekdayMask),
       workStartMinute = Value(workStartMinute),
       workEndMinute = Value(workEndMinute),
       payRule = Value(payRule),
       payDay = Value(payDay),
       payOffsetMonths = Value(payOffsetMonths),
       weekendAdjust = Value(weekendAdjust),
       fixedTotalAccrual = Value(fixedTotalAccrual),
       forecastMethod = Value(forecastMethod),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<IncomeSourceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? category,
    Expression<String>? customCategory,
    Expression<String>? status,
    Expression<String>? currencyCode,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? accrualPolicy,
    Expression<int>? workWeekdayMask,
    Expression<int>? workStartMinute,
    Expression<int>? workEndMinute,
    Expression<String>? payRule,
    Expression<int>? payDay,
    Expression<int>? payOffsetMonths,
    Expression<String>? weekendAdjust,
    Expression<String>? expectedPayDate,
    Expression<int>? fixedTotalMinor,
    Expression<String>? fixedTotalAccrual,
    Expression<String>? forecastMethod,
    Expression<String>? employer,
    Expression<int>? takeHomeMinor,
    Expression<String>? notes,
    Expression<int>? colorIndex,
    Expression<bool>? isSample,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (category != null) 'category': category,
      if (customCategory != null) 'custom_category': customCategory,
      if (status != null) 'status': status,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (accrualPolicy != null) 'accrual_policy': accrualPolicy,
      if (workWeekdayMask != null) 'work_weekday_mask': workWeekdayMask,
      if (workStartMinute != null) 'work_start_minute': workStartMinute,
      if (workEndMinute != null) 'work_end_minute': workEndMinute,
      if (payRule != null) 'pay_rule': payRule,
      if (payDay != null) 'pay_day': payDay,
      if (payOffsetMonths != null) 'pay_offset_months': payOffsetMonths,
      if (weekendAdjust != null) 'weekend_adjust': weekendAdjust,
      if (expectedPayDate != null) 'expected_pay_date': expectedPayDate,
      if (fixedTotalMinor != null) 'fixed_total_minor': fixedTotalMinor,
      if (fixedTotalAccrual != null) 'fixed_total_accrual': fixedTotalAccrual,
      if (forecastMethod != null) 'forecast_method': forecastMethod,
      if (employer != null) 'employer': employer,
      if (takeHomeMinor != null) 'take_home_minor': takeHomeMinor,
      if (notes != null) 'notes': notes,
      if (colorIndex != null) 'color_index': colorIndex,
      if (isSample != null) 'is_sample': isSample,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncomeSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? category,
    Value<String?>? customCategory,
    Value<String>? status,
    Value<String>? currencyCode,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<String>? accrualPolicy,
    Value<int>? workWeekdayMask,
    Value<int>? workStartMinute,
    Value<int>? workEndMinute,
    Value<String>? payRule,
    Value<int>? payDay,
    Value<int>? payOffsetMonths,
    Value<String>? weekendAdjust,
    Value<String?>? expectedPayDate,
    Value<int?>? fixedTotalMinor,
    Value<String>? fixedTotalAccrual,
    Value<String>? forecastMethod,
    Value<String?>? employer,
    Value<int?>? takeHomeMinor,
    Value<String?>? notes,
    Value<int>? colorIndex,
    Value<bool>? isSample,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return IncomeSourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      status: status ?? this.status,
      currencyCode: currencyCode ?? this.currencyCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accrualPolicy: accrualPolicy ?? this.accrualPolicy,
      workWeekdayMask: workWeekdayMask ?? this.workWeekdayMask,
      workStartMinute: workStartMinute ?? this.workStartMinute,
      workEndMinute: workEndMinute ?? this.workEndMinute,
      payRule: payRule ?? this.payRule,
      payDay: payDay ?? this.payDay,
      payOffsetMonths: payOffsetMonths ?? this.payOffsetMonths,
      weekendAdjust: weekendAdjust ?? this.weekendAdjust,
      expectedPayDate: expectedPayDate ?? this.expectedPayDate,
      fixedTotalMinor: fixedTotalMinor ?? this.fixedTotalMinor,
      fixedTotalAccrual: fixedTotalAccrual ?? this.fixedTotalAccrual,
      forecastMethod: forecastMethod ?? this.forecastMethod,
      employer: employer ?? this.employer,
      takeHomeMinor: takeHomeMinor ?? this.takeHomeMinor,
      notes: notes ?? this.notes,
      colorIndex: colorIndex ?? this.colorIndex,
      isSample: isSample ?? this.isSample,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (customCategory.present) {
      map['custom_category'] = Variable<String>(customCategory.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (accrualPolicy.present) {
      map['accrual_policy'] = Variable<String>(accrualPolicy.value);
    }
    if (workWeekdayMask.present) {
      map['work_weekday_mask'] = Variable<int>(workWeekdayMask.value);
    }
    if (workStartMinute.present) {
      map['work_start_minute'] = Variable<int>(workStartMinute.value);
    }
    if (workEndMinute.present) {
      map['work_end_minute'] = Variable<int>(workEndMinute.value);
    }
    if (payRule.present) {
      map['pay_rule'] = Variable<String>(payRule.value);
    }
    if (payDay.present) {
      map['pay_day'] = Variable<int>(payDay.value);
    }
    if (payOffsetMonths.present) {
      map['pay_offset_months'] = Variable<int>(payOffsetMonths.value);
    }
    if (weekendAdjust.present) {
      map['weekend_adjust'] = Variable<String>(weekendAdjust.value);
    }
    if (expectedPayDate.present) {
      map['expected_pay_date'] = Variable<String>(expectedPayDate.value);
    }
    if (fixedTotalMinor.present) {
      map['fixed_total_minor'] = Variable<int>(fixedTotalMinor.value);
    }
    if (fixedTotalAccrual.present) {
      map['fixed_total_accrual'] = Variable<String>(fixedTotalAccrual.value);
    }
    if (forecastMethod.present) {
      map['forecast_method'] = Variable<String>(forecastMethod.value);
    }
    if (employer.present) {
      map['employer'] = Variable<String>(employer.value);
    }
    if (takeHomeMinor.present) {
      map['take_home_minor'] = Variable<int>(takeHomeMinor.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (isSample.present) {
      map['is_sample'] = Variable<bool>(isSample.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomeSourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('category: $category, ')
          ..write('customCategory: $customCategory, ')
          ..write('status: $status, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('accrualPolicy: $accrualPolicy, ')
          ..write('workWeekdayMask: $workWeekdayMask, ')
          ..write('workStartMinute: $workStartMinute, ')
          ..write('workEndMinute: $workEndMinute, ')
          ..write('payRule: $payRule, ')
          ..write('payDay: $payDay, ')
          ..write('payOffsetMonths: $payOffsetMonths, ')
          ..write('weekendAdjust: $weekendAdjust, ')
          ..write('expectedPayDate: $expectedPayDate, ')
          ..write('fixedTotalMinor: $fixedTotalMinor, ')
          ..write('fixedTotalAccrual: $fixedTotalAccrual, ')
          ..write('forecastMethod: $forecastMethod, ')
          ..write('employer: $employer, ')
          ..write('takeHomeMinor: $takeHomeMinor, ')
          ..write('notes: $notes, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('isSample: $isSample, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RateRevisionsTable extends RateRevisions
    with TableInfo<$RateRevisionsTable, RateRevisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RateRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES income_sources (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<String> effectiveFrom = GeneratedColumn<String>(
    'effective_from',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeTypeMeta = const VerificationMeta(
    'changeType',
  );
  @override
  late final GeneratedColumn<String> changeType = GeneratedColumn<String>(
    'change_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentBpsMeta = const VerificationMeta(
    'percentBps',
  );
  @override
  late final GeneratedColumn<int> percentBps = GeneratedColumn<int>(
    'percent_bps',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    effectiveFrom,
    amountMinor,
    period,
    changeType,
    percentBps,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rate_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RateRevisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('change_type')) {
      context.handle(
        _changeTypeMeta,
        changeType.isAcceptableOrUnknown(data['change_type']!, _changeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_changeTypeMeta);
    }
    if (data.containsKey('percent_bps')) {
      context.handle(
        _percentBpsMeta,
        percentBps.isAcceptableOrUnknown(data['percent_bps']!, _percentBpsMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RateRevisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RateRevisionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_from'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      changeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_type'],
      )!,
      percentBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percent_bps'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RateRevisionsTable createAlias(String alias) {
    return $RateRevisionsTable(attachedDatabase, alias);
  }
}

class RateRevisionRow extends DataClass implements Insertable<RateRevisionRow> {
  final String id;
  final String sourceId;
  final String effectiveFrom;
  final int amountMinor;
  final String period;
  final String changeType;
  final int? percentBps;
  final String? note;
  final int createdAt;
  const RateRevisionRow({
    required this.id,
    required this.sourceId,
    required this.effectiveFrom,
    required this.amountMinor,
    required this.period,
    required this.changeType,
    this.percentBps,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['effective_from'] = Variable<String>(effectiveFrom);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['period'] = Variable<String>(period);
    map['change_type'] = Variable<String>(changeType);
    if (!nullToAbsent || percentBps != null) {
      map['percent_bps'] = Variable<int>(percentBps);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RateRevisionsCompanion toCompanion(bool nullToAbsent) {
    return RateRevisionsCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      effectiveFrom: Value(effectiveFrom),
      amountMinor: Value(amountMinor),
      period: Value(period),
      changeType: Value(changeType),
      percentBps: percentBps == null && nullToAbsent
          ? const Value.absent()
          : Value(percentBps),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory RateRevisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RateRevisionRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      effectiveFrom: serializer.fromJson<String>(json['effectiveFrom']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      period: serializer.fromJson<String>(json['period']),
      changeType: serializer.fromJson<String>(json['changeType']),
      percentBps: serializer.fromJson<int?>(json['percentBps']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'effectiveFrom': serializer.toJson<String>(effectiveFrom),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'period': serializer.toJson<String>(period),
      'changeType': serializer.toJson<String>(changeType),
      'percentBps': serializer.toJson<int?>(percentBps),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  RateRevisionRow copyWith({
    String? id,
    String? sourceId,
    String? effectiveFrom,
    int? amountMinor,
    String? period,
    String? changeType,
    Value<int?> percentBps = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? createdAt,
  }) => RateRevisionRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    effectiveFrom: effectiveFrom ?? this.effectiveFrom,
    amountMinor: amountMinor ?? this.amountMinor,
    period: period ?? this.period,
    changeType: changeType ?? this.changeType,
    percentBps: percentBps.present ? percentBps.value : this.percentBps,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  RateRevisionRow copyWithCompanion(RateRevisionsCompanion data) {
    return RateRevisionRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      period: data.period.present ? data.period.value : this.period,
      changeType: data.changeType.present
          ? data.changeType.value
          : this.changeType,
      percentBps: data.percentBps.present
          ? data.percentBps.value
          : this.percentBps,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RateRevisionRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('period: $period, ')
          ..write('changeType: $changeType, ')
          ..write('percentBps: $percentBps, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    effectiveFrom,
    amountMinor,
    period,
    changeType,
    percentBps,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RateRevisionRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.effectiveFrom == this.effectiveFrom &&
          other.amountMinor == this.amountMinor &&
          other.period == this.period &&
          other.changeType == this.changeType &&
          other.percentBps == this.percentBps &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class RateRevisionsCompanion extends UpdateCompanion<RateRevisionRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String> effectiveFrom;
  final Value<int> amountMinor;
  final Value<String> period;
  final Value<String> changeType;
  final Value<int?> percentBps;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> rowid;
  const RateRevisionsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.period = const Value.absent(),
    this.changeType = const Value.absent(),
    this.percentBps = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RateRevisionsCompanion.insert({
    required String id,
    required String sourceId,
    required String effectiveFrom,
    required int amountMinor,
    required String period,
    required String changeType,
    this.percentBps = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       effectiveFrom = Value(effectiveFrom),
       amountMinor = Value(amountMinor),
       period = Value(period),
       changeType = Value(changeType),
       createdAt = Value(createdAt);
  static Insertable<RateRevisionRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? effectiveFrom,
    Expression<int>? amountMinor,
    Expression<String>? period,
    Expression<String>? changeType,
    Expression<int>? percentBps,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (period != null) 'period': period,
      if (changeType != null) 'change_type': changeType,
      if (percentBps != null) 'percent_bps': percentBps,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RateRevisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String>? effectiveFrom,
    Value<int>? amountMinor,
    Value<String>? period,
    Value<String>? changeType,
    Value<int?>? percentBps,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return RateRevisionsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      amountMinor: amountMinor ?? this.amountMinor,
      period: period ?? this.period,
      changeType: changeType ?? this.changeType,
      percentBps: percentBps ?? this.percentBps,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<String>(effectiveFrom.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (changeType.present) {
      map['change_type'] = Variable<String>(changeType.value);
    }
    if (percentBps.present) {
      map['percent_bps'] = Variable<int>(percentBps.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RateRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('period: $period, ')
          ..write('changeType: $changeType, ')
          ..write('percentBps: $percentBps, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourcePausesTable extends SourcePauses
    with TableInfo<$SourcePausesTable, SourcePauseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcePausesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES income_sources (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<String> start = GeneratedColumn<String>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endExclusiveMeta = const VerificationMeta(
    'endExclusive',
  );
  @override
  late final GeneratedColumn<String> endExclusive = GeneratedColumn<String>(
    'end_exclusive',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sourceId, start, endExclusive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_pauses';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourcePauseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end_exclusive')) {
      context.handle(
        _endExclusiveMeta,
        endExclusive.isAcceptableOrUnknown(
          data['end_exclusive']!,
          _endExclusiveMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourcePauseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourcePauseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start'],
      )!,
      endExclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_exclusive'],
      ),
    );
  }

  @override
  $SourcePausesTable createAlias(String alias) {
    return $SourcePausesTable(attachedDatabase, alias);
  }
}

class SourcePauseRow extends DataClass implements Insertable<SourcePauseRow> {
  final String id;
  final String sourceId;
  final String start;
  final String? endExclusive;
  const SourcePauseRow({
    required this.id,
    required this.sourceId,
    required this.start,
    this.endExclusive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['start'] = Variable<String>(start);
    if (!nullToAbsent || endExclusive != null) {
      map['end_exclusive'] = Variable<String>(endExclusive);
    }
    return map;
  }

  SourcePausesCompanion toCompanion(bool nullToAbsent) {
    return SourcePausesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      start: Value(start),
      endExclusive: endExclusive == null && nullToAbsent
          ? const Value.absent()
          : Value(endExclusive),
    );
  }

  factory SourcePauseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourcePauseRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      start: serializer.fromJson<String>(json['start']),
      endExclusive: serializer.fromJson<String?>(json['endExclusive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'start': serializer.toJson<String>(start),
      'endExclusive': serializer.toJson<String?>(endExclusive),
    };
  }

  SourcePauseRow copyWith({
    String? id,
    String? sourceId,
    String? start,
    Value<String?> endExclusive = const Value.absent(),
  }) => SourcePauseRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    start: start ?? this.start,
    endExclusive: endExclusive.present ? endExclusive.value : this.endExclusive,
  );
  SourcePauseRow copyWithCompanion(SourcePausesCompanion data) {
    return SourcePauseRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      start: data.start.present ? data.start.value : this.start,
      endExclusive: data.endExclusive.present
          ? data.endExclusive.value
          : this.endExclusive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourcePauseRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('start: $start, ')
          ..write('endExclusive: $endExclusive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceId, start, endExclusive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourcePauseRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.start == this.start &&
          other.endExclusive == this.endExclusive);
}

class SourcePausesCompanion extends UpdateCompanion<SourcePauseRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String> start;
  final Value<String?> endExclusive;
  final Value<int> rowid;
  const SourcePausesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.start = const Value.absent(),
    this.endExclusive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcePausesCompanion.insert({
    required String id,
    required String sourceId,
    required String start,
    this.endExclusive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       start = Value(start);
  static Insertable<SourcePauseRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? start,
    Expression<String>? endExclusive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (start != null) 'start': start,
      if (endExclusive != null) 'end_exclusive': endExclusive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcePausesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String>? start,
    Value<String?>? endExclusive,
    Value<int>? rowid,
  }) {
    return SourcePausesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      start: start ?? this.start,
      endExclusive: endExclusive ?? this.endExclusive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (start.present) {
      map['start'] = Variable<String>(start.value);
    }
    if (endExclusive.present) {
      map['end_exclusive'] = Variable<String>(endExclusive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcePausesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('start: $start, ')
          ..write('endExclusive: $endExclusive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayOverridesTable extends DayOverrides
    with TableInfo<$DayOverridesTable, DayOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES income_sources (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [id, sourceId, date, type, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayOverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayOverrideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayOverrideRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $DayOverridesTable createAlias(String alias) {
    return $DayOverridesTable(attachedDatabase, alias);
  }
}

class DayOverrideRow extends DataClass implements Insertable<DayOverrideRow> {
  final String id;
  final String? sourceId;
  final String date;
  final String type;
  final String? note;
  const DayOverrideRow({
    required this.id,
    this.sourceId,
    required this.date,
    required this.type,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  DayOverridesCompanion toCompanion(bool nullToAbsent) {
    return DayOverridesCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      date: Value(date),
      type: Value(type),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory DayOverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayOverrideRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String?>(sourceId),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'note': serializer.toJson<String?>(note),
    };
  }

  DayOverrideRow copyWith({
    String? id,
    Value<String?> sourceId = const Value.absent(),
    String? date,
    String? type,
    Value<String?> note = const Value.absent(),
  }) => DayOverrideRow(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    date: date ?? this.date,
    type: type ?? this.type,
    note: note.present ? note.value : this.note,
  );
  DayOverrideRow copyWithCompanion(DayOverridesCompanion data) {
    return DayOverrideRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayOverrideRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceId, date, type, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayOverrideRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.date == this.date &&
          other.type == this.type &&
          other.note == this.note);
}

class DayOverridesCompanion extends UpdateCompanion<DayOverrideRow> {
  final Value<String> id;
  final Value<String?> sourceId;
  final Value<String> date;
  final Value<String> type;
  final Value<String?> note;
  final Value<int> rowid;
  const DayOverridesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayOverridesCompanion.insert({
    required String id,
    this.sourceId = const Value.absent(),
    required String date,
    required String type,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       type = Value(type);
  static Insertable<DayOverrideRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? date,
    Expression<String>? type,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayOverridesCompanion copyWith({
    Value<String>? id,
    Value<String?>? sourceId,
    Value<String>? date,
    Value<String>? type,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return DayOverridesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayOverridesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompensationItemsTable extends CompensationItems
    with TableInfo<$CompensationItemsTable, CompensationItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompensationItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES income_sources (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedMinorMeta = const VerificationMeta(
    'expectedMinor',
  );
  @override
  late final GeneratedColumn<int> expectedMinor = GeneratedColumn<int>(
    'expected_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedDateMeta = const VerificationMeta(
    'expectedDate',
  );
  @override
  late final GeneratedColumn<String> expectedDate = GeneratedColumn<String>(
    'expected_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualMinorMeta = const VerificationMeta(
    'actualMinor',
  );
  @override
  late final GeneratedColumn<int> actualMinor = GeneratedColumn<int>(
    'actual_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _earnedDateMeta = const VerificationMeta(
    'earnedDate',
  );
  @override
  late final GeneratedColumn<String> earnedDate = GeneratedColumn<String>(
    'earned_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta(
    'recurrence',
  );
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nonCashMeta = const VerificationMeta(
    'nonCash',
  );
  @override
  late final GeneratedColumn<bool> nonCash = GeneratedColumn<bool>(
    'non_cash',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("non_cash" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _countsAsEarningsMeta = const VerificationMeta(
    'countsAsEarnings',
  );
  @override
  late final GeneratedColumn<bool> countsAsEarnings = GeneratedColumn<bool>(
    'counts_as_earnings',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("counts_as_earnings" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _includeInForecastMeta = const VerificationMeta(
    'includeInForecast',
  );
  @override
  late final GeneratedColumn<bool> includeInForecast = GeneratedColumn<bool>(
    'include_in_forecast',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_forecast" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _taxNoteMeta = const VerificationMeta(
    'taxNote',
  );
  @override
  late final GeneratedColumn<String> taxNote = GeneratedColumn<String>(
    'tax_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cancelledMeta = const VerificationMeta(
    'cancelled',
  );
  @override
  late final GeneratedColumn<bool> cancelled = GeneratedColumn<bool>(
    'cancelled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cancelled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    type,
    title,
    currencyCode,
    expectedMinor,
    expectedDate,
    actualMinor,
    earnedDate,
    recurrence,
    nonCash,
    countsAsEarnings,
    includeInForecast,
    taxNote,
    notes,
    cancelled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'compensation_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompensationItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('expected_minor')) {
      context.handle(
        _expectedMinorMeta,
        expectedMinor.isAcceptableOrUnknown(
          data['expected_minor']!,
          _expectedMinorMeta,
        ),
      );
    }
    if (data.containsKey('expected_date')) {
      context.handle(
        _expectedDateMeta,
        expectedDate.isAcceptableOrUnknown(
          data['expected_date']!,
          _expectedDateMeta,
        ),
      );
    }
    if (data.containsKey('actual_minor')) {
      context.handle(
        _actualMinorMeta,
        actualMinor.isAcceptableOrUnknown(
          data['actual_minor']!,
          _actualMinorMeta,
        ),
      );
    }
    if (data.containsKey('earned_date')) {
      context.handle(
        _earnedDateMeta,
        earnedDate.isAcceptableOrUnknown(data['earned_date']!, _earnedDateMeta),
      );
    }
    if (data.containsKey('recurrence')) {
      context.handle(
        _recurrenceMeta,
        recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta),
      );
    } else if (isInserting) {
      context.missing(_recurrenceMeta);
    }
    if (data.containsKey('non_cash')) {
      context.handle(
        _nonCashMeta,
        nonCash.isAcceptableOrUnknown(data['non_cash']!, _nonCashMeta),
      );
    }
    if (data.containsKey('counts_as_earnings')) {
      context.handle(
        _countsAsEarningsMeta,
        countsAsEarnings.isAcceptableOrUnknown(
          data['counts_as_earnings']!,
          _countsAsEarningsMeta,
        ),
      );
    }
    if (data.containsKey('include_in_forecast')) {
      context.handle(
        _includeInForecastMeta,
        includeInForecast.isAcceptableOrUnknown(
          data['include_in_forecast']!,
          _includeInForecastMeta,
        ),
      );
    }
    if (data.containsKey('tax_note')) {
      context.handle(
        _taxNoteMeta,
        taxNote.isAcceptableOrUnknown(data['tax_note']!, _taxNoteMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('cancelled')) {
      context.handle(
        _cancelledMeta,
        cancelled.isAcceptableOrUnknown(data['cancelled']!, _cancelledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompensationItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompensationItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      expectedMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_minor'],
      ),
      expectedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expected_date'],
      ),
      actualMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_minor'],
      ),
      earnedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}earned_date'],
      ),
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      )!,
      nonCash: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}non_cash'],
      )!,
      countsAsEarnings: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counts_as_earnings'],
      )!,
      includeInForecast: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_forecast'],
      )!,
      taxNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_note'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      cancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cancelled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CompensationItemsTable createAlias(String alias) {
    return $CompensationItemsTable(attachedDatabase, alias);
  }
}

class CompensationItemRow extends DataClass
    implements Insertable<CompensationItemRow> {
  final String id;
  final String? sourceId;
  final String type;
  final String title;
  final String currencyCode;
  final int? expectedMinor;
  final String? expectedDate;
  final int? actualMinor;
  final String? earnedDate;
  final String recurrence;
  final bool nonCash;
  final bool countsAsEarnings;
  final bool includeInForecast;
  final String? taxNote;
  final String? notes;
  final bool cancelled;
  final int createdAt;
  final int updatedAt;
  const CompensationItemRow({
    required this.id,
    this.sourceId,
    required this.type,
    required this.title,
    required this.currencyCode,
    this.expectedMinor,
    this.expectedDate,
    this.actualMinor,
    this.earnedDate,
    required this.recurrence,
    required this.nonCash,
    required this.countsAsEarnings,
    required this.includeInForecast,
    this.taxNote,
    this.notes,
    required this.cancelled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || expectedMinor != null) {
      map['expected_minor'] = Variable<int>(expectedMinor);
    }
    if (!nullToAbsent || expectedDate != null) {
      map['expected_date'] = Variable<String>(expectedDate);
    }
    if (!nullToAbsent || actualMinor != null) {
      map['actual_minor'] = Variable<int>(actualMinor);
    }
    if (!nullToAbsent || earnedDate != null) {
      map['earned_date'] = Variable<String>(earnedDate);
    }
    map['recurrence'] = Variable<String>(recurrence);
    map['non_cash'] = Variable<bool>(nonCash);
    map['counts_as_earnings'] = Variable<bool>(countsAsEarnings);
    map['include_in_forecast'] = Variable<bool>(includeInForecast);
    if (!nullToAbsent || taxNote != null) {
      map['tax_note'] = Variable<String>(taxNote);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['cancelled'] = Variable<bool>(cancelled);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CompensationItemsCompanion toCompanion(bool nullToAbsent) {
    return CompensationItemsCompanion(
      id: Value(id),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      type: Value(type),
      title: Value(title),
      currencyCode: Value(currencyCode),
      expectedMinor: expectedMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedMinor),
      expectedDate: expectedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedDate),
      actualMinor: actualMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(actualMinor),
      earnedDate: earnedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(earnedDate),
      recurrence: Value(recurrence),
      nonCash: Value(nonCash),
      countsAsEarnings: Value(countsAsEarnings),
      includeInForecast: Value(includeInForecast),
      taxNote: taxNote == null && nullToAbsent
          ? const Value.absent()
          : Value(taxNote),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      cancelled: Value(cancelled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CompensationItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompensationItemRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      expectedMinor: serializer.fromJson<int?>(json['expectedMinor']),
      expectedDate: serializer.fromJson<String?>(json['expectedDate']),
      actualMinor: serializer.fromJson<int?>(json['actualMinor']),
      earnedDate: serializer.fromJson<String?>(json['earnedDate']),
      recurrence: serializer.fromJson<String>(json['recurrence']),
      nonCash: serializer.fromJson<bool>(json['nonCash']),
      countsAsEarnings: serializer.fromJson<bool>(json['countsAsEarnings']),
      includeInForecast: serializer.fromJson<bool>(json['includeInForecast']),
      taxNote: serializer.fromJson<String?>(json['taxNote']),
      notes: serializer.fromJson<String?>(json['notes']),
      cancelled: serializer.fromJson<bool>(json['cancelled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String?>(sourceId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'expectedMinor': serializer.toJson<int?>(expectedMinor),
      'expectedDate': serializer.toJson<String?>(expectedDate),
      'actualMinor': serializer.toJson<int?>(actualMinor),
      'earnedDate': serializer.toJson<String?>(earnedDate),
      'recurrence': serializer.toJson<String>(recurrence),
      'nonCash': serializer.toJson<bool>(nonCash),
      'countsAsEarnings': serializer.toJson<bool>(countsAsEarnings),
      'includeInForecast': serializer.toJson<bool>(includeInForecast),
      'taxNote': serializer.toJson<String?>(taxNote),
      'notes': serializer.toJson<String?>(notes),
      'cancelled': serializer.toJson<bool>(cancelled),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CompensationItemRow copyWith({
    String? id,
    Value<String?> sourceId = const Value.absent(),
    String? type,
    String? title,
    String? currencyCode,
    Value<int?> expectedMinor = const Value.absent(),
    Value<String?> expectedDate = const Value.absent(),
    Value<int?> actualMinor = const Value.absent(),
    Value<String?> earnedDate = const Value.absent(),
    String? recurrence,
    bool? nonCash,
    bool? countsAsEarnings,
    bool? includeInForecast,
    Value<String?> taxNote = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? cancelled,
    int? createdAt,
    int? updatedAt,
  }) => CompensationItemRow(
    id: id ?? this.id,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    type: type ?? this.type,
    title: title ?? this.title,
    currencyCode: currencyCode ?? this.currencyCode,
    expectedMinor: expectedMinor.present
        ? expectedMinor.value
        : this.expectedMinor,
    expectedDate: expectedDate.present ? expectedDate.value : this.expectedDate,
    actualMinor: actualMinor.present ? actualMinor.value : this.actualMinor,
    earnedDate: earnedDate.present ? earnedDate.value : this.earnedDate,
    recurrence: recurrence ?? this.recurrence,
    nonCash: nonCash ?? this.nonCash,
    countsAsEarnings: countsAsEarnings ?? this.countsAsEarnings,
    includeInForecast: includeInForecast ?? this.includeInForecast,
    taxNote: taxNote.present ? taxNote.value : this.taxNote,
    notes: notes.present ? notes.value : this.notes,
    cancelled: cancelled ?? this.cancelled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CompensationItemRow copyWithCompanion(CompensationItemsCompanion data) {
    return CompensationItemRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      expectedMinor: data.expectedMinor.present
          ? data.expectedMinor.value
          : this.expectedMinor,
      expectedDate: data.expectedDate.present
          ? data.expectedDate.value
          : this.expectedDate,
      actualMinor: data.actualMinor.present
          ? data.actualMinor.value
          : this.actualMinor,
      earnedDate: data.earnedDate.present
          ? data.earnedDate.value
          : this.earnedDate,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      nonCash: data.nonCash.present ? data.nonCash.value : this.nonCash,
      countsAsEarnings: data.countsAsEarnings.present
          ? data.countsAsEarnings.value
          : this.countsAsEarnings,
      includeInForecast: data.includeInForecast.present
          ? data.includeInForecast.value
          : this.includeInForecast,
      taxNote: data.taxNote.present ? data.taxNote.value : this.taxNote,
      notes: data.notes.present ? data.notes.value : this.notes,
      cancelled: data.cancelled.present ? data.cancelled.value : this.cancelled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompensationItemRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('expectedMinor: $expectedMinor, ')
          ..write('expectedDate: $expectedDate, ')
          ..write('actualMinor: $actualMinor, ')
          ..write('earnedDate: $earnedDate, ')
          ..write('recurrence: $recurrence, ')
          ..write('nonCash: $nonCash, ')
          ..write('countsAsEarnings: $countsAsEarnings, ')
          ..write('includeInForecast: $includeInForecast, ')
          ..write('taxNote: $taxNote, ')
          ..write('notes: $notes, ')
          ..write('cancelled: $cancelled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    type,
    title,
    currencyCode,
    expectedMinor,
    expectedDate,
    actualMinor,
    earnedDate,
    recurrence,
    nonCash,
    countsAsEarnings,
    includeInForecast,
    taxNote,
    notes,
    cancelled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompensationItemRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.type == this.type &&
          other.title == this.title &&
          other.currencyCode == this.currencyCode &&
          other.expectedMinor == this.expectedMinor &&
          other.expectedDate == this.expectedDate &&
          other.actualMinor == this.actualMinor &&
          other.earnedDate == this.earnedDate &&
          other.recurrence == this.recurrence &&
          other.nonCash == this.nonCash &&
          other.countsAsEarnings == this.countsAsEarnings &&
          other.includeInForecast == this.includeInForecast &&
          other.taxNote == this.taxNote &&
          other.notes == this.notes &&
          other.cancelled == this.cancelled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CompensationItemsCompanion extends UpdateCompanion<CompensationItemRow> {
  final Value<String> id;
  final Value<String?> sourceId;
  final Value<String> type;
  final Value<String> title;
  final Value<String> currencyCode;
  final Value<int?> expectedMinor;
  final Value<String?> expectedDate;
  final Value<int?> actualMinor;
  final Value<String?> earnedDate;
  final Value<String> recurrence;
  final Value<bool> nonCash;
  final Value<bool> countsAsEarnings;
  final Value<bool> includeInForecast;
  final Value<String?> taxNote;
  final Value<String?> notes;
  final Value<bool> cancelled;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CompensationItemsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.expectedMinor = const Value.absent(),
    this.expectedDate = const Value.absent(),
    this.actualMinor = const Value.absent(),
    this.earnedDate = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.nonCash = const Value.absent(),
    this.countsAsEarnings = const Value.absent(),
    this.includeInForecast = const Value.absent(),
    this.taxNote = const Value.absent(),
    this.notes = const Value.absent(),
    this.cancelled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompensationItemsCompanion.insert({
    required String id,
    this.sourceId = const Value.absent(),
    required String type,
    required String title,
    required String currencyCode,
    this.expectedMinor = const Value.absent(),
    this.expectedDate = const Value.absent(),
    this.actualMinor = const Value.absent(),
    this.earnedDate = const Value.absent(),
    required String recurrence,
    this.nonCash = const Value.absent(),
    this.countsAsEarnings = const Value.absent(),
    this.includeInForecast = const Value.absent(),
    this.taxNote = const Value.absent(),
    this.notes = const Value.absent(),
    this.cancelled = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       currencyCode = Value(currencyCode),
       recurrence = Value(recurrence),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CompensationItemRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? currencyCode,
    Expression<int>? expectedMinor,
    Expression<String>? expectedDate,
    Expression<int>? actualMinor,
    Expression<String>? earnedDate,
    Expression<String>? recurrence,
    Expression<bool>? nonCash,
    Expression<bool>? countsAsEarnings,
    Expression<bool>? includeInForecast,
    Expression<String>? taxNote,
    Expression<String>? notes,
    Expression<bool>? cancelled,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (expectedMinor != null) 'expected_minor': expectedMinor,
      if (expectedDate != null) 'expected_date': expectedDate,
      if (actualMinor != null) 'actual_minor': actualMinor,
      if (earnedDate != null) 'earned_date': earnedDate,
      if (recurrence != null) 'recurrence': recurrence,
      if (nonCash != null) 'non_cash': nonCash,
      if (countsAsEarnings != null) 'counts_as_earnings': countsAsEarnings,
      if (includeInForecast != null) 'include_in_forecast': includeInForecast,
      if (taxNote != null) 'tax_note': taxNote,
      if (notes != null) 'notes': notes,
      if (cancelled != null) 'cancelled': cancelled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompensationItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? sourceId,
    Value<String>? type,
    Value<String>? title,
    Value<String>? currencyCode,
    Value<int?>? expectedMinor,
    Value<String?>? expectedDate,
    Value<int?>? actualMinor,
    Value<String?>? earnedDate,
    Value<String>? recurrence,
    Value<bool>? nonCash,
    Value<bool>? countsAsEarnings,
    Value<bool>? includeInForecast,
    Value<String?>? taxNote,
    Value<String?>? notes,
    Value<bool>? cancelled,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CompensationItemsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      type: type ?? this.type,
      title: title ?? this.title,
      currencyCode: currencyCode ?? this.currencyCode,
      expectedMinor: expectedMinor ?? this.expectedMinor,
      expectedDate: expectedDate ?? this.expectedDate,
      actualMinor: actualMinor ?? this.actualMinor,
      earnedDate: earnedDate ?? this.earnedDate,
      recurrence: recurrence ?? this.recurrence,
      nonCash: nonCash ?? this.nonCash,
      countsAsEarnings: countsAsEarnings ?? this.countsAsEarnings,
      includeInForecast: includeInForecast ?? this.includeInForecast,
      taxNote: taxNote ?? this.taxNote,
      notes: notes ?? this.notes,
      cancelled: cancelled ?? this.cancelled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (expectedMinor.present) {
      map['expected_minor'] = Variable<int>(expectedMinor.value);
    }
    if (expectedDate.present) {
      map['expected_date'] = Variable<String>(expectedDate.value);
    }
    if (actualMinor.present) {
      map['actual_minor'] = Variable<int>(actualMinor.value);
    }
    if (earnedDate.present) {
      map['earned_date'] = Variable<String>(earnedDate.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (nonCash.present) {
      map['non_cash'] = Variable<bool>(nonCash.value);
    }
    if (countsAsEarnings.present) {
      map['counts_as_earnings'] = Variable<bool>(countsAsEarnings.value);
    }
    if (includeInForecast.present) {
      map['include_in_forecast'] = Variable<bool>(includeInForecast.value);
    }
    if (taxNote.present) {
      map['tax_note'] = Variable<String>(taxNote.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (cancelled.present) {
      map['cancelled'] = Variable<bool>(cancelled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompensationItemsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('expectedMinor: $expectedMinor, ')
          ..write('expectedDate: $expectedDate, ')
          ..write('actualMinor: $actualMinor, ')
          ..write('earnedDate: $earnedDate, ')
          ..write('recurrence: $recurrence, ')
          ..write('nonCash: $nonCash, ')
          ..write('countsAsEarnings: $countsAsEarnings, ')
          ..write('includeInForecast: $includeInForecast, ')
          ..write('taxNote: $taxNote, ')
          ..write('notes: $notes, ')
          ..write('cancelled: $cancelled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthlyRecordsTable extends MonthlyRecords
    with TableInfo<$MonthlyRecordsTable, MonthlyRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES income_sources (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalEstimateMinorMeta =
      const VerificationMeta('originalEstimateMinor');
  @override
  late final GeneratedColumn<int> originalEstimateMinor = GeneratedColumn<int>(
    'original_estimate_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisedEstimateMinorMeta =
      const VerificationMeta('revisedEstimateMinor');
  @override
  late final GeneratedColumn<int> revisedEstimateMinor = GeneratedColumn<int>(
    'revised_estimate_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualMinorMeta = const VerificationMeta(
    'actualMinor',
  );
  @override
  late final GeneratedColumn<int> actualMinor = GeneratedColumn<int>(
    'actual_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalizedMeta = const VerificationMeta(
    'finalized',
  );
  @override
  late final GeneratedColumn<bool> finalized = GeneratedColumn<bool>(
    'finalized',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finalized" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _finalizedAtMeta = const VerificationMeta(
    'finalizedAt',
  );
  @override
  late final GeneratedColumn<int> finalizedAt = GeneratedColumn<int>(
    'finalized_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    month,
    originalEstimateMinor,
    revisedEstimateMinor,
    actualMinor,
    finalized,
    finalizedAt,
    notes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlyRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('original_estimate_minor')) {
      context.handle(
        _originalEstimateMinorMeta,
        originalEstimateMinor.isAcceptableOrUnknown(
          data['original_estimate_minor']!,
          _originalEstimateMinorMeta,
        ),
      );
    }
    if (data.containsKey('revised_estimate_minor')) {
      context.handle(
        _revisedEstimateMinorMeta,
        revisedEstimateMinor.isAcceptableOrUnknown(
          data['revised_estimate_minor']!,
          _revisedEstimateMinorMeta,
        ),
      );
    }
    if (data.containsKey('actual_minor')) {
      context.handle(
        _actualMinorMeta,
        actualMinor.isAcceptableOrUnknown(
          data['actual_minor']!,
          _actualMinorMeta,
        ),
      );
    }
    if (data.containsKey('finalized')) {
      context.handle(
        _finalizedMeta,
        finalized.isAcceptableOrUnknown(data['finalized']!, _finalizedMeta),
      );
    }
    if (data.containsKey('finalized_at')) {
      context.handle(
        _finalizedAtMeta,
        finalizedAt.isAcceptableOrUnknown(
          data['finalized_at']!,
          _finalizedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceId, month},
  ];
  @override
  MonthlyRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month'],
      )!,
      originalEstimateMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_estimate_minor'],
      ),
      revisedEstimateMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revised_estimate_minor'],
      ),
      actualMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_minor'],
      ),
      finalized: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finalized'],
      )!,
      finalizedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finalized_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MonthlyRecordsTable createAlias(String alias) {
    return $MonthlyRecordsTable(attachedDatabase, alias);
  }
}

class MonthlyRecordRow extends DataClass
    implements Insertable<MonthlyRecordRow> {
  final String id;
  final String sourceId;
  final String month;
  final int? originalEstimateMinor;
  final int? revisedEstimateMinor;
  final int? actualMinor;
  final bool finalized;
  final int? finalizedAt;
  final String? notes;
  final int updatedAt;
  const MonthlyRecordRow({
    required this.id,
    required this.sourceId,
    required this.month,
    this.originalEstimateMinor,
    this.revisedEstimateMinor,
    this.actualMinor,
    required this.finalized,
    this.finalizedAt,
    this.notes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['month'] = Variable<String>(month);
    if (!nullToAbsent || originalEstimateMinor != null) {
      map['original_estimate_minor'] = Variable<int>(originalEstimateMinor);
    }
    if (!nullToAbsent || revisedEstimateMinor != null) {
      map['revised_estimate_minor'] = Variable<int>(revisedEstimateMinor);
    }
    if (!nullToAbsent || actualMinor != null) {
      map['actual_minor'] = Variable<int>(actualMinor);
    }
    map['finalized'] = Variable<bool>(finalized);
    if (!nullToAbsent || finalizedAt != null) {
      map['finalized_at'] = Variable<int>(finalizedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  MonthlyRecordsCompanion toCompanion(bool nullToAbsent) {
    return MonthlyRecordsCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      month: Value(month),
      originalEstimateMinor: originalEstimateMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(originalEstimateMinor),
      revisedEstimateMinor: revisedEstimateMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(revisedEstimateMinor),
      actualMinor: actualMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(actualMinor),
      finalized: Value(finalized),
      finalizedAt: finalizedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finalizedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      updatedAt: Value(updatedAt),
    );
  }

  factory MonthlyRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyRecordRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      month: serializer.fromJson<String>(json['month']),
      originalEstimateMinor: serializer.fromJson<int?>(
        json['originalEstimateMinor'],
      ),
      revisedEstimateMinor: serializer.fromJson<int?>(
        json['revisedEstimateMinor'],
      ),
      actualMinor: serializer.fromJson<int?>(json['actualMinor']),
      finalized: serializer.fromJson<bool>(json['finalized']),
      finalizedAt: serializer.fromJson<int?>(json['finalizedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'month': serializer.toJson<String>(month),
      'originalEstimateMinor': serializer.toJson<int?>(originalEstimateMinor),
      'revisedEstimateMinor': serializer.toJson<int?>(revisedEstimateMinor),
      'actualMinor': serializer.toJson<int?>(actualMinor),
      'finalized': serializer.toJson<bool>(finalized),
      'finalizedAt': serializer.toJson<int?>(finalizedAt),
      'notes': serializer.toJson<String?>(notes),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  MonthlyRecordRow copyWith({
    String? id,
    String? sourceId,
    String? month,
    Value<int?> originalEstimateMinor = const Value.absent(),
    Value<int?> revisedEstimateMinor = const Value.absent(),
    Value<int?> actualMinor = const Value.absent(),
    bool? finalized,
    Value<int?> finalizedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? updatedAt,
  }) => MonthlyRecordRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    month: month ?? this.month,
    originalEstimateMinor: originalEstimateMinor.present
        ? originalEstimateMinor.value
        : this.originalEstimateMinor,
    revisedEstimateMinor: revisedEstimateMinor.present
        ? revisedEstimateMinor.value
        : this.revisedEstimateMinor,
    actualMinor: actualMinor.present ? actualMinor.value : this.actualMinor,
    finalized: finalized ?? this.finalized,
    finalizedAt: finalizedAt.present ? finalizedAt.value : this.finalizedAt,
    notes: notes.present ? notes.value : this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MonthlyRecordRow copyWithCompanion(MonthlyRecordsCompanion data) {
    return MonthlyRecordRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      month: data.month.present ? data.month.value : this.month,
      originalEstimateMinor: data.originalEstimateMinor.present
          ? data.originalEstimateMinor.value
          : this.originalEstimateMinor,
      revisedEstimateMinor: data.revisedEstimateMinor.present
          ? data.revisedEstimateMinor.value
          : this.revisedEstimateMinor,
      actualMinor: data.actualMinor.present
          ? data.actualMinor.value
          : this.actualMinor,
      finalized: data.finalized.present ? data.finalized.value : this.finalized,
      finalizedAt: data.finalizedAt.present
          ? data.finalizedAt.value
          : this.finalizedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyRecordRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('month: $month, ')
          ..write('originalEstimateMinor: $originalEstimateMinor, ')
          ..write('revisedEstimateMinor: $revisedEstimateMinor, ')
          ..write('actualMinor: $actualMinor, ')
          ..write('finalized: $finalized, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    month,
    originalEstimateMinor,
    revisedEstimateMinor,
    actualMinor,
    finalized,
    finalizedAt,
    notes,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyRecordRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.month == this.month &&
          other.originalEstimateMinor == this.originalEstimateMinor &&
          other.revisedEstimateMinor == this.revisedEstimateMinor &&
          other.actualMinor == this.actualMinor &&
          other.finalized == this.finalized &&
          other.finalizedAt == this.finalizedAt &&
          other.notes == this.notes &&
          other.updatedAt == this.updatedAt);
}

class MonthlyRecordsCompanion extends UpdateCompanion<MonthlyRecordRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String> month;
  final Value<int?> originalEstimateMinor;
  final Value<int?> revisedEstimateMinor;
  final Value<int?> actualMinor;
  final Value<bool> finalized;
  final Value<int?> finalizedAt;
  final Value<String?> notes;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const MonthlyRecordsCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.month = const Value.absent(),
    this.originalEstimateMinor = const Value.absent(),
    this.revisedEstimateMinor = const Value.absent(),
    this.actualMinor = const Value.absent(),
    this.finalized = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthlyRecordsCompanion.insert({
    required String id,
    required String sourceId,
    required String month,
    this.originalEstimateMinor = const Value.absent(),
    this.revisedEstimateMinor = const Value.absent(),
    this.actualMinor = const Value.absent(),
    this.finalized = const Value.absent(),
    this.finalizedAt = const Value.absent(),
    this.notes = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       month = Value(month),
       updatedAt = Value(updatedAt);
  static Insertable<MonthlyRecordRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? month,
    Expression<int>? originalEstimateMinor,
    Expression<int>? revisedEstimateMinor,
    Expression<int>? actualMinor,
    Expression<bool>? finalized,
    Expression<int>? finalizedAt,
    Expression<String>? notes,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (month != null) 'month': month,
      if (originalEstimateMinor != null)
        'original_estimate_minor': originalEstimateMinor,
      if (revisedEstimateMinor != null)
        'revised_estimate_minor': revisedEstimateMinor,
      if (actualMinor != null) 'actual_minor': actualMinor,
      if (finalized != null) 'finalized': finalized,
      if (finalizedAt != null) 'finalized_at': finalizedAt,
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthlyRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String>? month,
    Value<int?>? originalEstimateMinor,
    Value<int?>? revisedEstimateMinor,
    Value<int?>? actualMinor,
    Value<bool>? finalized,
    Value<int?>? finalizedAt,
    Value<String?>? notes,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return MonthlyRecordsCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      month: month ?? this.month,
      originalEstimateMinor:
          originalEstimateMinor ?? this.originalEstimateMinor,
      revisedEstimateMinor: revisedEstimateMinor ?? this.revisedEstimateMinor,
      actualMinor: actualMinor ?? this.actualMinor,
      finalized: finalized ?? this.finalized,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (originalEstimateMinor.present) {
      map['original_estimate_minor'] = Variable<int>(
        originalEstimateMinor.value,
      );
    }
    if (revisedEstimateMinor.present) {
      map['revised_estimate_minor'] = Variable<int>(revisedEstimateMinor.value);
    }
    if (actualMinor.present) {
      map['actual_minor'] = Variable<int>(actualMinor.value);
    }
    if (finalized.present) {
      map['finalized'] = Variable<bool>(finalized.value);
    }
    if (finalizedAt.present) {
      map['finalized_at'] = Variable<int>(finalizedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyRecordsCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('month: $month, ')
          ..write('originalEstimateMinor: $originalEstimateMinor, ')
          ..write('revisedEstimateMinor: $revisedEstimateMinor, ')
          ..write('actualMinor: $actualMinor, ')
          ..write('finalized: $finalized, ')
          ..write('finalizedAt: $finalizedAt, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES income_sources (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES compensation_items (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodMonthMeta = const VerificationMeta(
    'periodMonth',
  );
  @override
  late final GeneratedColumn<String> periodMonth = GeneratedColumn<String>(
    'period_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dedupeKeyMeta = const VerificationMeta(
    'dedupeKey',
  );
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
    'dedupe_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    itemId,
    type,
    amountMinor,
    currencyCode,
    periodMonth,
    date,
    status,
    dedupeKey,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('period_month')) {
      context.handle(
        _periodMonthMeta,
        periodMonth.isAcceptableOrUnknown(
          data['period_month']!,
          _periodMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodMonthMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(
        _dedupeKeyMeta,
        dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      periodMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_month'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      dedupeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dedupe_key'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class LedgerEntryRow extends DataClass implements Insertable<LedgerEntryRow> {
  final String id;
  final String sourceId;
  final String? itemId;
  final String type;
  final int amountMinor;
  final String currencyCode;
  final String periodMonth;
  final String date;
  final String status;
  final String? dedupeKey;
  final String? notes;
  final int createdAt;
  final int updatedAt;
  const LedgerEntryRow({
    required this.id,
    required this.sourceId,
    this.itemId,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.periodMonth,
    required this.date,
    required this.status,
    this.dedupeKey,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    map['type'] = Variable<String>(type);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['period_month'] = Variable<String>(periodMonth);
    map['date'] = Variable<String>(date);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dedupeKey != null) {
      map['dedupe_key'] = Variable<String>(dedupeKey);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      type: Value(type),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      periodMonth: Value(periodMonth),
      date: Value(date),
      status: Value(status),
      dedupeKey: dedupeKey == null && nullToAbsent
          ? const Value.absent()
          : Value(dedupeKey),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LedgerEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntryRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      type: serializer.fromJson<String>(json['type']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      periodMonth: serializer.fromJson<String>(json['periodMonth']),
      date: serializer.fromJson<String>(json['date']),
      status: serializer.fromJson<String>(json['status']),
      dedupeKey: serializer.fromJson<String?>(json['dedupeKey']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'itemId': serializer.toJson<String?>(itemId),
      'type': serializer.toJson<String>(type),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'periodMonth': serializer.toJson<String>(periodMonth),
      'date': serializer.toJson<String>(date),
      'status': serializer.toJson<String>(status),
      'dedupeKey': serializer.toJson<String?>(dedupeKey),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LedgerEntryRow copyWith({
    String? id,
    String? sourceId,
    Value<String?> itemId = const Value.absent(),
    String? type,
    int? amountMinor,
    String? currencyCode,
    String? periodMonth,
    String? date,
    String? status,
    Value<String?> dedupeKey = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => LedgerEntryRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    itemId: itemId.present ? itemId.value : this.itemId,
    type: type ?? this.type,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    periodMonth: periodMonth ?? this.periodMonth,
    date: date ?? this.date,
    status: status ?? this.status,
    dedupeKey: dedupeKey.present ? dedupeKey.value : this.dedupeKey,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LedgerEntryRow copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntryRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      type: data.type.present ? data.type.value : this.type,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      periodMonth: data.periodMonth.present
          ? data.periodMonth.value
          : this.periodMonth,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntryRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('periodMonth: $periodMonth, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceId,
    itemId,
    type,
    amountMinor,
    currencyCode,
    periodMonth,
    date,
    status,
    dedupeKey,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntryRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.itemId == this.itemId &&
          other.type == this.type &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.periodMonth == this.periodMonth &&
          other.date == this.date &&
          other.status == this.status &&
          other.dedupeKey == this.dedupeKey &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntryRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<String?> itemId;
  final Value<String> type;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<String> periodMonth;
  final Value<String> date;
  final Value<String> status;
  final Value<String?> dedupeKey;
  final Value<String?> notes;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.type = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.periodMonth = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    required String id,
    required String sourceId,
    this.itemId = const Value.absent(),
    required String type,
    required int amountMinor,
    required String currencyCode,
    required String periodMonth,
    required String date,
    required String status,
    this.dedupeKey = const Value.absent(),
    this.notes = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceId = Value(sourceId),
       type = Value(type),
       amountMinor = Value(amountMinor),
       currencyCode = Value(currencyCode),
       periodMonth = Value(periodMonth),
       date = Value(date),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LedgerEntryRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<String>? itemId,
    Expression<String>? type,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? periodMonth,
    Expression<String>? date,
    Expression<String>? status,
    Expression<String>? dedupeKey,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (itemId != null) 'item_id': itemId,
      if (type != null) 'type': type,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (periodMonth != null) 'period_month': periodMonth,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceId,
    Value<String?>? itemId,
    Value<String>? type,
    Value<int>? amountMinor,
    Value<String>? currencyCode,
    Value<String>? periodMonth,
    Value<String>? date,
    Value<String>? status,
    Value<String?>? dedupeKey,
    Value<String?>? notes,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      periodMonth: periodMonth ?? this.periodMonth,
      date: date ?? this.date,
      status: status ?? this.status,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (periodMonth.present) {
      map['period_month'] = Variable<String>(periodMonth.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('itemId: $itemId, ')
          ..write('type: $type, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('periodMonth: $periodMonth, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES income_sources (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindMeta = const VerificationMeta('remind');
  @override
  late final GeneratedColumn<bool> remind = GeneratedColumn<bool>(
    'remind',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remind" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cancelledMeta = const VerificationMeta(
    'cancelled',
  );
  @override
  late final GeneratedColumn<bool> cancelled = GeneratedColumn<bool>(
    'cancelled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cancelled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    date,
    type,
    sourceId,
    amountMinor,
    notes,
    remind,
    cancelled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('remind')) {
      context.handle(
        _remindMeta,
        remind.isAcceptableOrUnknown(data['remind']!, _remindMeta),
      );
    }
    if (data.containsKey('cancelled')) {
      context.handle(
        _cancelledMeta,
        cancelled.isAcceptableOrUnknown(data['cancelled']!, _cancelledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      remind: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remind'],
      )!,
      cancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cancelled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }
}

class CalendarEventRow extends DataClass
    implements Insertable<CalendarEventRow> {
  final String id;
  final String title;
  final String date;
  final String type;
  final String? sourceId;
  final int? amountMinor;
  final String? notes;
  final bool remind;
  final bool cancelled;
  final int createdAt;
  const CalendarEventRow({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.sourceId,
    this.amountMinor,
    this.notes,
    required this.remind,
    required this.cancelled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['remind'] = Variable<bool>(remind);
    map['cancelled'] = Variable<bool>(cancelled);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      type: Value(type),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      remind: Value(remind),
      cancelled: Value(cancelled),
      createdAt: Value(createdAt),
    );
  }

  factory CalendarEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEventRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      notes: serializer.fromJson<String?>(json['notes']),
      remind: serializer.fromJson<bool>(json['remind']),
      cancelled: serializer.fromJson<bool>(json['cancelled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'sourceId': serializer.toJson<String?>(sourceId),
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'notes': serializer.toJson<String?>(notes),
      'remind': serializer.toJson<bool>(remind),
      'cancelled': serializer.toJson<bool>(cancelled),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CalendarEventRow copyWith({
    String? id,
    String? title,
    String? date,
    String? type,
    Value<String?> sourceId = const Value.absent(),
    Value<int?> amountMinor = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? remind,
    bool? cancelled,
    int? createdAt,
  }) => CalendarEventRow(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    type: type ?? this.type,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    notes: notes.present ? notes.value : this.notes,
    remind: remind ?? this.remind,
    cancelled: cancelled ?? this.cancelled,
    createdAt: createdAt ?? this.createdAt,
  );
  CalendarEventRow copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEventRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      notes: data.notes.present ? data.notes.value : this.notes,
      remind: data.remind.present ? data.remind.value : this.remind,
      cancelled: data.cancelled.present ? data.cancelled.value : this.cancelled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('sourceId: $sourceId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('notes: $notes, ')
          ..write('remind: $remind, ')
          ..write('cancelled: $cancelled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    date,
    type,
    sourceId,
    amountMinor,
    notes,
    remind,
    cancelled,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEventRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.date == this.date &&
          other.type == this.type &&
          other.sourceId == this.sourceId &&
          other.amountMinor == this.amountMinor &&
          other.notes == this.notes &&
          other.remind == this.remind &&
          other.cancelled == this.cancelled &&
          other.createdAt == this.createdAt);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEventRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> date;
  final Value<String> type;
  final Value<String?> sourceId;
  final Value<int?> amountMinor;
  final Value<String?> notes;
  final Value<bool> remind;
  final Value<bool> cancelled;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.notes = const Value.absent(),
    this.remind = const Value.absent(),
    this.cancelled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    required String title,
    required String date,
    required String type,
    this.sourceId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.notes = const Value.absent(),
    this.remind = const Value.absent(),
    this.cancelled = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       date = Value(date),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<CalendarEventRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? date,
    Expression<String>? type,
    Expression<String>? sourceId,
    Expression<int>? amountMinor,
    Expression<String>? notes,
    Expression<bool>? remind,
    Expression<bool>? cancelled,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (sourceId != null) 'source_id': sourceId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (notes != null) 'notes': notes,
      if (remind != null) 'remind': remind,
      if (cancelled != null) 'cancelled': cancelled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? date,
    Value<String>? type,
    Value<String?>? sourceId,
    Value<int?>? amountMinor,
    Value<String?>? notes,
    Value<bool>? remind,
    Value<bool>? cancelled,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      type: type ?? this.type,
      sourceId: sourceId ?? this.sourceId,
      amountMinor: amountMinor ?? this.amountMinor,
      notes: notes ?? this.notes,
      remind: remind ?? this.remind,
      cancelled: cancelled ?? this.cancelled,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (remind.present) {
      map['remind'] = Variable<bool>(remind.value);
    }
    if (cancelled.present) {
      map['cancelled'] = Variable<bool>(cancelled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('sourceId: $sourceId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('notes: $notes, ')
          ..write('remind: $remind, ')
          ..write('cancelled: $cancelled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog with TableInfo<$AuditLogTable, AuditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
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
  static const VerificationMeta _beforeJsonMeta = const VerificationMeta(
    'beforeJson',
  );
  @override
  late final GeneratedColumn<String> beforeJson = GeneratedColumn<String>(
    'before_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _afterJsonMeta = const VerificationMeta(
    'afterJson',
  );
  @override
  late final GeneratedColumn<String> afterJson = GeneratedColumn<String>(
    'after_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    action,
    summary,
    beforeJson,
    afterJson,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('before_json')) {
      context.handle(
        _beforeJsonMeta,
        beforeJson.isAcceptableOrUnknown(data['before_json']!, _beforeJsonMeta),
      );
    }
    if (data.containsKey('after_json')) {
      context.handle(
        _afterJsonMeta,
        afterJson.isAcceptableOrUnknown(data['after_json']!, _afterJsonMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
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
      beforeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before_json'],
      ),
      afterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after_json'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditRow extends DataClass implements Insertable<AuditRow> {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String summary;
  final String? beforeJson;
  final String? afterJson;
  final int at;
  const AuditRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.summary,
    this.beforeJson,
    this.afterJson,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || beforeJson != null) {
      map['before_json'] = Variable<String>(beforeJson);
    }
    if (!nullToAbsent || afterJson != null) {
      map['after_json'] = Variable<String>(afterJson);
    }
    map['at'] = Variable<int>(at);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      summary: Value(summary),
      beforeJson: beforeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(beforeJson),
      afterJson: afterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(afterJson),
      at: Value(at),
    );
  }

  factory AuditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditRow(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      summary: serializer.fromJson<String>(json['summary']),
      beforeJson: serializer.fromJson<String?>(json['beforeJson']),
      afterJson: serializer.fromJson<String?>(json['afterJson']),
      at: serializer.fromJson<int>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'summary': serializer.toJson<String>(summary),
      'beforeJson': serializer.toJson<String?>(beforeJson),
      'afterJson': serializer.toJson<String?>(afterJson),
      'at': serializer.toJson<int>(at),
    };
  }

  AuditRow copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? action,
    String? summary,
    Value<String?> beforeJson = const Value.absent(),
    Value<String?> afterJson = const Value.absent(),
    int? at,
  }) => AuditRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    summary: summary ?? this.summary,
    beforeJson: beforeJson.present ? beforeJson.value : this.beforeJson,
    afterJson: afterJson.present ? afterJson.value : this.afterJson,
    at: at ?? this.at,
  );
  AuditRow copyWithCompanion(AuditLogCompanion data) {
    return AuditRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      summary: data.summary.present ? data.summary.value : this.summary,
      beforeJson: data.beforeJson.present
          ? data.beforeJson.value
          : this.beforeJson,
      afterJson: data.afterJson.present ? data.afterJson.value : this.afterJson,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('summary: $summary, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    action,
    summary,
    beforeJson,
    afterJson,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.summary == this.summary &&
          other.beforeJson == this.beforeJson &&
          other.afterJson == this.afterJson &&
          other.at == this.at);
}

class AuditLogCompanion extends UpdateCompanion<AuditRow> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> summary;
  final Value<String?> beforeJson;
  final Value<String?> afterJson;
  final Value<int> at;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.summary = const Value.absent(),
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String action,
    required String summary,
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    required int at,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       summary = Value(summary),
       at = Value(at);
  static Insertable<AuditRow> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? summary,
    Expression<String>? beforeJson,
    Expression<String>? afterJson,
    Expression<int>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (summary != null) 'summary': summary,
      if (beforeJson != null) 'before_json': beforeJson,
      if (afterJson != null) 'after_json': afterJson,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<String>? summary,
    Value<String?>? beforeJson,
    Value<String?>? afterJson,
    Value<int>? at,
    Value<int>? rowid,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      summary: summary ?? this.summary,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    if (beforeJson.present) {
      map['before_json'] = Variable<String>(beforeJson.value);
    }
    if (afterJson.present) {
      map['after_json'] = Variable<String>(afterJson.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('summary: $summary, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationHistoryTable extends NotificationHistory
    with TableInfo<$NotificationHistoryTable, NotificationHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledForMeta = const VerificationMeta(
    'scheduledFor',
  );
  @override
  late final GeneratedColumn<int> scheduledFor = GeneratedColumn<int>(
    'scheduled_for',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    category,
    title,
    scheduledFor,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('scheduled_for')) {
      context.handle(
        _scheduledForMeta,
        scheduledFor.isAcceptableOrUnknown(
          data['scheduled_for']!,
          _scheduledForMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledForMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  NotificationHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationHistoryRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      scheduledFor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_for'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NotificationHistoryTable createAlias(String alias) {
    return $NotificationHistoryTable(attachedDatabase, alias);
  }
}

class NotificationHistoryRow extends DataClass
    implements Insertable<NotificationHistoryRow> {
  final String key;
  final String category;
  final String title;
  final int scheduledFor;
  final int createdAt;
  const NotificationHistoryRow({
    required this.key,
    required this.category,
    required this.title,
    required this.scheduledFor,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    map['scheduled_for'] = Variable<int>(scheduledFor);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  NotificationHistoryCompanion toCompanion(bool nullToAbsent) {
    return NotificationHistoryCompanion(
      key: Value(key),
      category: Value(category),
      title: Value(title),
      scheduledFor: Value(scheduledFor),
      createdAt: Value(createdAt),
    );
  }

  factory NotificationHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationHistoryRow(
      key: serializer.fromJson<String>(json['key']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      scheduledFor: serializer.fromJson<int>(json['scheduledFor']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'scheduledFor': serializer.toJson<int>(scheduledFor),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  NotificationHistoryRow copyWith({
    String? key,
    String? category,
    String? title,
    int? scheduledFor,
    int? createdAt,
  }) => NotificationHistoryRow(
    key: key ?? this.key,
    category: category ?? this.category,
    title: title ?? this.title,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    createdAt: createdAt ?? this.createdAt,
  );
  NotificationHistoryRow copyWithCompanion(NotificationHistoryCompanion data) {
    return NotificationHistoryRow(
      key: data.key.present ? data.key.value : this.key,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationHistoryRow(')
          ..write('key: $key, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, category, title, scheduledFor, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationHistoryRow &&
          other.key == this.key &&
          other.category == this.category &&
          other.title == this.title &&
          other.scheduledFor == this.scheduledFor &&
          other.createdAt == this.createdAt);
}

class NotificationHistoryCompanion
    extends UpdateCompanion<NotificationHistoryRow> {
  final Value<String> key;
  final Value<String> category;
  final Value<String> title;
  final Value<int> scheduledFor;
  final Value<int> createdAt;
  final Value<int> rowid;
  const NotificationHistoryCompanion({
    this.key = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationHistoryCompanion.insert({
    required String key,
    required String category,
    required String title,
    required int scheduledFor,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       category = Value(category),
       title = Value(title),
       scheduledFor = Value(scheduledFor),
       createdAt = Value(createdAt);
  static Insertable<NotificationHistoryRow> custom({
    Expression<String>? key,
    Expression<String>? category,
    Expression<String>? title,
    Expression<int>? scheduledFor,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationHistoryCompanion copyWith({
    Value<String>? key,
    Value<String>? category,
    Value<String>? title,
    Value<int>? scheduledFor,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return NotificationHistoryCompanion(
      key: key ?? this.key,
      category: category ?? this.category,
      title: title ?? this.title,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<int>(scheduledFor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationHistoryCompanion(')
          ..write('key: $key, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $IncomeSourcesTable incomeSources = $IncomeSourcesTable(this);
  late final $RateRevisionsTable rateRevisions = $RateRevisionsTable(this);
  late final $SourcePausesTable sourcePauses = $SourcePausesTable(this);
  late final $DayOverridesTable dayOverrides = $DayOverridesTable(this);
  late final $CompensationItemsTable compensationItems =
      $CompensationItemsTable(this);
  late final $MonthlyRecordsTable monthlyRecords = $MonthlyRecordsTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $NotificationHistoryTable notificationHistory =
      $NotificationHistoryTable(this);
  late final Index idxRateRevisionsSource = Index(
    'idx_rate_revisions_source',
    'CREATE INDEX idx_rate_revisions_source ON rate_revisions (source_id, effective_from)',
  );
  late final Index idxDayOverridesDate = Index(
    'idx_day_overrides_date',
    'CREATE INDEX idx_day_overrides_date ON day_overrides (date)',
  );
  late final Index idxItemsSource = Index(
    'idx_items_source',
    'CREATE INDEX idx_items_source ON compensation_items (source_id)',
  );
  late final Index idxLedgerSourcePeriod = Index(
    'idx_ledger_source_period',
    'CREATE INDEX idx_ledger_source_period ON ledger_entries (source_id, period_month)',
  );
  late final Index idxLedgerDate = Index(
    'idx_ledger_date',
    'CREATE INDEX idx_ledger_date ON ledger_entries (date)',
  );
  late final Index idxEventsDate = Index(
    'idx_events_date',
    'CREATE INDEX idx_events_date ON calendar_events (date)',
  );
  late final Index idxAuditEntity = Index(
    'idx_audit_entity',
    'CREATE INDEX idx_audit_entity ON audit_log (entity_type, entity_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    settings,
    incomeSources,
    rateRevisions,
    sourcePauses,
    dayOverrides,
    compensationItems,
    monthlyRecords,
    ledgerEntries,
    calendarEvents,
    auditLog,
    notificationHistory,
    idxRateRevisionsSource,
    idxDayOverridesDate,
    idxItemsSource,
    idxLedgerSourcePeriod,
    idxLedgerDate,
    idxEventsDate,
    idxAuditEntity,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required String displayName,
  required String currencyCode,
  required String locale,
  required String timezone,
  Value<String?> dateOfBirth,
  Value<bool> onboardingComplete,
  required int createdAt,
  required int updatedAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> displayName,
  Value<String> currencyCode,
  Value<String> locale,
  Value<String> timezone,
  Value<String?> dateOfBirth,
  Value<bool> onboardingComplete,
  Value<int> createdAt,
  Value<int> updatedAt,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
    column: $table.dateOfBirth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String?> dateOfBirth = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                displayName: displayName,
                currencyCode: currencyCode,
                locale: locale,
                timezone: timezone,
                dateOfBirth: dateOfBirth,
                onboardingComplete: onboardingComplete,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                required String currencyCode,
                required String locale,
                required String timezone,
                Value<String?> dateOfBirth = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                currencyCode: currencyCode,
                locale: locale,
                timezone: timezone,
                dateOfBirth: dateOfBirth,
                onboardingComplete: onboardingComplete,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, ProfileRow>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$IncomeSourcesTableCreateCompanionBuilder =
    IncomeSourcesCompanion Function({
      required String id,
      required String name,
      required String kind,
      required String category,
      Value<String?> customCategory,
      required String status,
      required String currencyCode,
      required String startDate,
      Value<String?> endDate,
      required String accrualPolicy,
      required int workWeekdayMask,
      required int workStartMinute,
      required int workEndMinute,
      required String payRule,
      required int payDay,
      required int payOffsetMonths,
      required String weekendAdjust,
      Value<String?> expectedPayDate,
      Value<int?> fixedTotalMinor,
      required String fixedTotalAccrual,
      required String forecastMethod,
      Value<String?> employer,
      Value<int?> takeHomeMinor,
      Value<String?> notes,
      Value<int> colorIndex,
      Value<bool> isSample,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$IncomeSourcesTableUpdateCompanionBuilder =
    IncomeSourcesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<String> category,
      Value<String?> customCategory,
      Value<String> status,
      Value<String> currencyCode,
      Value<String> startDate,
      Value<String?> endDate,
      Value<String> accrualPolicy,
      Value<int> workWeekdayMask,
      Value<int> workStartMinute,
      Value<int> workEndMinute,
      Value<String> payRule,
      Value<int> payDay,
      Value<int> payOffsetMonths,
      Value<String> weekendAdjust,
      Value<String?> expectedPayDate,
      Value<int?> fixedTotalMinor,
      Value<String> fixedTotalAccrual,
      Value<String> forecastMethod,
      Value<String?> employer,
      Value<int?> takeHomeMinor,
      Value<String?> notes,
      Value<int> colorIndex,
      Value<bool> isSample,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$IncomeSourcesTableReferences
    extends
        BaseReferences<_$AppDatabase, $IncomeSourcesTable, IncomeSourceRow> {
  $$IncomeSourcesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$RateRevisionsTable, List<RateRevisionRow>>
  _rateRevisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rateRevisions,
    aliasName: 'income_sources__id__rate_revisions__source_id',
  );

  $$RateRevisionsTableProcessedTableManager get rateRevisionsRefs {
    final manager = $$RateRevisionsTableTableManager(
      $_db,
      $_db.rateRevisions,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rateRevisionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SourcePausesTable, List<SourcePauseRow>>
  _sourcePausesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sourcePauses,
    aliasName: 'income_sources__id__source_pauses__source_id',
  );

  $$SourcePausesTableProcessedTableManager get sourcePausesRefs {
    final manager = $$SourcePausesTableTableManager(
      $_db,
      $_db.sourcePauses,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourcePausesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DayOverridesTable, List<DayOverrideRow>>
  _dayOverridesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dayOverrides,
    aliasName: 'income_sources__id__day_overrides__source_id',
  );

  $$DayOverridesTableProcessedTableManager get dayOverridesRefs {
    final manager = $$DayOverridesTableTableManager(
      $_db,
      $_db.dayOverrides,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dayOverridesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompensationItemsTable, List<CompensationItemRow>>
  _compensationItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.compensationItems,
        aliasName: 'income_sources__id__compensation_items__source_id',
      );

  $$CompensationItemsTableProcessedTableManager get compensationItemsRefs {
    final manager = $$CompensationItemsTableTableManager(
      $_db,
      $_db.compensationItems,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _compensationItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MonthlyRecordsTable, List<MonthlyRecordRow>>
  _monthlyRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.monthlyRecords,
    aliasName: 'income_sources__id__monthly_records__source_id',
  );

  $$MonthlyRecordsTableProcessedTableManager get monthlyRecordsRefs {
    final manager = $$MonthlyRecordsTableTableManager(
      $_db,
      $_db.monthlyRecords,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_monthlyRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntryRow>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'income_sources__id__ledger_entries__source_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEventRow>>
  _calendarEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.calendarEvents,
    aliasName: 'income_sources__id__calendar_events__source_id',
  );

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager(
      $_db,
      $_db.calendarEvents,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IncomeSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $IncomeSourcesTable> {
  $$IncomeSourcesTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customCategory => $composableBuilder(
    column: $table.customCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accrualPolicy => $composableBuilder(
    column: $table.accrualPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workWeekdayMask => $composableBuilder(
    column: $table.workWeekdayMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workStartMinute => $composableBuilder(
    column: $table.workStartMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get workEndMinute => $composableBuilder(
    column: $table.workEndMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payRule => $composableBuilder(
    column: $table.payRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payDay => $composableBuilder(
    column: $table.payDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get payOffsetMonths => $composableBuilder(
    column: $table.payOffsetMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekendAdjust => $composableBuilder(
    column: $table.weekendAdjust,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedPayDate => $composableBuilder(
    column: $table.expectedPayDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fixedTotalMinor => $composableBuilder(
    column: $table.fixedTotalMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedTotalAccrual => $composableBuilder(
    column: $table.fixedTotalAccrual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forecastMethod => $composableBuilder(
    column: $table.forecastMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get employer => $composableBuilder(
    column: $table.employer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get takeHomeMinor => $composableBuilder(
    column: $table.takeHomeMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSample => $composableBuilder(
    column: $table.isSample,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> rateRevisionsRefs(
    Expression<bool> Function($$RateRevisionsTableFilterComposer f) f,
  ) {
    final $$RateRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rateRevisions,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.rateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sourcePausesRefs(
    Expression<bool> Function($$SourcePausesTableFilterComposer f) f,
  ) {
    final $$SourcePausesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sourcePauses,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcePausesTableFilterComposer(
            $db: $db,
            $table: $db.sourcePauses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dayOverridesRefs(
    Expression<bool> Function($$DayOverridesTableFilterComposer f) f,
  ) {
    final $$DayOverridesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayOverrides,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayOverridesTableFilterComposer(
            $db: $db,
            $table: $db.dayOverrides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> compensationItemsRefs(
    Expression<bool> Function($$CompensationItemsTableFilterComposer f) f,
  ) {
    final $$CompensationItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compensationItems,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompensationItemsTableFilterComposer(
            $db: $db,
            $table: $db.compensationItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> monthlyRecordsRefs(
    Expression<bool> Function($$MonthlyRecordsTableFilterComposer f) f,
  ) {
    final $$MonthlyRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.monthlyRecords,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthlyRecordsTableFilterComposer(
            $db: $db,
            $table: $db.monthlyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> calendarEventsRefs(
    Expression<bool> Function($$CalendarEventsTableFilterComposer f) f,
  ) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableFilterComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IncomeSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomeSourcesTable> {
  $$IncomeSourcesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customCategory => $composableBuilder(
    column: $table.customCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accrualPolicy => $composableBuilder(
    column: $table.accrualPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workWeekdayMask => $composableBuilder(
    column: $table.workWeekdayMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workStartMinute => $composableBuilder(
    column: $table.workStartMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get workEndMinute => $composableBuilder(
    column: $table.workEndMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payRule => $composableBuilder(
    column: $table.payRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payDay => $composableBuilder(
    column: $table.payDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get payOffsetMonths => $composableBuilder(
    column: $table.payOffsetMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekendAdjust => $composableBuilder(
    column: $table.weekendAdjust,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedPayDate => $composableBuilder(
    column: $table.expectedPayDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fixedTotalMinor => $composableBuilder(
    column: $table.fixedTotalMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedTotalAccrual => $composableBuilder(
    column: $table.fixedTotalAccrual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forecastMethod => $composableBuilder(
    column: $table.forecastMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get employer => $composableBuilder(
    column: $table.employer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get takeHomeMinor => $composableBuilder(
    column: $table.takeHomeMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSample => $composableBuilder(
    column: $table.isSample,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IncomeSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomeSourcesTable> {
  $$IncomeSourcesTableAnnotationComposer({
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

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get customCategory => $composableBuilder(
    column: $table.customCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get accrualPolicy => $composableBuilder(
    column: $table.accrualPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workWeekdayMask => $composableBuilder(
    column: $table.workWeekdayMask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workStartMinute => $composableBuilder(
    column: $table.workStartMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get workEndMinute => $composableBuilder(
    column: $table.workEndMinute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payRule =>
      $composableBuilder(column: $table.payRule, builder: (column) => column);

  GeneratedColumn<int> get payDay =>
      $composableBuilder(column: $table.payDay, builder: (column) => column);

  GeneratedColumn<int> get payOffsetMonths => $composableBuilder(
    column: $table.payOffsetMonths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weekendAdjust => $composableBuilder(
    column: $table.weekendAdjust,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expectedPayDate => $composableBuilder(
    column: $table.expectedPayDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fixedTotalMinor => $composableBuilder(
    column: $table.fixedTotalMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedTotalAccrual => $composableBuilder(
    column: $table.fixedTotalAccrual,
    builder: (column) => column,
  );

  GeneratedColumn<String> get forecastMethod => $composableBuilder(
    column: $table.forecastMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get employer =>
      $composableBuilder(column: $table.employer, builder: (column) => column);

  GeneratedColumn<int> get takeHomeMinor => $composableBuilder(
    column: $table.takeHomeMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSample =>
      $composableBuilder(column: $table.isSample, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> rateRevisionsRefs<T extends Object>(
    Expression<T> Function($$RateRevisionsTableAnnotationComposer a) f,
  ) {
    final $$RateRevisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rateRevisions,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RateRevisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.rateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sourcePausesRefs<T extends Object>(
    Expression<T> Function($$SourcePausesTableAnnotationComposer a) f,
  ) {
    final $$SourcePausesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sourcePauses,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcePausesTableAnnotationComposer(
            $db: $db,
            $table: $db.sourcePauses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dayOverridesRefs<T extends Object>(
    Expression<T> Function($$DayOverridesTableAnnotationComposer a) f,
  ) {
    final $$DayOverridesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dayOverrides,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayOverridesTableAnnotationComposer(
            $db: $db,
            $table: $db.dayOverrides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> compensationItemsRefs<T extends Object>(
    Expression<T> Function($$CompensationItemsTableAnnotationComposer a) f,
  ) {
    final $$CompensationItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.compensationItems,
          getReferencedColumn: (t) => t.sourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompensationItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.compensationItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> monthlyRecordsRefs<T extends Object>(
    Expression<T> Function($$MonthlyRecordsTableAnnotationComposer a) f,
  ) {
    final $$MonthlyRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.monthlyRecords,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthlyRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.monthlyRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> calendarEventsRefs<T extends Object>(
    Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f,
  ) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IncomeSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomeSourcesTable,
          IncomeSourceRow,
          $$IncomeSourcesTableFilterComposer,
          $$IncomeSourcesTableOrderingComposer,
          $$IncomeSourcesTableAnnotationComposer,
          $$IncomeSourcesTableCreateCompanionBuilder,
          $$IncomeSourcesTableUpdateCompanionBuilder,
          (IncomeSourceRow, $$IncomeSourcesTableReferences),
          IncomeSourceRow,
          PrefetchHooks Function({
            bool rateRevisionsRefs,
            bool sourcePausesRefs,
            bool dayOverridesRefs,
            bool compensationItemsRefs,
            bool monthlyRecordsRefs,
            bool ledgerEntriesRefs,
            bool calendarEventsRefs,
          })
        > {
  $$IncomeSourcesTableTableManager(_$AppDatabase db, $IncomeSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomeSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomeSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomeSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> customCategory = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> accrualPolicy = const Value.absent(),
                Value<int> workWeekdayMask = const Value.absent(),
                Value<int> workStartMinute = const Value.absent(),
                Value<int> workEndMinute = const Value.absent(),
                Value<String> payRule = const Value.absent(),
                Value<int> payDay = const Value.absent(),
                Value<int> payOffsetMonths = const Value.absent(),
                Value<String> weekendAdjust = const Value.absent(),
                Value<String?> expectedPayDate = const Value.absent(),
                Value<int?> fixedTotalMinor = const Value.absent(),
                Value<String> fixedTotalAccrual = const Value.absent(),
                Value<String> forecastMethod = const Value.absent(),
                Value<String?> employer = const Value.absent(),
                Value<int?> takeHomeMinor = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<bool> isSample = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomeSourcesCompanion(
                id: id,
                name: name,
                kind: kind,
                category: category,
                customCategory: customCategory,
                status: status,
                currencyCode: currencyCode,
                startDate: startDate,
                endDate: endDate,
                accrualPolicy: accrualPolicy,
                workWeekdayMask: workWeekdayMask,
                workStartMinute: workStartMinute,
                workEndMinute: workEndMinute,
                payRule: payRule,
                payDay: payDay,
                payOffsetMonths: payOffsetMonths,
                weekendAdjust: weekendAdjust,
                expectedPayDate: expectedPayDate,
                fixedTotalMinor: fixedTotalMinor,
                fixedTotalAccrual: fixedTotalAccrual,
                forecastMethod: forecastMethod,
                employer: employer,
                takeHomeMinor: takeHomeMinor,
                notes: notes,
                colorIndex: colorIndex,
                isSample: isSample,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                required String category,
                Value<String?> customCategory = const Value.absent(),
                required String status,
                required String currencyCode,
                required String startDate,
                Value<String?> endDate = const Value.absent(),
                required String accrualPolicy,
                required int workWeekdayMask,
                required int workStartMinute,
                required int workEndMinute,
                required String payRule,
                required int payDay,
                required int payOffsetMonths,
                required String weekendAdjust,
                Value<String?> expectedPayDate = const Value.absent(),
                Value<int?> fixedTotalMinor = const Value.absent(),
                required String fixedTotalAccrual,
                required String forecastMethod,
                Value<String?> employer = const Value.absent(),
                Value<int?> takeHomeMinor = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<bool> isSample = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => IncomeSourcesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                category: category,
                customCategory: customCategory,
                status: status,
                currencyCode: currencyCode,
                startDate: startDate,
                endDate: endDate,
                accrualPolicy: accrualPolicy,
                workWeekdayMask: workWeekdayMask,
                workStartMinute: workStartMinute,
                workEndMinute: workEndMinute,
                payRule: payRule,
                payDay: payDay,
                payOffsetMonths: payOffsetMonths,
                weekendAdjust: weekendAdjust,
                expectedPayDate: expectedPayDate,
                fixedTotalMinor: fixedTotalMinor,
                fixedTotalAccrual: fixedTotalAccrual,
                forecastMethod: forecastMethod,
                employer: employer,
                takeHomeMinor: takeHomeMinor,
                notes: notes,
                colorIndex: colorIndex,
                isSample: isSample,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IncomeSourcesTable, IncomeSourceRow>(table),
                  $$IncomeSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                rateRevisionsRefs = false,
                sourcePausesRefs = false,
                dayOverridesRefs = false,
                compensationItemsRefs = false,
                monthlyRecordsRefs = false,
                ledgerEntriesRefs = false,
                calendarEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rateRevisionsRefs) db.rateRevisions,
                    if (sourcePausesRefs) db.sourcePauses,
                    if (dayOverridesRefs) db.dayOverrides,
                    if (compensationItemsRefs) db.compensationItems,
                    if (monthlyRecordsRefs) db.monthlyRecords,
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (calendarEventsRefs) db.calendarEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rateRevisionsRefs)
                        await $_getPrefetchedDataByColumns<
                          IncomeSourceRow,
                          $IncomeSourcesTable,
                          RateRevisionRow,
                          $RateRevisionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$IncomeSourcesTableReferences
                              ._rateRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IncomeSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).rateRevisionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                      if (sourcePausesRefs)
                        await $_getPrefetchedDataByColumns<
                          IncomeSourceRow,
                          $IncomeSourcesTable,
                          SourcePauseRow,
                          $SourcePausesTable
                        >(
                          currentTable: table,
                          referencedTable: $$IncomeSourcesTableReferences
                              ._sourcePausesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IncomeSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).sourcePausesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                      if (dayOverridesRefs)
                        await $_getPrefetchedDataByColumns<
                          IncomeSourceRow,
                          $IncomeSourcesTable,
                          DayOverrideRow,
                          $DayOverridesTable
                        >(
                          currentTable: table,
                          referencedTable: $$IncomeSourcesTableReferences
                              ._dayOverridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IncomeSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).dayOverridesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                      if (compensationItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          IncomeSourceRow,
                          $IncomeSourcesTable,
                          CompensationItemRow,
                          $CompensationItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$IncomeSourcesTableReferences
                              ._compensationItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IncomeSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).compensationItemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                      if (monthlyRecordsRefs)
                        await $_getPrefetchedDataByColumns<
                          IncomeSourceRow,
                          $IncomeSourcesTable,
                          MonthlyRecordRow,
                          $MonthlyRecordsTable
                        >(
                          currentTable: table,
                          referencedTable: $$IncomeSourcesTableReferences
                              ._monthlyRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IncomeSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).monthlyRecordsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          IncomeSourceRow,
                          $IncomeSourcesTable,
                          LedgerEntryRow,
                          $LedgerEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$IncomeSourcesTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IncomeSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                      if (calendarEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          IncomeSourceRow,
                          $IncomeSourcesTable,
                          CalendarEventRow,
                          $CalendarEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$IncomeSourcesTableReferences
                              ._calendarEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IncomeSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).calendarEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$IncomeSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomeSourcesTable,
      IncomeSourceRow,
      $$IncomeSourcesTableFilterComposer,
      $$IncomeSourcesTableOrderingComposer,
      $$IncomeSourcesTableAnnotationComposer,
      $$IncomeSourcesTableCreateCompanionBuilder,
      $$IncomeSourcesTableUpdateCompanionBuilder,
      (IncomeSourceRow, $$IncomeSourcesTableReferences),
      IncomeSourceRow,
      PrefetchHooks Function({
        bool rateRevisionsRefs,
        bool sourcePausesRefs,
        bool dayOverridesRefs,
        bool compensationItemsRefs,
        bool monthlyRecordsRefs,
        bool ledgerEntriesRefs,
        bool calendarEventsRefs,
      })
    >;
typedef $$RateRevisionsTableCreateCompanionBuilder =
    RateRevisionsCompanion Function({
      required String id,
      required String sourceId,
      required String effectiveFrom,
      required int amountMinor,
      required String period,
      required String changeType,
      Value<int?> percentBps,
      Value<String?> note,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$RateRevisionsTableUpdateCompanionBuilder =
    RateRevisionsCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String> effectiveFrom,
      Value<int> amountMinor,
      Value<String> period,
      Value<String> changeType,
      Value<int?> percentBps,
      Value<String?> note,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$RateRevisionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $RateRevisionsTable, RateRevisionRow> {
  $$RateRevisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IncomeSourcesTable _sourceIdTable(_$AppDatabase db) => db
      .incomeSources
      .createAlias('rate_revisions__source_id__income_sources__id');

  $$IncomeSourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$IncomeSourcesTableTableManager(
      $_db,
      $_db.incomeSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RateRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $RateRevisionsTable> {
  $$RateRevisionsTableFilterComposer({
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

  ColumnFilters<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get percentBps => $composableBuilder(
    column: $table.percentBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$IncomeSourcesTableFilterComposer get sourceId {
    final $$IncomeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RateRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RateRevisionsTable> {
  $$RateRevisionsTableOrderingComposer({
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

  ColumnOrderings<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get percentBps => $composableBuilder(
    column: $table.percentBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$IncomeSourcesTableOrderingComposer get sourceId {
    final $$IncomeSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RateRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RateRevisionsTable> {
  $$RateRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<String> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get percentBps => $composableBuilder(
    column: $table.percentBps,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$IncomeSourcesTableAnnotationComposer get sourceId {
    final $$IncomeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RateRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RateRevisionsTable,
          RateRevisionRow,
          $$RateRevisionsTableFilterComposer,
          $$RateRevisionsTableOrderingComposer,
          $$RateRevisionsTableAnnotationComposer,
          $$RateRevisionsTableCreateCompanionBuilder,
          $$RateRevisionsTableUpdateCompanionBuilder,
          (RateRevisionRow, $$RateRevisionsTableReferences),
          RateRevisionRow,
          PrefetchHooks Function({bool sourceId})
        > {
  $$RateRevisionsTableTableManager(_$AppDatabase db, $RateRevisionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RateRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RateRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RateRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> effectiveFrom = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<String> changeType = const Value.absent(),
                Value<int?> percentBps = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RateRevisionsCompanion(
                id: id,
                sourceId: sourceId,
                effectiveFrom: effectiveFrom,
                amountMinor: amountMinor,
                period: period,
                changeType: changeType,
                percentBps: percentBps,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                required String effectiveFrom,
                required int amountMinor,
                required String period,
                required String changeType,
                Value<int?> percentBps = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => RateRevisionsCompanion.insert(
                id: id,
                sourceId: sourceId,
                effectiveFrom: effectiveFrom,
                amountMinor: amountMinor,
                period: period,
                changeType: changeType,
                percentBps: percentBps,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RateRevisionsTable, RateRevisionRow>(table),
                  $$RateRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
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
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: $$RateRevisionsTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: $$RateRevisionsTableReferences
                            ._sourceIdTable(db)
                            .id,
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

typedef $$RateRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RateRevisionsTable,
      RateRevisionRow,
      $$RateRevisionsTableFilterComposer,
      $$RateRevisionsTableOrderingComposer,
      $$RateRevisionsTableAnnotationComposer,
      $$RateRevisionsTableCreateCompanionBuilder,
      $$RateRevisionsTableUpdateCompanionBuilder,
      (RateRevisionRow, $$RateRevisionsTableReferences),
      RateRevisionRow,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$SourcePausesTableCreateCompanionBuilder =
    SourcePausesCompanion Function({
      required String id,
      required String sourceId,
      required String start,
      Value<String?> endExclusive,
      Value<int> rowid,
    });
typedef $$SourcePausesTableUpdateCompanionBuilder =
    SourcePausesCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String> start,
      Value<String?> endExclusive,
      Value<int> rowid,
    });

final class $$SourcePausesTableReferences
    extends BaseReferences<_$AppDatabase, $SourcePausesTable, SourcePauseRow> {
  $$SourcePausesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IncomeSourcesTable _sourceIdTable(_$AppDatabase db) => db
      .incomeSources
      .createAlias('source_pauses__source_id__income_sources__id');

  $$IncomeSourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$IncomeSourcesTableTableManager(
      $_db,
      $_db.incomeSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SourcePausesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcePausesTable> {
  $$SourcePausesTableFilterComposer({
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

  ColumnFilters<String> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endExclusive => $composableBuilder(
    column: $table.endExclusive,
    builder: (column) => ColumnFilters(column),
  );

  $$IncomeSourcesTableFilterComposer get sourceId {
    final $$IncomeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcePausesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcePausesTable> {
  $$SourcePausesTableOrderingComposer({
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

  ColumnOrderings<String> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endExclusive => $composableBuilder(
    column: $table.endExclusive,
    builder: (column) => ColumnOrderings(column),
  );

  $$IncomeSourcesTableOrderingComposer get sourceId {
    final $$IncomeSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcePausesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcePausesTable> {
  $$SourcePausesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<String> get endExclusive => $composableBuilder(
    column: $table.endExclusive,
    builder: (column) => column,
  );

  $$IncomeSourcesTableAnnotationComposer get sourceId {
    final $$IncomeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourcePausesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcePausesTable,
          SourcePauseRow,
          $$SourcePausesTableFilterComposer,
          $$SourcePausesTableOrderingComposer,
          $$SourcePausesTableAnnotationComposer,
          $$SourcePausesTableCreateCompanionBuilder,
          $$SourcePausesTableUpdateCompanionBuilder,
          (SourcePauseRow, $$SourcePausesTableReferences),
          SourcePauseRow,
          PrefetchHooks Function({bool sourceId})
        > {
  $$SourcePausesTableTableManager(_$AppDatabase db, $SourcePausesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcePausesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcePausesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcePausesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> start = const Value.absent(),
                Value<String?> endExclusive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcePausesCompanion(
                id: id,
                sourceId: sourceId,
                start: start,
                endExclusive: endExclusive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                required String start,
                Value<String?> endExclusive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourcePausesCompanion.insert(
                id: id,
                sourceId: sourceId,
                start: start,
                endExclusive: endExclusive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcePausesTable, SourcePauseRow>(table),
                  $$SourcePausesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
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
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: $$SourcePausesTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: $$SourcePausesTableReferences
                            ._sourceIdTable(db)
                            .id,
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

typedef $$SourcePausesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcePausesTable,
      SourcePauseRow,
      $$SourcePausesTableFilterComposer,
      $$SourcePausesTableOrderingComposer,
      $$SourcePausesTableAnnotationComposer,
      $$SourcePausesTableCreateCompanionBuilder,
      $$SourcePausesTableUpdateCompanionBuilder,
      (SourcePauseRow, $$SourcePausesTableReferences),
      SourcePauseRow,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$DayOverridesTableCreateCompanionBuilder =
    DayOverridesCompanion Function({
      required String id,
      Value<String?> sourceId,
      required String date,
      required String type,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$DayOverridesTableUpdateCompanionBuilder =
    DayOverridesCompanion Function({
      Value<String> id,
      Value<String?> sourceId,
      Value<String> date,
      Value<String> type,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$DayOverridesTableReferences
    extends BaseReferences<_$AppDatabase, $DayOverridesTable, DayOverrideRow> {
  $$DayOverridesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IncomeSourcesTable _sourceIdTable(_$AppDatabase db) => db
      .incomeSources
      .createAlias('day_overrides__source_id__income_sources__id');

  $$IncomeSourcesTableProcessedTableManager? get sourceId {
    final $_column = $_itemColumn<String>('source_id');
    if ($_column == null) return null;
    final manager = $$IncomeSourcesTableTableManager(
      $_db,
      $_db.incomeSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DayOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $DayOverridesTable> {
  $$DayOverridesTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$IncomeSourcesTableFilterComposer get sourceId {
    final $$IncomeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayOverridesTable> {
  $$DayOverridesTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$IncomeSourcesTableOrderingComposer get sourceId {
    final $$IncomeSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayOverridesTable> {
  $$DayOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$IncomeSourcesTableAnnotationComposer get sourceId {
    final $$IncomeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayOverridesTable,
          DayOverrideRow,
          $$DayOverridesTableFilterComposer,
          $$DayOverridesTableOrderingComposer,
          $$DayOverridesTableAnnotationComposer,
          $$DayOverridesTableCreateCompanionBuilder,
          $$DayOverridesTableUpdateCompanionBuilder,
          (DayOverrideRow, $$DayOverridesTableReferences),
          DayOverrideRow,
          PrefetchHooks Function({bool sourceId})
        > {
  $$DayOverridesTableTableManager(_$AppDatabase db, $DayOverridesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayOverridesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayOverridesCompanion(
                id: id,
                sourceId: sourceId,
                date: date,
                type: type,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> sourceId = const Value.absent(),
                required String date,
                required String type,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayOverridesCompanion.insert(
                id: id,
                sourceId: sourceId,
                date: date,
                type: type,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayOverridesTable, DayOverrideRow>(table),
                  $$DayOverridesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
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
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: $$DayOverridesTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: $$DayOverridesTableReferences
                            ._sourceIdTable(db)
                            .id,
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

typedef $$DayOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayOverridesTable,
      DayOverrideRow,
      $$DayOverridesTableFilterComposer,
      $$DayOverridesTableOrderingComposer,
      $$DayOverridesTableAnnotationComposer,
      $$DayOverridesTableCreateCompanionBuilder,
      $$DayOverridesTableUpdateCompanionBuilder,
      (DayOverrideRow, $$DayOverridesTableReferences),
      DayOverrideRow,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$CompensationItemsTableCreateCompanionBuilder =
    CompensationItemsCompanion Function({
      required String id,
      Value<String?> sourceId,
      required String type,
      required String title,
      required String currencyCode,
      Value<int?> expectedMinor,
      Value<String?> expectedDate,
      Value<int?> actualMinor,
      Value<String?> earnedDate,
      required String recurrence,
      Value<bool> nonCash,
      Value<bool> countsAsEarnings,
      Value<bool> includeInForecast,
      Value<String?> taxNote,
      Value<String?> notes,
      Value<bool> cancelled,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$CompensationItemsTableUpdateCompanionBuilder =
    CompensationItemsCompanion Function({
      Value<String> id,
      Value<String?> sourceId,
      Value<String> type,
      Value<String> title,
      Value<String> currencyCode,
      Value<int?> expectedMinor,
      Value<String?> expectedDate,
      Value<int?> actualMinor,
      Value<String?> earnedDate,
      Value<String> recurrence,
      Value<bool> nonCash,
      Value<bool> countsAsEarnings,
      Value<bool> includeInForecast,
      Value<String?> taxNote,
      Value<String?> notes,
      Value<bool> cancelled,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$CompensationItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CompensationItemsTable,
          CompensationItemRow
        > {
  $$CompensationItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IncomeSourcesTable _sourceIdTable(_$AppDatabase db) => db
      .incomeSources
      .createAlias('compensation_items__source_id__income_sources__id');

  $$IncomeSourcesTableProcessedTableManager? get sourceId {
    final $_column = $_itemColumn<String>('source_id');
    if ($_column == null) return null;
    final manager = $$IncomeSourcesTableTableManager(
      $_db,
      $_db.incomeSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<LedgerEntryRow>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'compensation_items__id__ledger_entries__item_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompensationItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CompensationItemsTable> {
  $$CompensationItemsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedMinor => $composableBuilder(
    column: $table.expectedMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earnedDate => $composableBuilder(
    column: $table.earnedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get nonCash => $composableBuilder(
    column: $table.nonCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countsAsEarnings => $composableBuilder(
    column: $table.countsAsEarnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInForecast => $composableBuilder(
    column: $table.includeInForecast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxNote => $composableBuilder(
    column: $table.taxNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$IncomeSourcesTableFilterComposer get sourceId {
    final $$IncomeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompensationItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompensationItemsTable> {
  $$CompensationItemsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedMinor => $composableBuilder(
    column: $table.expectedMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earnedDate => $composableBuilder(
    column: $table.earnedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nonCash => $composableBuilder(
    column: $table.nonCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countsAsEarnings => $composableBuilder(
    column: $table.countsAsEarnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInForecast => $composableBuilder(
    column: $table.includeInForecast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxNote => $composableBuilder(
    column: $table.taxNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$IncomeSourcesTableOrderingComposer get sourceId {
    final $$IncomeSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompensationItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompensationItemsTable> {
  $$CompensationItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedMinor => $composableBuilder(
    column: $table.expectedMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expectedDate => $composableBuilder(
    column: $table.expectedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get earnedDate => $composableBuilder(
    column: $table.earnedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get nonCash =>
      $composableBuilder(column: $table.nonCash, builder: (column) => column);

  GeneratedColumn<bool> get countsAsEarnings => $composableBuilder(
    column: $table.countsAsEarnings,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeInForecast => $composableBuilder(
    column: $table.includeInForecast,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxNote =>
      $composableBuilder(column: $table.taxNote, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get cancelled =>
      $composableBuilder(column: $table.cancelled, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$IncomeSourcesTableAnnotationComposer get sourceId {
    final $$IncomeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompensationItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompensationItemsTable,
          CompensationItemRow,
          $$CompensationItemsTableFilterComposer,
          $$CompensationItemsTableOrderingComposer,
          $$CompensationItemsTableAnnotationComposer,
          $$CompensationItemsTableCreateCompanionBuilder,
          $$CompensationItemsTableUpdateCompanionBuilder,
          (CompensationItemRow, $$CompensationItemsTableReferences),
          CompensationItemRow,
          PrefetchHooks Function({bool sourceId, bool ledgerEntriesRefs})
        > {
  $$CompensationItemsTableTableManager(
    _$AppDatabase db,
    $CompensationItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompensationItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompensationItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompensationItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int?> expectedMinor = const Value.absent(),
                Value<String?> expectedDate = const Value.absent(),
                Value<int?> actualMinor = const Value.absent(),
                Value<String?> earnedDate = const Value.absent(),
                Value<String> recurrence = const Value.absent(),
                Value<bool> nonCash = const Value.absent(),
                Value<bool> countsAsEarnings = const Value.absent(),
                Value<bool> includeInForecast = const Value.absent(),
                Value<String?> taxNote = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> cancelled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompensationItemsCompanion(
                id: id,
                sourceId: sourceId,
                type: type,
                title: title,
                currencyCode: currencyCode,
                expectedMinor: expectedMinor,
                expectedDate: expectedDate,
                actualMinor: actualMinor,
                earnedDate: earnedDate,
                recurrence: recurrence,
                nonCash: nonCash,
                countsAsEarnings: countsAsEarnings,
                includeInForecast: includeInForecast,
                taxNote: taxNote,
                notes: notes,
                cancelled: cancelled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> sourceId = const Value.absent(),
                required String type,
                required String title,
                required String currencyCode,
                Value<int?> expectedMinor = const Value.absent(),
                Value<String?> expectedDate = const Value.absent(),
                Value<int?> actualMinor = const Value.absent(),
                Value<String?> earnedDate = const Value.absent(),
                required String recurrence,
                Value<bool> nonCash = const Value.absent(),
                Value<bool> countsAsEarnings = const Value.absent(),
                Value<bool> includeInForecast = const Value.absent(),
                Value<String?> taxNote = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> cancelled = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CompensationItemsCompanion.insert(
                id: id,
                sourceId: sourceId,
                type: type,
                title: title,
                currencyCode: currencyCode,
                expectedMinor: expectedMinor,
                expectedDate: expectedDate,
                actualMinor: actualMinor,
                earnedDate: earnedDate,
                recurrence: recurrence,
                nonCash: nonCash,
                countsAsEarnings: countsAsEarnings,
                includeInForecast: includeInForecast,
                taxNote: taxNote,
                notes: notes,
                cancelled: cancelled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompensationItemsTable, CompensationItemRow>(
                    table,
                  ),
                  $$CompensationItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceId = false, ledgerEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerEntriesRefs) db.ledgerEntries,
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
                        if (sourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceId,
                            referencedTable: $$CompensationItemsTableReferences
                                ._sourceIdTable(db),
                            referencedColumn: $$CompensationItemsTableReferences
                                ._sourceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          CompensationItemRow,
                          $CompensationItemsTable,
                          LedgerEntryRow,
                          $LedgerEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$CompensationItemsTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompensationItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CompensationItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompensationItemsTable,
      CompensationItemRow,
      $$CompensationItemsTableFilterComposer,
      $$CompensationItemsTableOrderingComposer,
      $$CompensationItemsTableAnnotationComposer,
      $$CompensationItemsTableCreateCompanionBuilder,
      $$CompensationItemsTableUpdateCompanionBuilder,
      (CompensationItemRow, $$CompensationItemsTableReferences),
      CompensationItemRow,
      PrefetchHooks Function({bool sourceId, bool ledgerEntriesRefs})
    >;
typedef $$MonthlyRecordsTableCreateCompanionBuilder =
    MonthlyRecordsCompanion Function({
      required String id,
      required String sourceId,
      required String month,
      Value<int?> originalEstimateMinor,
      Value<int?> revisedEstimateMinor,
      Value<int?> actualMinor,
      Value<bool> finalized,
      Value<int?> finalizedAt,
      Value<String?> notes,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$MonthlyRecordsTableUpdateCompanionBuilder =
    MonthlyRecordsCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String> month,
      Value<int?> originalEstimateMinor,
      Value<int?> revisedEstimateMinor,
      Value<int?> actualMinor,
      Value<bool> finalized,
      Value<int?> finalizedAt,
      Value<String?> notes,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$MonthlyRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $MonthlyRecordsTable, MonthlyRecordRow> {
  $$MonthlyRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IncomeSourcesTable _sourceIdTable(_$AppDatabase db) => db
      .incomeSources
      .createAlias('monthly_records__source_id__income_sources__id');

  $$IncomeSourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$IncomeSourcesTableTableManager(
      $_db,
      $_db.incomeSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MonthlyRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyRecordsTable> {
  $$MonthlyRecordsTableFilterComposer({
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

  ColumnFilters<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalEstimateMinor => $composableBuilder(
    column: $table.originalEstimateMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revisedEstimateMinor => $composableBuilder(
    column: $table.revisedEstimateMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finalized => $composableBuilder(
    column: $table.finalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$IncomeSourcesTableFilterComposer get sourceId {
    final $$IncomeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyRecordsTable> {
  $$MonthlyRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalEstimateMinor => $composableBuilder(
    column: $table.originalEstimateMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revisedEstimateMinor => $composableBuilder(
    column: $table.revisedEstimateMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finalized => $composableBuilder(
    column: $table.finalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$IncomeSourcesTableOrderingComposer get sourceId {
    final $$IncomeSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyRecordsTable> {
  $$MonthlyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get originalEstimateMinor => $composableBuilder(
    column: $table.originalEstimateMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revisedEstimateMinor => $composableBuilder(
    column: $table.revisedEstimateMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualMinor => $composableBuilder(
    column: $table.actualMinor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get finalized =>
      $composableBuilder(column: $table.finalized, builder: (column) => column);

  GeneratedColumn<int> get finalizedAt => $composableBuilder(
    column: $table.finalizedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$IncomeSourcesTableAnnotationComposer get sourceId {
    final $$IncomeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthlyRecordsTable,
          MonthlyRecordRow,
          $$MonthlyRecordsTableFilterComposer,
          $$MonthlyRecordsTableOrderingComposer,
          $$MonthlyRecordsTableAnnotationComposer,
          $$MonthlyRecordsTableCreateCompanionBuilder,
          $$MonthlyRecordsTableUpdateCompanionBuilder,
          (MonthlyRecordRow, $$MonthlyRecordsTableReferences),
          MonthlyRecordRow,
          PrefetchHooks Function({bool sourceId})
        > {
  $$MonthlyRecordsTableTableManager(
    _$AppDatabase db,
    $MonthlyRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> month = const Value.absent(),
                Value<int?> originalEstimateMinor = const Value.absent(),
                Value<int?> revisedEstimateMinor = const Value.absent(),
                Value<int?> actualMinor = const Value.absent(),
                Value<bool> finalized = const Value.absent(),
                Value<int?> finalizedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlyRecordsCompanion(
                id: id,
                sourceId: sourceId,
                month: month,
                originalEstimateMinor: originalEstimateMinor,
                revisedEstimateMinor: revisedEstimateMinor,
                actualMinor: actualMinor,
                finalized: finalized,
                finalizedAt: finalizedAt,
                notes: notes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                required String month,
                Value<int?> originalEstimateMinor = const Value.absent(),
                Value<int?> revisedEstimateMinor = const Value.absent(),
                Value<int?> actualMinor = const Value.absent(),
                Value<bool> finalized = const Value.absent(),
                Value<int?> finalizedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MonthlyRecordsCompanion.insert(
                id: id,
                sourceId: sourceId,
                month: month,
                originalEstimateMinor: originalEstimateMinor,
                revisedEstimateMinor: revisedEstimateMinor,
                actualMinor: actualMinor,
                finalized: finalized,
                finalizedAt: finalizedAt,
                notes: notes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MonthlyRecordsTable, MonthlyRecordRow>(table),
                  $$MonthlyRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
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
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: $$MonthlyRecordsTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: $$MonthlyRecordsTableReferences
                            ._sourceIdTable(db)
                            .id,
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

typedef $$MonthlyRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthlyRecordsTable,
      MonthlyRecordRow,
      $$MonthlyRecordsTableFilterComposer,
      $$MonthlyRecordsTableOrderingComposer,
      $$MonthlyRecordsTableAnnotationComposer,
      $$MonthlyRecordsTableCreateCompanionBuilder,
      $$MonthlyRecordsTableUpdateCompanionBuilder,
      (MonthlyRecordRow, $$MonthlyRecordsTableReferences),
      MonthlyRecordRow,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      required String id,
      required String sourceId,
      Value<String?> itemId,
      required String type,
      required int amountMinor,
      required String currencyCode,
      required String periodMonth,
      required String date,
      required String status,
      Value<String?> dedupeKey,
      Value<String?> notes,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<String> id,
      Value<String> sourceId,
      Value<String?> itemId,
      Value<String> type,
      Value<int> amountMinor,
      Value<String> currencyCode,
      Value<String> periodMonth,
      Value<String> date,
      Value<String> status,
      Value<String?> dedupeKey,
      Value<String?> notes,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$LedgerEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntryRow> {
  $$LedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IncomeSourcesTable _sourceIdTable(_$AppDatabase db) => db
      .incomeSources
      .createAlias('ledger_entries__source_id__income_sources__id');

  $$IncomeSourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$IncomeSourcesTableTableManager(
      $_db,
      $_db.incomeSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CompensationItemsTable _itemIdTable(_$AppDatabase db) => db
      .compensationItems
      .createAlias('ledger_entries__item_id__compensation_items__id');

  $$CompensationItemsTableProcessedTableManager? get itemId {
    final $_column = $_itemColumn<String>('item_id');
    if ($_column == null) return null;
    final manager = $$CompensationItemsTableTableManager(
      $_db,
      $_db.compensationItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodMonth => $composableBuilder(
    column: $table.periodMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$IncomeSourcesTableFilterComposer get sourceId {
    final $$IncomeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompensationItemsTableFilterComposer get itemId {
    final $$CompensationItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.compensationItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompensationItemsTableFilterComposer(
            $db: $db,
            $table: $db.compensationItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodMonth => $composableBuilder(
    column: $table.periodMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dedupeKey => $composableBuilder(
    column: $table.dedupeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$IncomeSourcesTableOrderingComposer get sourceId {
    final $$IncomeSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompensationItemsTableOrderingComposer get itemId {
    final $$CompensationItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.compensationItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompensationItemsTableOrderingComposer(
            $db: $db,
            $table: $db.compensationItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodMonth => $composableBuilder(
    column: $table.periodMonth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$IncomeSourcesTableAnnotationComposer get sourceId {
    final $$IncomeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompensationItemsTableAnnotationComposer get itemId {
    final $$CompensationItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.itemId,
          referencedTable: $db.compensationItems,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompensationItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.compensationItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          LedgerEntryRow,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (LedgerEntryRow, $$LedgerEntriesTableReferences),
          LedgerEntryRow,
          PrefetchHooks Function({bool sourceId, bool itemId})
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> periodMonth = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> dedupeKey = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                sourceId: sourceId,
                itemId: itemId,
                type: type,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                periodMonth: periodMonth,
                date: date,
                status: status,
                dedupeKey: dedupeKey,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceId,
                Value<String?> itemId = const Value.absent(),
                required String type,
                required int amountMinor,
                required String currencyCode,
                required String periodMonth,
                required String date,
                required String status,
                Value<String?> dedupeKey = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                sourceId: sourceId,
                itemId: itemId,
                type: type,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                periodMonth: periodMonth,
                date: date,
                status: status,
                dedupeKey: dedupeKey,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LedgerEntriesTable, LedgerEntryRow>(table),
                  $$LedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false, itemId = false}) {
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
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: $$LedgerEntriesTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: $$LedgerEntriesTableReferences
                            ._sourceIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$LedgerEntriesTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$LedgerEntriesTableReferences
                            ._itemIdTable(db)
                            .id,
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

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      LedgerEntryRow,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (LedgerEntryRow, $$LedgerEntriesTableReferences),
      LedgerEntryRow,
      PrefetchHooks Function({bool sourceId, bool itemId})
    >;
typedef $$CalendarEventsTableCreateCompanionBuilder =
    CalendarEventsCompanion Function({
      required String id,
      required String title,
      required String date,
      required String type,
      Value<String?> sourceId,
      Value<int?> amountMinor,
      Value<String?> notes,
      Value<bool> remind,
      Value<bool> cancelled,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$CalendarEventsTableUpdateCompanionBuilder =
    CalendarEventsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> date,
      Value<String> type,
      Value<String?> sourceId,
      Value<int?> amountMinor,
      Value<String?> notes,
      Value<bool> remind,
      Value<bool> cancelled,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$CalendarEventsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CalendarEventsTable, CalendarEventRow> {
  $$CalendarEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $IncomeSourcesTable _sourceIdTable(_$AppDatabase db) => db
      .incomeSources
      .createAlias('calendar_events__source_id__income_sources__id');

  $$IncomeSourcesTableProcessedTableManager? get sourceId {
    final $_column = $_itemColumn<String>('source_id');
    if ($_column == null) return null;
    final manager = $$IncomeSourcesTableTableManager(
      $_db,
      $_db.incomeSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remind => $composableBuilder(
    column: $table.remind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$IncomeSourcesTableFilterComposer get sourceId {
    final $$IncomeSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableFilterComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remind => $composableBuilder(
    column: $table.remind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$IncomeSourcesTableOrderingComposer get sourceId {
    final $$IncomeSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get remind =>
      $composableBuilder(column: $table.remind, builder: (column) => column);

  GeneratedColumn<bool> get cancelled =>
      $composableBuilder(column: $table.cancelled, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$IncomeSourcesTableAnnotationComposer get sourceId {
    final $$IncomeSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.incomeSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarEventsTable,
          CalendarEventRow,
          $$CalendarEventsTableFilterComposer,
          $$CalendarEventsTableOrderingComposer,
          $$CalendarEventsTableAnnotationComposer,
          $$CalendarEventsTableCreateCompanionBuilder,
          $$CalendarEventsTableUpdateCompanionBuilder,
          (CalendarEventRow, $$CalendarEventsTableReferences),
          CalendarEventRow,
          PrefetchHooks Function({bool sourceId})
        > {
  $$CalendarEventsTableTableManager(
    _$AppDatabase db,
    $CalendarEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> remind = const Value.absent(),
                Value<bool> cancelled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion(
                id: id,
                title: title,
                date: date,
                type: type,
                sourceId: sourceId,
                amountMinor: amountMinor,
                notes: notes,
                remind: remind,
                cancelled: cancelled,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String date,
                required String type,
                Value<String?> sourceId = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> remind = const Value.absent(),
                Value<bool> cancelled = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion.insert(
                id: id,
                title: title,
                date: date,
                type: type,
                sourceId: sourceId,
                amountMinor: amountMinor,
                notes: notes,
                remind: remind,
                cancelled: cancelled,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarEventsTable, CalendarEventRow>(table),
                  $$CalendarEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
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
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: $$CalendarEventsTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: $$CalendarEventsTableReferences
                            ._sourceIdTable(db)
                            .id,
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

typedef $$CalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarEventsTable,
      CalendarEventRow,
      $$CalendarEventsTableFilterComposer,
      $$CalendarEventsTableOrderingComposer,
      $$CalendarEventsTableAnnotationComposer,
      $$CalendarEventsTableCreateCompanionBuilder,
      $$CalendarEventsTableUpdateCompanionBuilder,
      (CalendarEventRow, $$CalendarEventsTableReferences),
      CalendarEventRow,
      PrefetchHooks Function({bool sourceId})
    >;
typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  required String id,
  required String entityType,
  required String entityId,
  required String action,
  required String summary,
  Value<String?> beforeJson,
  Value<String?> afterJson,
  required int at,
  Value<int> rowid,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<String> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> action,
  Value<String> summary,
  Value<String?> beforeJson,
  Value<String?> afterJson,
  Value<int> at,
  Value<int> rowid,
});

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
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

  ColumnFilters<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
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

  ColumnOrderings<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  GeneratedColumn<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afterJson =>
      $composableBuilder(column: $table.afterJson, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogTable,
          AuditRow,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (AuditRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditRow>),
          AuditRow,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String?> beforeJson = const Value.absent(),
                Value<String?> afterJson = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                summary: summary,
                beforeJson: beforeJson,
                afterJson: afterJson,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String action,
                required String summary,
                Value<String?> beforeJson = const Value.absent(),
                Value<String?> afterJson = const Value.absent(),
                required int at,
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                summary: summary,
                beforeJson: beforeJson,
                afterJson: afterJson,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditLogTable, AuditRow>(table),
                  BaseReferences<_$AppDatabase, $AuditLogTable, AuditRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogTable,
      AuditRow,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (AuditRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditRow>),
      AuditRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationHistoryTableCreateCompanionBuilder =
    NotificationHistoryCompanion Function({
      required String key,
      required String category,
      required String title,
      required int scheduledFor,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$NotificationHistoryTableUpdateCompanionBuilder =
    NotificationHistoryCompanion Function({
      Value<String> key,
      Value<String> category,
      Value<String> title,
      Value<int> scheduledFor,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$NotificationHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NotificationHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationHistoryTable,
          NotificationHistoryRow,
          $$NotificationHistoryTableFilterComposer,
          $$NotificationHistoryTableOrderingComposer,
          $$NotificationHistoryTableAnnotationComposer,
          $$NotificationHistoryTableCreateCompanionBuilder,
          $$NotificationHistoryTableUpdateCompanionBuilder,
          (
            NotificationHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $NotificationHistoryTable,
              NotificationHistoryRow
            >,
          ),
          NotificationHistoryRow,
          PrefetchHooks Function()
        > {
  $$NotificationHistoryTableTableManager(
    _$AppDatabase db,
    $NotificationHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> scheduledFor = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationHistoryCompanion(
                key: key,
                category: category,
                title: title,
                scheduledFor: scheduledFor,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String category,
                required String title,
                required int scheduledFor,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NotificationHistoryCompanion.insert(
                key: key,
                category: category,
                title: title,
                scheduledFor: scheduledFor,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $NotificationHistoryTable,
                    NotificationHistoryRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $NotificationHistoryTable,
                    NotificationHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationHistoryTable,
      NotificationHistoryRow,
      $$NotificationHistoryTableFilterComposer,
      $$NotificationHistoryTableOrderingComposer,
      $$NotificationHistoryTableAnnotationComposer,
      $$NotificationHistoryTableCreateCompanionBuilder,
      $$NotificationHistoryTableUpdateCompanionBuilder,
      (
        NotificationHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $NotificationHistoryTable,
          NotificationHistoryRow
        >,
      ),
      NotificationHistoryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$IncomeSourcesTableTableManager get incomeSources =>
      $$IncomeSourcesTableTableManager(_db, _db.incomeSources);
  $$RateRevisionsTableTableManager get rateRevisions =>
      $$RateRevisionsTableTableManager(_db, _db.rateRevisions);
  $$SourcePausesTableTableManager get sourcePauses =>
      $$SourcePausesTableTableManager(_db, _db.sourcePauses);
  $$DayOverridesTableTableManager get dayOverrides =>
      $$DayOverridesTableTableManager(_db, _db.dayOverrides);
  $$CompensationItemsTableTableManager get compensationItems =>
      $$CompensationItemsTableTableManager(_db, _db.compensationItems);
  $$MonthlyRecordsTableTableManager get monthlyRecords =>
      $$MonthlyRecordsTableTableManager(_db, _db.monthlyRecords);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$NotificationHistoryTableTableManager get notificationHistory =>
      $$NotificationHistoryTableTableManager(_db, _db.notificationHistory);
}
