// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal.db.dart';

// ignore_for_file: type=lint
class $SignalIdentityKeyStoresTable extends SignalIdentityKeyStores
    with TableInfo<$SignalIdentityKeyStoresTable, SignalIdentityKeyStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalIdentityKeyStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _identityKeyMeta = const VerificationMeta(
    'identityKey',
  );
  @override
  late final GeneratedColumn<Uint8List> identityKey =
      GeneratedColumn<Uint8List>(
        'identity_key',
        aliasedName,
        false,
        type: DriftSqlType.blob,
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
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    name,
    identityKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_identity_key_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalIdentityKeyStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('identity_key')) {
      context.handle(
        _identityKeyMeta,
        identityKey.isAcceptableOrUnknown(
          data['identity_key']!,
          _identityKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, name};
  @override
  SignalIdentityKeyStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalIdentityKeyStore(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      identityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}identity_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SignalIdentityKeyStoresTable createAlias(String alias) {
    return $SignalIdentityKeyStoresTable(attachedDatabase, alias);
  }
}

class SignalIdentityKeyStore extends DataClass
    implements Insertable<SignalIdentityKeyStore> {
  final int deviceId;
  final String name;
  final Uint8List identityKey;
  final DateTime createdAt;
  const SignalIdentityKeyStore({
    required this.deviceId,
    required this.name,
    required this.identityKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<int>(deviceId);
    map['name'] = Variable<String>(name);
    map['identity_key'] = Variable<Uint8List>(identityKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SignalIdentityKeyStoresCompanion toCompanion(bool nullToAbsent) {
    return SignalIdentityKeyStoresCompanion(
      deviceId: Value(deviceId),
      name: Value(name),
      identityKey: Value(identityKey),
      createdAt: Value(createdAt),
    );
  }

  factory SignalIdentityKeyStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalIdentityKeyStore(
      deviceId: serializer.fromJson<int>(json['deviceId']),
      name: serializer.fromJson<String>(json['name']),
      identityKey: serializer.fromJson<Uint8List>(json['identityKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<int>(deviceId),
      'name': serializer.toJson<String>(name),
      'identityKey': serializer.toJson<Uint8List>(identityKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalIdentityKeyStore copyWith({
    int? deviceId,
    String? name,
    Uint8List? identityKey,
    DateTime? createdAt,
  }) => SignalIdentityKeyStore(
    deviceId: deviceId ?? this.deviceId,
    name: name ?? this.name,
    identityKey: identityKey ?? this.identityKey,
    createdAt: createdAt ?? this.createdAt,
  );
  SignalIdentityKeyStore copyWithCompanion(
    SignalIdentityKeyStoresCompanion data,
  ) {
    return SignalIdentityKeyStore(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      identityKey: data.identityKey.present
          ? data.identityKey.value
          : this.identityKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalIdentityKeyStore(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('identityKey: $identityKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    name,
    $driftBlobEquality.hash(identityKey),
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalIdentityKeyStore &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          $driftBlobEquality.equals(other.identityKey, this.identityKey) &&
          other.createdAt == this.createdAt);
}

class SignalIdentityKeyStoresCompanion
    extends UpdateCompanion<SignalIdentityKeyStore> {
  final Value<int> deviceId;
  final Value<String> name;
  final Value<Uint8List> identityKey;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SignalIdentityKeyStoresCompanion({
    this.deviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.identityKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalIdentityKeyStoresCompanion.insert({
    required int deviceId,
    required String name,
    required Uint8List identityKey,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       name = Value(name),
       identityKey = Value(identityKey);
  static Insertable<SignalIdentityKeyStore> custom({
    Expression<int>? deviceId,
    Expression<String>? name,
    Expression<Uint8List>? identityKey,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (name != null) 'name': name,
      if (identityKey != null) 'identity_key': identityKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalIdentityKeyStoresCompanion copyWith({
    Value<int>? deviceId,
    Value<String>? name,
    Value<Uint8List>? identityKey,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SignalIdentityKeyStoresCompanion(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      identityKey: identityKey ?? this.identityKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (identityKey.present) {
      map['identity_key'] = Variable<Uint8List>(identityKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalIdentityKeyStoresCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('identityKey: $identityKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalPreKeyStoresTable extends SignalPreKeyStores
    with TableInfo<$SignalPreKeyStoresTable, SignalPreKeyStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalPreKeyStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _preKeyIdMeta = const VerificationMeta(
    'preKeyId',
  );
  @override
  late final GeneratedColumn<int> preKeyId = GeneratedColumn<int>(
    'pre_key_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preKeyMeta = const VerificationMeta('preKey');
  @override
  late final GeneratedColumn<Uint8List> preKey = GeneratedColumn<Uint8List>(
    'pre_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
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
  @override
  List<GeneratedColumn> get $columns => [preKeyId, preKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_pre_key_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalPreKeyStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pre_key_id')) {
      context.handle(
        _preKeyIdMeta,
        preKeyId.isAcceptableOrUnknown(data['pre_key_id']!, _preKeyIdMeta),
      );
    }
    if (data.containsKey('pre_key')) {
      context.handle(
        _preKeyMeta,
        preKey.isAcceptableOrUnknown(data['pre_key']!, _preKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_preKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {preKeyId};
  @override
  SignalPreKeyStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalPreKeyStore(
      preKeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pre_key_id'],
      )!,
      preKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}pre_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SignalPreKeyStoresTable createAlias(String alias) {
    return $SignalPreKeyStoresTable(attachedDatabase, alias);
  }
}

class SignalPreKeyStore extends DataClass
    implements Insertable<SignalPreKeyStore> {
  final int preKeyId;
  final Uint8List preKey;
  final DateTime createdAt;
  const SignalPreKeyStore({
    required this.preKeyId,
    required this.preKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pre_key_id'] = Variable<int>(preKeyId);
    map['pre_key'] = Variable<Uint8List>(preKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SignalPreKeyStoresCompanion toCompanion(bool nullToAbsent) {
    return SignalPreKeyStoresCompanion(
      preKeyId: Value(preKeyId),
      preKey: Value(preKey),
      createdAt: Value(createdAt),
    );
  }

  factory SignalPreKeyStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalPreKeyStore(
      preKeyId: serializer.fromJson<int>(json['preKeyId']),
      preKey: serializer.fromJson<Uint8List>(json['preKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'preKeyId': serializer.toJson<int>(preKeyId),
      'preKey': serializer.toJson<Uint8List>(preKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalPreKeyStore copyWith({
    int? preKeyId,
    Uint8List? preKey,
    DateTime? createdAt,
  }) => SignalPreKeyStore(
    preKeyId: preKeyId ?? this.preKeyId,
    preKey: preKey ?? this.preKey,
    createdAt: createdAt ?? this.createdAt,
  );
  SignalPreKeyStore copyWithCompanion(SignalPreKeyStoresCompanion data) {
    return SignalPreKeyStore(
      preKeyId: data.preKeyId.present ? data.preKeyId.value : this.preKeyId,
      preKey: data.preKey.present ? data.preKey.value : this.preKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalPreKeyStore(')
          ..write('preKeyId: $preKeyId, ')
          ..write('preKey: $preKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(preKeyId, $driftBlobEquality.hash(preKey), createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalPreKeyStore &&
          other.preKeyId == this.preKeyId &&
          $driftBlobEquality.equals(other.preKey, this.preKey) &&
          other.createdAt == this.createdAt);
}

class SignalPreKeyStoresCompanion extends UpdateCompanion<SignalPreKeyStore> {
  final Value<int> preKeyId;
  final Value<Uint8List> preKey;
  final Value<DateTime> createdAt;
  const SignalPreKeyStoresCompanion({
    this.preKeyId = const Value.absent(),
    this.preKey = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SignalPreKeyStoresCompanion.insert({
    this.preKeyId = const Value.absent(),
    required Uint8List preKey,
    this.createdAt = const Value.absent(),
  }) : preKey = Value(preKey);
  static Insertable<SignalPreKeyStore> custom({
    Expression<int>? preKeyId,
    Expression<Uint8List>? preKey,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (preKeyId != null) 'pre_key_id': preKeyId,
      if (preKey != null) 'pre_key': preKey,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SignalPreKeyStoresCompanion copyWith({
    Value<int>? preKeyId,
    Value<Uint8List>? preKey,
    Value<DateTime>? createdAt,
  }) {
    return SignalPreKeyStoresCompanion(
      preKeyId: preKeyId ?? this.preKeyId,
      preKey: preKey ?? this.preKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (preKeyId.present) {
      map['pre_key_id'] = Variable<int>(preKeyId.value);
    }
    if (preKey.present) {
      map['pre_key'] = Variable<Uint8List>(preKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalPreKeyStoresCompanion(')
          ..write('preKeyId: $preKeyId, ')
          ..write('preKey: $preKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SignalSenderKeyStoresTable extends SignalSenderKeyStores
    with TableInfo<$SignalSenderKeyStoresTable, SignalSenderKeyStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalSenderKeyStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _senderKeyNameMeta = const VerificationMeta(
    'senderKeyName',
  );
  @override
  late final GeneratedColumn<String> senderKeyName = GeneratedColumn<String>(
    'sender_key_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderKeyMeta = const VerificationMeta(
    'senderKey',
  );
  @override
  late final GeneratedColumn<Uint8List> senderKey = GeneratedColumn<Uint8List>(
    'sender_key',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [senderKeyName, senderKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_sender_key_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalSenderKeyStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sender_key_name')) {
      context.handle(
        _senderKeyNameMeta,
        senderKeyName.isAcceptableOrUnknown(
          data['sender_key_name']!,
          _senderKeyNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderKeyNameMeta);
    }
    if (data.containsKey('sender_key')) {
      context.handle(
        _senderKeyMeta,
        senderKey.isAcceptableOrUnknown(data['sender_key']!, _senderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_senderKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {senderKeyName};
  @override
  SignalSenderKeyStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSenderKeyStore(
      senderKeyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_key_name'],
      )!,
      senderKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}sender_key'],
      )!,
    );
  }

  @override
  $SignalSenderKeyStoresTable createAlias(String alias) {
    return $SignalSenderKeyStoresTable(attachedDatabase, alias);
  }
}

class SignalSenderKeyStore extends DataClass
    implements Insertable<SignalSenderKeyStore> {
  final String senderKeyName;
  final Uint8List senderKey;
  const SignalSenderKeyStore({
    required this.senderKeyName,
    required this.senderKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sender_key_name'] = Variable<String>(senderKeyName);
    map['sender_key'] = Variable<Uint8List>(senderKey);
    return map;
  }

  SignalSenderKeyStoresCompanion toCompanion(bool nullToAbsent) {
    return SignalSenderKeyStoresCompanion(
      senderKeyName: Value(senderKeyName),
      senderKey: Value(senderKey),
    );
  }

  factory SignalSenderKeyStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSenderKeyStore(
      senderKeyName: serializer.fromJson<String>(json['senderKeyName']),
      senderKey: serializer.fromJson<Uint8List>(json['senderKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'senderKeyName': serializer.toJson<String>(senderKeyName),
      'senderKey': serializer.toJson<Uint8List>(senderKey),
    };
  }

  SignalSenderKeyStore copyWith({
    String? senderKeyName,
    Uint8List? senderKey,
  }) => SignalSenderKeyStore(
    senderKeyName: senderKeyName ?? this.senderKeyName,
    senderKey: senderKey ?? this.senderKey,
  );
  SignalSenderKeyStore copyWithCompanion(SignalSenderKeyStoresCompanion data) {
    return SignalSenderKeyStore(
      senderKeyName: data.senderKeyName.present
          ? data.senderKeyName.value
          : this.senderKeyName,
      senderKey: data.senderKey.present ? data.senderKey.value : this.senderKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalSenderKeyStore(')
          ..write('senderKeyName: $senderKeyName, ')
          ..write('senderKey: $senderKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(senderKeyName, $driftBlobEquality.hash(senderKey));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalSenderKeyStore &&
          other.senderKeyName == this.senderKeyName &&
          $driftBlobEquality.equals(other.senderKey, this.senderKey));
}

class SignalSenderKeyStoresCompanion
    extends UpdateCompanion<SignalSenderKeyStore> {
  final Value<String> senderKeyName;
  final Value<Uint8List> senderKey;
  final Value<int> rowid;
  const SignalSenderKeyStoresCompanion({
    this.senderKeyName = const Value.absent(),
    this.senderKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalSenderKeyStoresCompanion.insert({
    required String senderKeyName,
    required Uint8List senderKey,
    this.rowid = const Value.absent(),
  }) : senderKeyName = Value(senderKeyName),
       senderKey = Value(senderKey);
  static Insertable<SignalSenderKeyStore> custom({
    Expression<String>? senderKeyName,
    Expression<Uint8List>? senderKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (senderKeyName != null) 'sender_key_name': senderKeyName,
      if (senderKey != null) 'sender_key': senderKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalSenderKeyStoresCompanion copyWith({
    Value<String>? senderKeyName,
    Value<Uint8List>? senderKey,
    Value<int>? rowid,
  }) {
    return SignalSenderKeyStoresCompanion(
      senderKeyName: senderKeyName ?? this.senderKeyName,
      senderKey: senderKey ?? this.senderKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (senderKeyName.present) {
      map['sender_key_name'] = Variable<String>(senderKeyName.value);
    }
    if (senderKey.present) {
      map['sender_key'] = Variable<Uint8List>(senderKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalSenderKeyStoresCompanion(')
          ..write('senderKeyName: $senderKeyName, ')
          ..write('senderKey: $senderKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalSessionStoresTable extends SignalSessionStores
    with TableInfo<$SignalSessionStoresTable, SignalSessionStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalSessionStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _sessionRecordMeta = const VerificationMeta(
    'sessionRecord',
  );
  @override
  late final GeneratedColumn<Uint8List> sessionRecord =
      GeneratedColumn<Uint8List>(
        'session_record',
        aliasedName,
        false,
        type: DriftSqlType.blob,
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
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    name,
    sessionRecord,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_session_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalSessionStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('session_record')) {
      context.handle(
        _sessionRecordMeta,
        sessionRecord.isAcceptableOrUnknown(
          data['session_record']!,
          _sessionRecordMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionRecordMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, name};
  @override
  SignalSessionStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSessionStore(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sessionRecord: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}session_record'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SignalSessionStoresTable createAlias(String alias) {
    return $SignalSessionStoresTable(attachedDatabase, alias);
  }
}

class SignalSessionStore extends DataClass
    implements Insertable<SignalSessionStore> {
  final int deviceId;
  final String name;
  final Uint8List sessionRecord;
  final DateTime createdAt;
  const SignalSessionStore({
    required this.deviceId,
    required this.name,
    required this.sessionRecord,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<int>(deviceId);
    map['name'] = Variable<String>(name);
    map['session_record'] = Variable<Uint8List>(sessionRecord);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SignalSessionStoresCompanion toCompanion(bool nullToAbsent) {
    return SignalSessionStoresCompanion(
      deviceId: Value(deviceId),
      name: Value(name),
      sessionRecord: Value(sessionRecord),
      createdAt: Value(createdAt),
    );
  }

  factory SignalSessionStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSessionStore(
      deviceId: serializer.fromJson<int>(json['deviceId']),
      name: serializer.fromJson<String>(json['name']),
      sessionRecord: serializer.fromJson<Uint8List>(json['sessionRecord']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<int>(deviceId),
      'name': serializer.toJson<String>(name),
      'sessionRecord': serializer.toJson<Uint8List>(sessionRecord),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalSessionStore copyWith({
    int? deviceId,
    String? name,
    Uint8List? sessionRecord,
    DateTime? createdAt,
  }) => SignalSessionStore(
    deviceId: deviceId ?? this.deviceId,
    name: name ?? this.name,
    sessionRecord: sessionRecord ?? this.sessionRecord,
    createdAt: createdAt ?? this.createdAt,
  );
  SignalSessionStore copyWithCompanion(SignalSessionStoresCompanion data) {
    return SignalSessionStore(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      sessionRecord: data.sessionRecord.present
          ? data.sessionRecord.value
          : this.sessionRecord,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalSessionStore(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('sessionRecord: $sessionRecord, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    name,
    $driftBlobEquality.hash(sessionRecord),
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalSessionStore &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          $driftBlobEquality.equals(other.sessionRecord, this.sessionRecord) &&
          other.createdAt == this.createdAt);
}

class SignalSessionStoresCompanion extends UpdateCompanion<SignalSessionStore> {
  final Value<int> deviceId;
  final Value<String> name;
  final Value<Uint8List> sessionRecord;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SignalSessionStoresCompanion({
    this.deviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.sessionRecord = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalSessionStoresCompanion.insert({
    required int deviceId,
    required String name,
    required Uint8List sessionRecord,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       name = Value(name),
       sessionRecord = Value(sessionRecord);
  static Insertable<SignalSessionStore> custom({
    Expression<int>? deviceId,
    Expression<String>? name,
    Expression<Uint8List>? sessionRecord,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (name != null) 'name': name,
      if (sessionRecord != null) 'session_record': sessionRecord,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalSessionStoresCompanion copyWith({
    Value<int>? deviceId,
    Value<String>? name,
    Value<Uint8List>? sessionRecord,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SignalSessionStoresCompanion(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      sessionRecord: sessionRecord ?? this.sessionRecord,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<int>(deviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sessionRecord.present) {
      map['session_record'] = Variable<Uint8List>(sessionRecord.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalSessionStoresCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('sessionRecord: $sessionRecord, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalSignedPreKeyStoresTable extends SignalSignedPreKeyStores
    with TableInfo<$SignalSignedPreKeyStoresTable, SignalSignedPreKeyStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalSignedPreKeyStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _signedPreKeyIdMeta = const VerificationMeta(
    'signedPreKeyId',
  );
  @override
  late final GeneratedColumn<int> signedPreKeyId = GeneratedColumn<int>(
    'signed_pre_key_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signedPreKeyMeta = const VerificationMeta(
    'signedPreKey',
  );
  @override
  late final GeneratedColumn<Uint8List> signedPreKey =
      GeneratedColumn<Uint8List>(
        'signed_pre_key',
        aliasedName,
        false,
        type: DriftSqlType.blob,
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
  @override
  List<GeneratedColumn> get $columns => [
    signedPreKeyId,
    signedPreKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_signed_pre_key_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<SignalSignedPreKeyStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('signed_pre_key_id')) {
      context.handle(
        _signedPreKeyIdMeta,
        signedPreKeyId.isAcceptableOrUnknown(
          data['signed_pre_key_id']!,
          _signedPreKeyIdMeta,
        ),
      );
    }
    if (data.containsKey('signed_pre_key')) {
      context.handle(
        _signedPreKeyMeta,
        signedPreKey.isAcceptableOrUnknown(
          data['signed_pre_key']!,
          _signedPreKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signedPreKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {signedPreKeyId};
  @override
  SignalSignedPreKeyStore map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSignedPreKeyStore(
      signedPreKeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}signed_pre_key_id'],
      )!,
      signedPreKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}signed_pre_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SignalSignedPreKeyStoresTable createAlias(String alias) {
    return $SignalSignedPreKeyStoresTable(attachedDatabase, alias);
  }
}

class SignalSignedPreKeyStore extends DataClass
    implements Insertable<SignalSignedPreKeyStore> {
  final int signedPreKeyId;
  final Uint8List signedPreKey;
  final DateTime createdAt;
  const SignalSignedPreKeyStore({
    required this.signedPreKeyId,
    required this.signedPreKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['signed_pre_key_id'] = Variable<int>(signedPreKeyId);
    map['signed_pre_key'] = Variable<Uint8List>(signedPreKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SignalSignedPreKeyStoresCompanion toCompanion(bool nullToAbsent) {
    return SignalSignedPreKeyStoresCompanion(
      signedPreKeyId: Value(signedPreKeyId),
      signedPreKey: Value(signedPreKey),
      createdAt: Value(createdAt),
    );
  }

  factory SignalSignedPreKeyStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSignedPreKeyStore(
      signedPreKeyId: serializer.fromJson<int>(json['signedPreKeyId']),
      signedPreKey: serializer.fromJson<Uint8List>(json['signedPreKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'signedPreKeyId': serializer.toJson<int>(signedPreKeyId),
      'signedPreKey': serializer.toJson<Uint8List>(signedPreKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalSignedPreKeyStore copyWith({
    int? signedPreKeyId,
    Uint8List? signedPreKey,
    DateTime? createdAt,
  }) => SignalSignedPreKeyStore(
    signedPreKeyId: signedPreKeyId ?? this.signedPreKeyId,
    signedPreKey: signedPreKey ?? this.signedPreKey,
    createdAt: createdAt ?? this.createdAt,
  );
  SignalSignedPreKeyStore copyWithCompanion(
    SignalSignedPreKeyStoresCompanion data,
  ) {
    return SignalSignedPreKeyStore(
      signedPreKeyId: data.signedPreKeyId.present
          ? data.signedPreKeyId.value
          : this.signedPreKeyId,
      signedPreKey: data.signedPreKey.present
          ? data.signedPreKey.value
          : this.signedPreKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalSignedPreKeyStore(')
          ..write('signedPreKeyId: $signedPreKeyId, ')
          ..write('signedPreKey: $signedPreKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    signedPreKeyId,
    $driftBlobEquality.hash(signedPreKey),
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalSignedPreKeyStore &&
          other.signedPreKeyId == this.signedPreKeyId &&
          $driftBlobEquality.equals(other.signedPreKey, this.signedPreKey) &&
          other.createdAt == this.createdAt);
}

class SignalSignedPreKeyStoresCompanion
    extends UpdateCompanion<SignalSignedPreKeyStore> {
  final Value<int> signedPreKeyId;
  final Value<Uint8List> signedPreKey;
  final Value<DateTime> createdAt;
  const SignalSignedPreKeyStoresCompanion({
    this.signedPreKeyId = const Value.absent(),
    this.signedPreKey = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SignalSignedPreKeyStoresCompanion.insert({
    this.signedPreKeyId = const Value.absent(),
    required Uint8List signedPreKey,
    this.createdAt = const Value.absent(),
  }) : signedPreKey = Value(signedPreKey);
  static Insertable<SignalSignedPreKeyStore> custom({
    Expression<int>? signedPreKeyId,
    Expression<Uint8List>? signedPreKey,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (signedPreKeyId != null) 'signed_pre_key_id': signedPreKeyId,
      if (signedPreKey != null) 'signed_pre_key': signedPreKey,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SignalSignedPreKeyStoresCompanion copyWith({
    Value<int>? signedPreKeyId,
    Value<Uint8List>? signedPreKey,
    Value<DateTime>? createdAt,
  }) {
    return SignalSignedPreKeyStoresCompanion(
      signedPreKeyId: signedPreKeyId ?? this.signedPreKeyId,
      signedPreKey: signedPreKey ?? this.signedPreKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (signedPreKeyId.present) {
      map['signed_pre_key_id'] = Variable<int>(signedPreKeyId.value);
    }
    if (signedPreKey.present) {
      map['signed_pre_key'] = Variable<Uint8List>(signedPreKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalSignedPreKeyStoresCompanion(')
          ..write('signedPreKeyId: $signedPreKeyId, ')
          ..write('signedPreKey: $signedPreKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$SignalDB extends GeneratedDatabase {
  _$SignalDB(QueryExecutor e) : super(e);
  $SignalDBManager get managers => $SignalDBManager(this);
  late final $SignalIdentityKeyStoresTable signalIdentityKeyStores =
      $SignalIdentityKeyStoresTable(this);
  late final $SignalPreKeyStoresTable signalPreKeyStores =
      $SignalPreKeyStoresTable(this);
  late final $SignalSenderKeyStoresTable signalSenderKeyStores =
      $SignalSenderKeyStoresTable(this);
  late final $SignalSessionStoresTable signalSessionStores =
      $SignalSessionStoresTable(this);
  late final $SignalSignedPreKeyStoresTable signalSignedPreKeyStores =
      $SignalSignedPreKeyStoresTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    signalIdentityKeyStores,
    signalPreKeyStores,
    signalSenderKeyStores,
    signalSessionStores,
    signalSignedPreKeyStores,
  ];
}

typedef $$SignalIdentityKeyStoresTableCreateCompanionBuilder =
    SignalIdentityKeyStoresCompanion Function({
      required int deviceId,
      required String name,
      required Uint8List identityKey,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$SignalIdentityKeyStoresTableUpdateCompanionBuilder =
    SignalIdentityKeyStoresCompanion Function({
      Value<int> deviceId,
      Value<String> name,
      Value<Uint8List> identityKey,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SignalIdentityKeyStoresTableFilterComposer
    extends Composer<_$SignalDB, $SignalIdentityKeyStoresTable> {
  $$SignalIdentityKeyStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalIdentityKeyStoresTableOrderingComposer
    extends Composer<_$SignalDB, $SignalIdentityKeyStoresTable> {
  $$SignalIdentityKeyStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalIdentityKeyStoresTableAnnotationComposer
    extends Composer<_$SignalDB, $SignalIdentityKeyStoresTable> {
  $$SignalIdentityKeyStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<Uint8List> get identityKey => $composableBuilder(
    column: $table.identityKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignalIdentityKeyStoresTableTableManager
    extends
        RootTableManager<
          _$SignalDB,
          $SignalIdentityKeyStoresTable,
          SignalIdentityKeyStore,
          $$SignalIdentityKeyStoresTableFilterComposer,
          $$SignalIdentityKeyStoresTableOrderingComposer,
          $$SignalIdentityKeyStoresTableAnnotationComposer,
          $$SignalIdentityKeyStoresTableCreateCompanionBuilder,
          $$SignalIdentityKeyStoresTableUpdateCompanionBuilder,
          (
            SignalIdentityKeyStore,
            BaseReferences<
              _$SignalDB,
              $SignalIdentityKeyStoresTable,
              SignalIdentityKeyStore
            >,
          ),
          SignalIdentityKeyStore,
          PrefetchHooks Function()
        > {
  $$SignalIdentityKeyStoresTableTableManager(
    _$SignalDB db,
    $SignalIdentityKeyStoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalIdentityKeyStoresTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SignalIdentityKeyStoresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SignalIdentityKeyStoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> deviceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Uint8List> identityKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalIdentityKeyStoresCompanion(
                deviceId: deviceId,
                name: name,
                identityKey: identityKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int deviceId,
                required String name,
                required Uint8List identityKey,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalIdentityKeyStoresCompanion.insert(
                deviceId: deviceId,
                name: name,
                identityKey: identityKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalIdentityKeyStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDB,
      $SignalIdentityKeyStoresTable,
      SignalIdentityKeyStore,
      $$SignalIdentityKeyStoresTableFilterComposer,
      $$SignalIdentityKeyStoresTableOrderingComposer,
      $$SignalIdentityKeyStoresTableAnnotationComposer,
      $$SignalIdentityKeyStoresTableCreateCompanionBuilder,
      $$SignalIdentityKeyStoresTableUpdateCompanionBuilder,
      (
        SignalIdentityKeyStore,
        BaseReferences<
          _$SignalDB,
          $SignalIdentityKeyStoresTable,
          SignalIdentityKeyStore
        >,
      ),
      SignalIdentityKeyStore,
      PrefetchHooks Function()
    >;
typedef $$SignalPreKeyStoresTableCreateCompanionBuilder =
    SignalPreKeyStoresCompanion Function({
      Value<int> preKeyId,
      required Uint8List preKey,
      Value<DateTime> createdAt,
    });
typedef $$SignalPreKeyStoresTableUpdateCompanionBuilder =
    SignalPreKeyStoresCompanion Function({
      Value<int> preKeyId,
      Value<Uint8List> preKey,
      Value<DateTime> createdAt,
    });

class $$SignalPreKeyStoresTableFilterComposer
    extends Composer<_$SignalDB, $SignalPreKeyStoresTable> {
  $$SignalPreKeyStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get preKeyId => $composableBuilder(
    column: $table.preKeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get preKey => $composableBuilder(
    column: $table.preKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalPreKeyStoresTableOrderingComposer
    extends Composer<_$SignalDB, $SignalPreKeyStoresTable> {
  $$SignalPreKeyStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get preKeyId => $composableBuilder(
    column: $table.preKeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get preKey => $composableBuilder(
    column: $table.preKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalPreKeyStoresTableAnnotationComposer
    extends Composer<_$SignalDB, $SignalPreKeyStoresTable> {
  $$SignalPreKeyStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get preKeyId =>
      $composableBuilder(column: $table.preKeyId, builder: (column) => column);

  GeneratedColumn<Uint8List> get preKey =>
      $composableBuilder(column: $table.preKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignalPreKeyStoresTableTableManager
    extends
        RootTableManager<
          _$SignalDB,
          $SignalPreKeyStoresTable,
          SignalPreKeyStore,
          $$SignalPreKeyStoresTableFilterComposer,
          $$SignalPreKeyStoresTableOrderingComposer,
          $$SignalPreKeyStoresTableAnnotationComposer,
          $$SignalPreKeyStoresTableCreateCompanionBuilder,
          $$SignalPreKeyStoresTableUpdateCompanionBuilder,
          (
            SignalPreKeyStore,
            BaseReferences<
              _$SignalDB,
              $SignalPreKeyStoresTable,
              SignalPreKeyStore
            >,
          ),
          SignalPreKeyStore,
          PrefetchHooks Function()
        > {
  $$SignalPreKeyStoresTableTableManager(
    _$SignalDB db,
    $SignalPreKeyStoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalPreKeyStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalPreKeyStoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalPreKeyStoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> preKeyId = const Value.absent(),
                Value<Uint8List> preKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SignalPreKeyStoresCompanion(
                preKeyId: preKeyId,
                preKey: preKey,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> preKeyId = const Value.absent(),
                required Uint8List preKey,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SignalPreKeyStoresCompanion.insert(
                preKeyId: preKeyId,
                preKey: preKey,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalPreKeyStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDB,
      $SignalPreKeyStoresTable,
      SignalPreKeyStore,
      $$SignalPreKeyStoresTableFilterComposer,
      $$SignalPreKeyStoresTableOrderingComposer,
      $$SignalPreKeyStoresTableAnnotationComposer,
      $$SignalPreKeyStoresTableCreateCompanionBuilder,
      $$SignalPreKeyStoresTableUpdateCompanionBuilder,
      (
        SignalPreKeyStore,
        BaseReferences<_$SignalDB, $SignalPreKeyStoresTable, SignalPreKeyStore>,
      ),
      SignalPreKeyStore,
      PrefetchHooks Function()
    >;
typedef $$SignalSenderKeyStoresTableCreateCompanionBuilder =
    SignalSenderKeyStoresCompanion Function({
      required String senderKeyName,
      required Uint8List senderKey,
      Value<int> rowid,
    });
typedef $$SignalSenderKeyStoresTableUpdateCompanionBuilder =
    SignalSenderKeyStoresCompanion Function({
      Value<String> senderKeyName,
      Value<Uint8List> senderKey,
      Value<int> rowid,
    });

class $$SignalSenderKeyStoresTableFilterComposer
    extends Composer<_$SignalDB, $SignalSenderKeyStoresTable> {
  $$SignalSenderKeyStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get senderKeyName => $composableBuilder(
    column: $table.senderKeyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get senderKey => $composableBuilder(
    column: $table.senderKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalSenderKeyStoresTableOrderingComposer
    extends Composer<_$SignalDB, $SignalSenderKeyStoresTable> {
  $$SignalSenderKeyStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get senderKeyName => $composableBuilder(
    column: $table.senderKeyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get senderKey => $composableBuilder(
    column: $table.senderKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalSenderKeyStoresTableAnnotationComposer
    extends Composer<_$SignalDB, $SignalSenderKeyStoresTable> {
  $$SignalSenderKeyStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get senderKeyName => $composableBuilder(
    column: $table.senderKeyName,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get senderKey =>
      $composableBuilder(column: $table.senderKey, builder: (column) => column);
}

class $$SignalSenderKeyStoresTableTableManager
    extends
        RootTableManager<
          _$SignalDB,
          $SignalSenderKeyStoresTable,
          SignalSenderKeyStore,
          $$SignalSenderKeyStoresTableFilterComposer,
          $$SignalSenderKeyStoresTableOrderingComposer,
          $$SignalSenderKeyStoresTableAnnotationComposer,
          $$SignalSenderKeyStoresTableCreateCompanionBuilder,
          $$SignalSenderKeyStoresTableUpdateCompanionBuilder,
          (
            SignalSenderKeyStore,
            BaseReferences<
              _$SignalDB,
              $SignalSenderKeyStoresTable,
              SignalSenderKeyStore
            >,
          ),
          SignalSenderKeyStore,
          PrefetchHooks Function()
        > {
  $$SignalSenderKeyStoresTableTableManager(
    _$SignalDB db,
    $SignalSenderKeyStoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSenderKeyStoresTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SignalSenderKeyStoresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SignalSenderKeyStoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> senderKeyName = const Value.absent(),
                Value<Uint8List> senderKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalSenderKeyStoresCompanion(
                senderKeyName: senderKeyName,
                senderKey: senderKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String senderKeyName,
                required Uint8List senderKey,
                Value<int> rowid = const Value.absent(),
              }) => SignalSenderKeyStoresCompanion.insert(
                senderKeyName: senderKeyName,
                senderKey: senderKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalSenderKeyStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDB,
      $SignalSenderKeyStoresTable,
      SignalSenderKeyStore,
      $$SignalSenderKeyStoresTableFilterComposer,
      $$SignalSenderKeyStoresTableOrderingComposer,
      $$SignalSenderKeyStoresTableAnnotationComposer,
      $$SignalSenderKeyStoresTableCreateCompanionBuilder,
      $$SignalSenderKeyStoresTableUpdateCompanionBuilder,
      (
        SignalSenderKeyStore,
        BaseReferences<
          _$SignalDB,
          $SignalSenderKeyStoresTable,
          SignalSenderKeyStore
        >,
      ),
      SignalSenderKeyStore,
      PrefetchHooks Function()
    >;
typedef $$SignalSessionStoresTableCreateCompanionBuilder =
    SignalSessionStoresCompanion Function({
      required int deviceId,
      required String name,
      required Uint8List sessionRecord,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$SignalSessionStoresTableUpdateCompanionBuilder =
    SignalSessionStoresCompanion Function({
      Value<int> deviceId,
      Value<String> name,
      Value<Uint8List> sessionRecord,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SignalSessionStoresTableFilterComposer
    extends Composer<_$SignalDB, $SignalSessionStoresTable> {
  $$SignalSessionStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sessionRecord => $composableBuilder(
    column: $table.sessionRecord,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalSessionStoresTableOrderingComposer
    extends Composer<_$SignalDB, $SignalSessionStoresTable> {
  $$SignalSessionStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sessionRecord => $composableBuilder(
    column: $table.sessionRecord,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalSessionStoresTableAnnotationComposer
    extends Composer<_$SignalDB, $SignalSessionStoresTable> {
  $$SignalSessionStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<Uint8List> get sessionRecord => $composableBuilder(
    column: $table.sessionRecord,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignalSessionStoresTableTableManager
    extends
        RootTableManager<
          _$SignalDB,
          $SignalSessionStoresTable,
          SignalSessionStore,
          $$SignalSessionStoresTableFilterComposer,
          $$SignalSessionStoresTableOrderingComposer,
          $$SignalSessionStoresTableAnnotationComposer,
          $$SignalSessionStoresTableCreateCompanionBuilder,
          $$SignalSessionStoresTableUpdateCompanionBuilder,
          (
            SignalSessionStore,
            BaseReferences<
              _$SignalDB,
              $SignalSessionStoresTable,
              SignalSessionStore
            >,
          ),
          SignalSessionStore,
          PrefetchHooks Function()
        > {
  $$SignalSessionStoresTableTableManager(
    _$SignalDB db,
    $SignalSessionStoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSessionStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalSessionStoresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SignalSessionStoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> deviceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Uint8List> sessionRecord = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalSessionStoresCompanion(
                deviceId: deviceId,
                name: name,
                sessionRecord: sessionRecord,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int deviceId,
                required String name,
                required Uint8List sessionRecord,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SignalSessionStoresCompanion.insert(
                deviceId: deviceId,
                name: name,
                sessionRecord: sessionRecord,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalSessionStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDB,
      $SignalSessionStoresTable,
      SignalSessionStore,
      $$SignalSessionStoresTableFilterComposer,
      $$SignalSessionStoresTableOrderingComposer,
      $$SignalSessionStoresTableAnnotationComposer,
      $$SignalSessionStoresTableCreateCompanionBuilder,
      $$SignalSessionStoresTableUpdateCompanionBuilder,
      (
        SignalSessionStore,
        BaseReferences<
          _$SignalDB,
          $SignalSessionStoresTable,
          SignalSessionStore
        >,
      ),
      SignalSessionStore,
      PrefetchHooks Function()
    >;
typedef $$SignalSignedPreKeyStoresTableCreateCompanionBuilder =
    SignalSignedPreKeyStoresCompanion Function({
      Value<int> signedPreKeyId,
      required Uint8List signedPreKey,
      Value<DateTime> createdAt,
    });
typedef $$SignalSignedPreKeyStoresTableUpdateCompanionBuilder =
    SignalSignedPreKeyStoresCompanion Function({
      Value<int> signedPreKeyId,
      Value<Uint8List> signedPreKey,
      Value<DateTime> createdAt,
    });

class $$SignalSignedPreKeyStoresTableFilterComposer
    extends Composer<_$SignalDB, $SignalSignedPreKeyStoresTable> {
  $$SignalSignedPreKeyStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get signedPreKeyId => $composableBuilder(
    column: $table.signedPreKeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get signedPreKey => $composableBuilder(
    column: $table.signedPreKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalSignedPreKeyStoresTableOrderingComposer
    extends Composer<_$SignalDB, $SignalSignedPreKeyStoresTable> {
  $$SignalSignedPreKeyStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get signedPreKeyId => $composableBuilder(
    column: $table.signedPreKeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get signedPreKey => $composableBuilder(
    column: $table.signedPreKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalSignedPreKeyStoresTableAnnotationComposer
    extends Composer<_$SignalDB, $SignalSignedPreKeyStoresTable> {
  $$SignalSignedPreKeyStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get signedPreKeyId => $composableBuilder(
    column: $table.signedPreKeyId,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get signedPreKey => $composableBuilder(
    column: $table.signedPreKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignalSignedPreKeyStoresTableTableManager
    extends
        RootTableManager<
          _$SignalDB,
          $SignalSignedPreKeyStoresTable,
          SignalSignedPreKeyStore,
          $$SignalSignedPreKeyStoresTableFilterComposer,
          $$SignalSignedPreKeyStoresTableOrderingComposer,
          $$SignalSignedPreKeyStoresTableAnnotationComposer,
          $$SignalSignedPreKeyStoresTableCreateCompanionBuilder,
          $$SignalSignedPreKeyStoresTableUpdateCompanionBuilder,
          (
            SignalSignedPreKeyStore,
            BaseReferences<
              _$SignalDB,
              $SignalSignedPreKeyStoresTable,
              SignalSignedPreKeyStore
            >,
          ),
          SignalSignedPreKeyStore,
          PrefetchHooks Function()
        > {
  $$SignalSignedPreKeyStoresTableTableManager(
    _$SignalDB db,
    $SignalSignedPreKeyStoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSignedPreKeyStoresTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SignalSignedPreKeyStoresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SignalSignedPreKeyStoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> signedPreKeyId = const Value.absent(),
                Value<Uint8List> signedPreKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SignalSignedPreKeyStoresCompanion(
                signedPreKeyId: signedPreKeyId,
                signedPreKey: signedPreKey,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> signedPreKeyId = const Value.absent(),
                required Uint8List signedPreKey,
                Value<DateTime> createdAt = const Value.absent(),
              }) => SignalSignedPreKeyStoresCompanion.insert(
                signedPreKeyId: signedPreKeyId,
                signedPreKey: signedPreKey,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalSignedPreKeyStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$SignalDB,
      $SignalSignedPreKeyStoresTable,
      SignalSignedPreKeyStore,
      $$SignalSignedPreKeyStoresTableFilterComposer,
      $$SignalSignedPreKeyStoresTableOrderingComposer,
      $$SignalSignedPreKeyStoresTableAnnotationComposer,
      $$SignalSignedPreKeyStoresTableCreateCompanionBuilder,
      $$SignalSignedPreKeyStoresTableUpdateCompanionBuilder,
      (
        SignalSignedPreKeyStore,
        BaseReferences<
          _$SignalDB,
          $SignalSignedPreKeyStoresTable,
          SignalSignedPreKeyStore
        >,
      ),
      SignalSignedPreKeyStore,
      PrefetchHooks Function()
    >;

class $SignalDBManager {
  final _$SignalDB _db;
  $SignalDBManager(this._db);
  $$SignalIdentityKeyStoresTableTableManager get signalIdentityKeyStores =>
      $$SignalIdentityKeyStoresTableTableManager(
        _db,
        _db.signalIdentityKeyStores,
      );
  $$SignalPreKeyStoresTableTableManager get signalPreKeyStores =>
      $$SignalPreKeyStoresTableTableManager(_db, _db.signalPreKeyStores);
  $$SignalSenderKeyStoresTableTableManager get signalSenderKeyStores =>
      $$SignalSenderKeyStoresTableTableManager(_db, _db.signalSenderKeyStores);
  $$SignalSessionStoresTableTableManager get signalSessionStores =>
      $$SignalSessionStoresTableTableManager(_db, _db.signalSessionStores);
  $$SignalSignedPreKeyStoresTableTableManager get signalSignedPreKeyStores =>
      $$SignalSignedPreKeyStoresTableTableManager(
        _db,
        _db.signalSignedPreKeyStores,
      );
}
