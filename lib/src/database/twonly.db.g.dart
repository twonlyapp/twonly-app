// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twonly.db.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nickNameMeta =
      const VerificationMeta('nickName');
  @override
  late final GeneratedColumn<String> nickName = GeneratedColumn<String>(
      'nick_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _avatarSvgCompressedMeta =
      const VerificationMeta('avatarSvgCompressed');
  @override
  late final GeneratedColumn<Uint8List> avatarSvgCompressed =
      GeneratedColumn<Uint8List>('avatar_svg_compressed', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _senderProfileCounterMeta =
      const VerificationMeta('senderProfileCounter');
  @override
  late final GeneratedColumn<int> senderProfileCounter = GeneratedColumn<int>(
      'sender_profile_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _acceptedMeta =
      const VerificationMeta('accepted');
  @override
  late final GeneratedColumn<bool> accepted = GeneratedColumn<bool>(
      'accepted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("accepted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedByUserMeta =
      const VerificationMeta('deletedByUser');
  @override
  late final GeneratedColumn<bool> deletedByUser = GeneratedColumn<bool>(
      'deleted_by_user', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("deleted_by_user" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _requestedMeta =
      const VerificationMeta('requested');
  @override
  late final GeneratedColumn<bool> requested = GeneratedColumn<bool>(
      'requested', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("requested" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _blockedMeta =
      const VerificationMeta('blocked');
  @override
  late final GeneratedColumn<bool> blocked = GeneratedColumn<bool>(
      'blocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("blocked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _verifiedMeta =
      const VerificationMeta('verified');
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
      'verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _accountDeletedMeta =
      const VerificationMeta('accountDeleted');
  @override
  late final GeneratedColumn<bool> accountDeleted = GeneratedColumn<bool>(
      'account_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("account_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        username,
        displayName,
        nickName,
        avatarSvgCompressed,
        senderProfileCounter,
        accepted,
        deletedByUser,
        requested,
        blocked,
        verified,
        accountDeleted,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(Insertable<Contact> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('nick_name')) {
      context.handle(_nickNameMeta,
          nickName.isAcceptableOrUnknown(data['nick_name']!, _nickNameMeta));
    }
    if (data.containsKey('avatar_svg_compressed')) {
      context.handle(
          _avatarSvgCompressedMeta,
          avatarSvgCompressed.isAcceptableOrUnknown(
              data['avatar_svg_compressed']!, _avatarSvgCompressedMeta));
    }
    if (data.containsKey('sender_profile_counter')) {
      context.handle(
          _senderProfileCounterMeta,
          senderProfileCounter.isAcceptableOrUnknown(
              data['sender_profile_counter']!, _senderProfileCounterMeta));
    }
    if (data.containsKey('accepted')) {
      context.handle(_acceptedMeta,
          accepted.isAcceptableOrUnknown(data['accepted']!, _acceptedMeta));
    }
    if (data.containsKey('deleted_by_user')) {
      context.handle(
          _deletedByUserMeta,
          deletedByUser.isAcceptableOrUnknown(
              data['deleted_by_user']!, _deletedByUserMeta));
    }
    if (data.containsKey('requested')) {
      context.handle(_requestedMeta,
          requested.isAcceptableOrUnknown(data['requested']!, _requestedMeta));
    }
    if (data.containsKey('blocked')) {
      context.handle(_blockedMeta,
          blocked.isAcceptableOrUnknown(data['blocked']!, _blockedMeta));
    }
    if (data.containsKey('verified')) {
      context.handle(_verifiedMeta,
          verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta));
    }
    if (data.containsKey('account_deleted')) {
      context.handle(
          _accountDeletedMeta,
          accountDeleted.isAcceptableOrUnknown(
              data['account_deleted']!, _accountDeletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      nickName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nick_name']),
      avatarSvgCompressed: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}avatar_svg_compressed']),
      senderProfileCounter: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}sender_profile_counter'])!,
      accepted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}accepted'])!,
      deletedByUser: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted_by_user'])!,
      requested: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}requested'])!,
      blocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}blocked'])!,
      verified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}verified'])!,
      accountDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}account_deleted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final int userId;
  final String username;
  final String? displayName;
  final String? nickName;
  final Uint8List? avatarSvgCompressed;
  final int senderProfileCounter;
  final bool accepted;
  final bool deletedByUser;
  final bool requested;
  final bool blocked;
  final bool verified;
  final bool accountDeleted;
  final DateTime createdAt;
  const Contact(
      {required this.userId,
      required this.username,
      this.displayName,
      this.nickName,
      this.avatarSvgCompressed,
      required this.senderProfileCounter,
      required this.accepted,
      required this.deletedByUser,
      required this.requested,
      required this.blocked,
      required this.verified,
      required this.accountDeleted,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || nickName != null) {
      map['nick_name'] = Variable<String>(nickName);
    }
    if (!nullToAbsent || avatarSvgCompressed != null) {
      map['avatar_svg_compressed'] = Variable<Uint8List>(avatarSvgCompressed);
    }
    map['sender_profile_counter'] = Variable<int>(senderProfileCounter);
    map['accepted'] = Variable<bool>(accepted);
    map['deleted_by_user'] = Variable<bool>(deletedByUser);
    map['requested'] = Variable<bool>(requested);
    map['blocked'] = Variable<bool>(blocked);
    map['verified'] = Variable<bool>(verified);
    map['account_deleted'] = Variable<bool>(accountDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      userId: Value(userId),
      username: Value(username),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      nickName: nickName == null && nullToAbsent
          ? const Value.absent()
          : Value(nickName),
      avatarSvgCompressed: avatarSvgCompressed == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarSvgCompressed),
      senderProfileCounter: Value(senderProfileCounter),
      accepted: Value(accepted),
      deletedByUser: Value(deletedByUser),
      requested: Value(requested),
      blocked: Value(blocked),
      verified: Value(verified),
      accountDeleted: Value(accountDeleted),
      createdAt: Value(createdAt),
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      userId: serializer.fromJson<int>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      nickName: serializer.fromJson<String?>(json['nickName']),
      avatarSvgCompressed:
          serializer.fromJson<Uint8List?>(json['avatarSvgCompressed']),
      senderProfileCounter:
          serializer.fromJson<int>(json['senderProfileCounter']),
      accepted: serializer.fromJson<bool>(json['accepted']),
      deletedByUser: serializer.fromJson<bool>(json['deletedByUser']),
      requested: serializer.fromJson<bool>(json['requested']),
      blocked: serializer.fromJson<bool>(json['blocked']),
      verified: serializer.fromJson<bool>(json['verified']),
      accountDeleted: serializer.fromJson<bool>(json['accountDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'username': serializer.toJson<String>(username),
      'displayName': serializer.toJson<String?>(displayName),
      'nickName': serializer.toJson<String?>(nickName),
      'avatarSvgCompressed': serializer.toJson<Uint8List?>(avatarSvgCompressed),
      'senderProfileCounter': serializer.toJson<int>(senderProfileCounter),
      'accepted': serializer.toJson<bool>(accepted),
      'deletedByUser': serializer.toJson<bool>(deletedByUser),
      'requested': serializer.toJson<bool>(requested),
      'blocked': serializer.toJson<bool>(blocked),
      'verified': serializer.toJson<bool>(verified),
      'accountDeleted': serializer.toJson<bool>(accountDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Contact copyWith(
          {int? userId,
          String? username,
          Value<String?> displayName = const Value.absent(),
          Value<String?> nickName = const Value.absent(),
          Value<Uint8List?> avatarSvgCompressed = const Value.absent(),
          int? senderProfileCounter,
          bool? accepted,
          bool? deletedByUser,
          bool? requested,
          bool? blocked,
          bool? verified,
          bool? accountDeleted,
          DateTime? createdAt}) =>
      Contact(
        userId: userId ?? this.userId,
        username: username ?? this.username,
        displayName: displayName.present ? displayName.value : this.displayName,
        nickName: nickName.present ? nickName.value : this.nickName,
        avatarSvgCompressed: avatarSvgCompressed.present
            ? avatarSvgCompressed.value
            : this.avatarSvgCompressed,
        senderProfileCounter: senderProfileCounter ?? this.senderProfileCounter,
        accepted: accepted ?? this.accepted,
        deletedByUser: deletedByUser ?? this.deletedByUser,
        requested: requested ?? this.requested,
        blocked: blocked ?? this.blocked,
        verified: verified ?? this.verified,
        accountDeleted: accountDeleted ?? this.accountDeleted,
        createdAt: createdAt ?? this.createdAt,
      );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      nickName: data.nickName.present ? data.nickName.value : this.nickName,
      avatarSvgCompressed: data.avatarSvgCompressed.present
          ? data.avatarSvgCompressed.value
          : this.avatarSvgCompressed,
      senderProfileCounter: data.senderProfileCounter.present
          ? data.senderProfileCounter.value
          : this.senderProfileCounter,
      accepted: data.accepted.present ? data.accepted.value : this.accepted,
      deletedByUser: data.deletedByUser.present
          ? data.deletedByUser.value
          : this.deletedByUser,
      requested: data.requested.present ? data.requested.value : this.requested,
      blocked: data.blocked.present ? data.blocked.value : this.blocked,
      verified: data.verified.present ? data.verified.value : this.verified,
      accountDeleted: data.accountDeleted.present
          ? data.accountDeleted.value
          : this.accountDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('nickName: $nickName, ')
          ..write('avatarSvgCompressed: $avatarSvgCompressed, ')
          ..write('senderProfileCounter: $senderProfileCounter, ')
          ..write('accepted: $accepted, ')
          ..write('deletedByUser: $deletedByUser, ')
          ..write('requested: $requested, ')
          ..write('blocked: $blocked, ')
          ..write('verified: $verified, ')
          ..write('accountDeleted: $accountDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId,
      username,
      displayName,
      nickName,
      $driftBlobEquality.hash(avatarSvgCompressed),
      senderProfileCounter,
      accepted,
      deletedByUser,
      requested,
      blocked,
      verified,
      accountDeleted,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.nickName == this.nickName &&
          $driftBlobEquality.equals(
              other.avatarSvgCompressed, this.avatarSvgCompressed) &&
          other.senderProfileCounter == this.senderProfileCounter &&
          other.accepted == this.accepted &&
          other.deletedByUser == this.deletedByUser &&
          other.requested == this.requested &&
          other.blocked == this.blocked &&
          other.verified == this.verified &&
          other.accountDeleted == this.accountDeleted &&
          other.createdAt == this.createdAt);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<int> userId;
  final Value<String> username;
  final Value<String?> displayName;
  final Value<String?> nickName;
  final Value<Uint8List?> avatarSvgCompressed;
  final Value<int> senderProfileCounter;
  final Value<bool> accepted;
  final Value<bool> deletedByUser;
  final Value<bool> requested;
  final Value<bool> blocked;
  final Value<bool> verified;
  final Value<bool> accountDeleted;
  final Value<DateTime> createdAt;
  const ContactsCompanion({
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.nickName = const Value.absent(),
    this.avatarSvgCompressed = const Value.absent(),
    this.senderProfileCounter = const Value.absent(),
    this.accepted = const Value.absent(),
    this.deletedByUser = const Value.absent(),
    this.requested = const Value.absent(),
    this.blocked = const Value.absent(),
    this.verified = const Value.absent(),
    this.accountDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.userId = const Value.absent(),
    required String username,
    this.displayName = const Value.absent(),
    this.nickName = const Value.absent(),
    this.avatarSvgCompressed = const Value.absent(),
    this.senderProfileCounter = const Value.absent(),
    this.accepted = const Value.absent(),
    this.deletedByUser = const Value.absent(),
    this.requested = const Value.absent(),
    this.blocked = const Value.absent(),
    this.verified = const Value.absent(),
    this.accountDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : username = Value(username);
  static Insertable<Contact> custom({
    Expression<int>? userId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? nickName,
    Expression<Uint8List>? avatarSvgCompressed,
    Expression<int>? senderProfileCounter,
    Expression<bool>? accepted,
    Expression<bool>? deletedByUser,
    Expression<bool>? requested,
    Expression<bool>? blocked,
    Expression<bool>? verified,
    Expression<bool>? accountDeleted,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (nickName != null) 'nick_name': nickName,
      if (avatarSvgCompressed != null)
        'avatar_svg_compressed': avatarSvgCompressed,
      if (senderProfileCounter != null)
        'sender_profile_counter': senderProfileCounter,
      if (accepted != null) 'accepted': accepted,
      if (deletedByUser != null) 'deleted_by_user': deletedByUser,
      if (requested != null) 'requested': requested,
      if (blocked != null) 'blocked': blocked,
      if (verified != null) 'verified': verified,
      if (accountDeleted != null) 'account_deleted': accountDeleted,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ContactsCompanion copyWith(
      {Value<int>? userId,
      Value<String>? username,
      Value<String?>? displayName,
      Value<String?>? nickName,
      Value<Uint8List?>? avatarSvgCompressed,
      Value<int>? senderProfileCounter,
      Value<bool>? accepted,
      Value<bool>? deletedByUser,
      Value<bool>? requested,
      Value<bool>? blocked,
      Value<bool>? verified,
      Value<bool>? accountDeleted,
      Value<DateTime>? createdAt}) {
    return ContactsCompanion(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      nickName: nickName ?? this.nickName,
      avatarSvgCompressed: avatarSvgCompressed ?? this.avatarSvgCompressed,
      senderProfileCounter: senderProfileCounter ?? this.senderProfileCounter,
      accepted: accepted ?? this.accepted,
      deletedByUser: deletedByUser ?? this.deletedByUser,
      requested: requested ?? this.requested,
      blocked: blocked ?? this.blocked,
      verified: verified ?? this.verified,
      accountDeleted: accountDeleted ?? this.accountDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (nickName.present) {
      map['nick_name'] = Variable<String>(nickName.value);
    }
    if (avatarSvgCompressed.present) {
      map['avatar_svg_compressed'] =
          Variable<Uint8List>(avatarSvgCompressed.value);
    }
    if (senderProfileCounter.present) {
      map['sender_profile_counter'] = Variable<int>(senderProfileCounter.value);
    }
    if (accepted.present) {
      map['accepted'] = Variable<bool>(accepted.value);
    }
    if (deletedByUser.present) {
      map['deleted_by_user'] = Variable<bool>(deletedByUser.value);
    }
    if (requested.present) {
      map['requested'] = Variable<bool>(requested.value);
    }
    if (blocked.present) {
      map['blocked'] = Variable<bool>(blocked.value);
    }
    if (verified.present) {
      map['verified'] = Variable<bool>(verified.value);
    }
    if (accountDeleted.present) {
      map['account_deleted'] = Variable<bool>(accountDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('nickName: $nickName, ')
          ..write('avatarSvgCompressed: $avatarSvgCompressed, ')
          ..write('senderProfileCounter: $senderProfileCounter, ')
          ..write('accepted: $accepted, ')
          ..write('deletedByUser: $deletedByUser, ')
          ..write('requested: $requested, ')
          ..write('blocked: $blocked, ')
          ..write('verified: $verified, ')
          ..write('accountDeleted: $accountDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isGroupAdminMeta =
      const VerificationMeta('isGroupAdmin');
  @override
  late final GeneratedColumn<bool> isGroupAdmin = GeneratedColumn<bool>(
      'is_group_admin', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_group_admin" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDirectChatMeta =
      const VerificationMeta('isDirectChat');
  @override
  late final GeneratedColumn<bool> isDirectChat = GeneratedColumn<bool>(
      'is_direct_chat', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_direct_chat" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _joinedGroupMeta =
      const VerificationMeta('joinedGroup');
  @override
  late final GeneratedColumn<bool> joinedGroup = GeneratedColumn<bool>(
      'joined_group', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("joined_group" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _leftGroupMeta =
      const VerificationMeta('leftGroup');
  @override
  late final GeneratedColumn<bool> leftGroup = GeneratedColumn<bool>(
      'left_group', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("left_group" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedContentMeta =
      const VerificationMeta('deletedContent');
  @override
  late final GeneratedColumn<bool> deletedContent = GeneratedColumn<bool>(
      'deleted_content', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("deleted_content" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _stateVersionIdMeta =
      const VerificationMeta('stateVersionId');
  @override
  late final GeneratedColumn<int> stateVersionId = GeneratedColumn<int>(
      'state_version_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _stateEncryptionKeyMeta =
      const VerificationMeta('stateEncryptionKey');
  @override
  late final GeneratedColumn<Uint8List> stateEncryptionKey =
      GeneratedColumn<Uint8List>('state_encryption_key', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _myGroupPrivateKeyMeta =
      const VerificationMeta('myGroupPrivateKey');
  @override
  late final GeneratedColumn<Uint8List> myGroupPrivateKey =
      GeneratedColumn<Uint8List>('my_group_private_key', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _groupNameMeta =
      const VerificationMeta('groupName');
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
      'group_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _draftMessageMeta =
      const VerificationMeta('draftMessage');
  @override
  late final GeneratedColumn<String> draftMessage = GeneratedColumn<String>(
      'draft_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalMediaCounterMeta =
      const VerificationMeta('totalMediaCounter');
  @override
  late final GeneratedColumn<int> totalMediaCounter = GeneratedColumn<int>(
      'total_media_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _alsoBestFriendMeta =
      const VerificationMeta('alsoBestFriend');
  @override
  late final GeneratedColumn<bool> alsoBestFriend = GeneratedColumn<bool>(
      'also_best_friend', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("also_best_friend" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deleteMessagesAfterMillisecondsMeta =
      const VerificationMeta('deleteMessagesAfterMilliseconds');
  @override
  late final GeneratedColumn<int> deleteMessagesAfterMilliseconds =
      GeneratedColumn<int>(
          'delete_messages_after_milliseconds', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(defaultDeleteMessagesAfterMilliseconds));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastMessageSendMeta =
      const VerificationMeta('lastMessageSend');
  @override
  late final GeneratedColumn<DateTime> lastMessageSend =
      GeneratedColumn<DateTime>('last_message_send', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageReceivedMeta =
      const VerificationMeta('lastMessageReceived');
  @override
  late final GeneratedColumn<DateTime> lastMessageReceived =
      GeneratedColumn<DateTime>('last_message_received', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastFlameCounterChangeMeta =
      const VerificationMeta('lastFlameCounterChange');
  @override
  late final GeneratedColumn<DateTime> lastFlameCounterChange =
      GeneratedColumn<DateTime>('last_flame_counter_change', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastFlameSyncMeta =
      const VerificationMeta('lastFlameSync');
  @override
  late final GeneratedColumn<DateTime> lastFlameSync =
      GeneratedColumn<DateTime>('last_flame_sync', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _flameCounterMeta =
      const VerificationMeta('flameCounter');
  @override
  late final GeneratedColumn<int> flameCounter = GeneratedColumn<int>(
      'flame_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _maxFlameCounterMeta =
      const VerificationMeta('maxFlameCounter');
  @override
  late final GeneratedColumn<int> maxFlameCounter = GeneratedColumn<int>(
      'max_flame_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _maxFlameCounterFromMeta =
      const VerificationMeta('maxFlameCounterFrom');
  @override
  late final GeneratedColumn<DateTime> maxFlameCounterFrom =
      GeneratedColumn<DateTime>('max_flame_counter_from', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageExchangeMeta =
      const VerificationMeta('lastMessageExchange');
  @override
  late final GeneratedColumn<DateTime> lastMessageExchange =
      GeneratedColumn<DateTime>('last_message_exchange', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        groupId,
        isGroupAdmin,
        isDirectChat,
        pinned,
        archived,
        joinedGroup,
        leftGroup,
        deletedContent,
        stateVersionId,
        stateEncryptionKey,
        myGroupPrivateKey,
        groupName,
        draftMessage,
        totalMediaCounter,
        alsoBestFriend,
        deleteMessagesAfterMilliseconds,
        createdAt,
        lastMessageSend,
        lastMessageReceived,
        lastFlameCounterChange,
        lastFlameSync,
        flameCounter,
        maxFlameCounter,
        maxFlameCounterFrom,
        lastMessageExchange
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(Insertable<Group> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('is_group_admin')) {
      context.handle(
          _isGroupAdminMeta,
          isGroupAdmin.isAcceptableOrUnknown(
              data['is_group_admin']!, _isGroupAdminMeta));
    }
    if (data.containsKey('is_direct_chat')) {
      context.handle(
          _isDirectChatMeta,
          isDirectChat.isAcceptableOrUnknown(
              data['is_direct_chat']!, _isDirectChatMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('joined_group')) {
      context.handle(
          _joinedGroupMeta,
          joinedGroup.isAcceptableOrUnknown(
              data['joined_group']!, _joinedGroupMeta));
    }
    if (data.containsKey('left_group')) {
      context.handle(_leftGroupMeta,
          leftGroup.isAcceptableOrUnknown(data['left_group']!, _leftGroupMeta));
    }
    if (data.containsKey('deleted_content')) {
      context.handle(
          _deletedContentMeta,
          deletedContent.isAcceptableOrUnknown(
              data['deleted_content']!, _deletedContentMeta));
    }
    if (data.containsKey('state_version_id')) {
      context.handle(
          _stateVersionIdMeta,
          stateVersionId.isAcceptableOrUnknown(
              data['state_version_id']!, _stateVersionIdMeta));
    }
    if (data.containsKey('state_encryption_key')) {
      context.handle(
          _stateEncryptionKeyMeta,
          stateEncryptionKey.isAcceptableOrUnknown(
              data['state_encryption_key']!, _stateEncryptionKeyMeta));
    }
    if (data.containsKey('my_group_private_key')) {
      context.handle(
          _myGroupPrivateKeyMeta,
          myGroupPrivateKey.isAcceptableOrUnknown(
              data['my_group_private_key']!, _myGroupPrivateKeyMeta));
    }
    if (data.containsKey('group_name')) {
      context.handle(_groupNameMeta,
          groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta));
    } else if (isInserting) {
      context.missing(_groupNameMeta);
    }
    if (data.containsKey('draft_message')) {
      context.handle(
          _draftMessageMeta,
          draftMessage.isAcceptableOrUnknown(
              data['draft_message']!, _draftMessageMeta));
    }
    if (data.containsKey('total_media_counter')) {
      context.handle(
          _totalMediaCounterMeta,
          totalMediaCounter.isAcceptableOrUnknown(
              data['total_media_counter']!, _totalMediaCounterMeta));
    }
    if (data.containsKey('also_best_friend')) {
      context.handle(
          _alsoBestFriendMeta,
          alsoBestFriend.isAcceptableOrUnknown(
              data['also_best_friend']!, _alsoBestFriendMeta));
    }
    if (data.containsKey('delete_messages_after_milliseconds')) {
      context.handle(
          _deleteMessagesAfterMillisecondsMeta,
          deleteMessagesAfterMilliseconds.isAcceptableOrUnknown(
              data['delete_messages_after_milliseconds']!,
              _deleteMessagesAfterMillisecondsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_message_send')) {
      context.handle(
          _lastMessageSendMeta,
          lastMessageSend.isAcceptableOrUnknown(
              data['last_message_send']!, _lastMessageSendMeta));
    }
    if (data.containsKey('last_message_received')) {
      context.handle(
          _lastMessageReceivedMeta,
          lastMessageReceived.isAcceptableOrUnknown(
              data['last_message_received']!, _lastMessageReceivedMeta));
    }
    if (data.containsKey('last_flame_counter_change')) {
      context.handle(
          _lastFlameCounterChangeMeta,
          lastFlameCounterChange.isAcceptableOrUnknown(
              data['last_flame_counter_change']!, _lastFlameCounterChangeMeta));
    }
    if (data.containsKey('last_flame_sync')) {
      context.handle(
          _lastFlameSyncMeta,
          lastFlameSync.isAcceptableOrUnknown(
              data['last_flame_sync']!, _lastFlameSyncMeta));
    }
    if (data.containsKey('flame_counter')) {
      context.handle(
          _flameCounterMeta,
          flameCounter.isAcceptableOrUnknown(
              data['flame_counter']!, _flameCounterMeta));
    }
    if (data.containsKey('max_flame_counter')) {
      context.handle(
          _maxFlameCounterMeta,
          maxFlameCounter.isAcceptableOrUnknown(
              data['max_flame_counter']!, _maxFlameCounterMeta));
    }
    if (data.containsKey('max_flame_counter_from')) {
      context.handle(
          _maxFlameCounterFromMeta,
          maxFlameCounterFrom.isAcceptableOrUnknown(
              data['max_flame_counter_from']!, _maxFlameCounterFromMeta));
    }
    if (data.containsKey('last_message_exchange')) {
      context.handle(
          _lastMessageExchangeMeta,
          lastMessageExchange.isAcceptableOrUnknown(
              data['last_message_exchange']!, _lastMessageExchangeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      isGroupAdmin: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_group_admin'])!,
      isDirectChat: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_direct_chat'])!,
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      joinedGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}joined_group'])!,
      leftGroup: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}left_group'])!,
      deletedContent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted_content'])!,
      stateVersionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state_version_id'])!,
      stateEncryptionKey: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}state_encryption_key']),
      myGroupPrivateKey: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}my_group_private_key']),
      groupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_name'])!,
      draftMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}draft_message']),
      totalMediaCounter: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_media_counter'])!,
      alsoBestFriend: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}also_best_friend'])!,
      deleteMessagesAfterMilliseconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}delete_messages_after_milliseconds'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastMessageSend: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_message_send']),
      lastMessageReceived: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_message_received']),
      lastFlameCounterChange: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_flame_counter_change']),
      lastFlameSync: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_flame_sync']),
      flameCounter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}flame_counter'])!,
      maxFlameCounter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_flame_counter'])!,
      maxFlameCounterFrom: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}max_flame_counter_from']),
      lastMessageExchange: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_message_exchange'])!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final String groupId;
  final bool isGroupAdmin;
  final bool isDirectChat;
  final bool pinned;
  final bool archived;
  final bool joinedGroup;
  final bool leftGroup;
  final bool deletedContent;
  final int stateVersionId;
  final Uint8List? stateEncryptionKey;
  final Uint8List? myGroupPrivateKey;
  final String groupName;
  final String? draftMessage;
  final int totalMediaCounter;
  final bool alsoBestFriend;
  final int deleteMessagesAfterMilliseconds;
  final DateTime createdAt;
  final DateTime? lastMessageSend;
  final DateTime? lastMessageReceived;
  final DateTime? lastFlameCounterChange;
  final DateTime? lastFlameSync;
  final int flameCounter;
  final int maxFlameCounter;
  final DateTime? maxFlameCounterFrom;
  final DateTime lastMessageExchange;
  const Group(
      {required this.groupId,
      required this.isGroupAdmin,
      required this.isDirectChat,
      required this.pinned,
      required this.archived,
      required this.joinedGroup,
      required this.leftGroup,
      required this.deletedContent,
      required this.stateVersionId,
      this.stateEncryptionKey,
      this.myGroupPrivateKey,
      required this.groupName,
      this.draftMessage,
      required this.totalMediaCounter,
      required this.alsoBestFriend,
      required this.deleteMessagesAfterMilliseconds,
      required this.createdAt,
      this.lastMessageSend,
      this.lastMessageReceived,
      this.lastFlameCounterChange,
      this.lastFlameSync,
      required this.flameCounter,
      required this.maxFlameCounter,
      this.maxFlameCounterFrom,
      required this.lastMessageExchange});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['is_group_admin'] = Variable<bool>(isGroupAdmin);
    map['is_direct_chat'] = Variable<bool>(isDirectChat);
    map['pinned'] = Variable<bool>(pinned);
    map['archived'] = Variable<bool>(archived);
    map['joined_group'] = Variable<bool>(joinedGroup);
    map['left_group'] = Variable<bool>(leftGroup);
    map['deleted_content'] = Variable<bool>(deletedContent);
    map['state_version_id'] = Variable<int>(stateVersionId);
    if (!nullToAbsent || stateEncryptionKey != null) {
      map['state_encryption_key'] = Variable<Uint8List>(stateEncryptionKey);
    }
    if (!nullToAbsent || myGroupPrivateKey != null) {
      map['my_group_private_key'] = Variable<Uint8List>(myGroupPrivateKey);
    }
    map['group_name'] = Variable<String>(groupName);
    if (!nullToAbsent || draftMessage != null) {
      map['draft_message'] = Variable<String>(draftMessage);
    }
    map['total_media_counter'] = Variable<int>(totalMediaCounter);
    map['also_best_friend'] = Variable<bool>(alsoBestFriend);
    map['delete_messages_after_milliseconds'] =
        Variable<int>(deleteMessagesAfterMilliseconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastMessageSend != null) {
      map['last_message_send'] = Variable<DateTime>(lastMessageSend);
    }
    if (!nullToAbsent || lastMessageReceived != null) {
      map['last_message_received'] = Variable<DateTime>(lastMessageReceived);
    }
    if (!nullToAbsent || lastFlameCounterChange != null) {
      map['last_flame_counter_change'] =
          Variable<DateTime>(lastFlameCounterChange);
    }
    if (!nullToAbsent || lastFlameSync != null) {
      map['last_flame_sync'] = Variable<DateTime>(lastFlameSync);
    }
    map['flame_counter'] = Variable<int>(flameCounter);
    map['max_flame_counter'] = Variable<int>(maxFlameCounter);
    if (!nullToAbsent || maxFlameCounterFrom != null) {
      map['max_flame_counter_from'] = Variable<DateTime>(maxFlameCounterFrom);
    }
    map['last_message_exchange'] = Variable<DateTime>(lastMessageExchange);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      groupId: Value(groupId),
      isGroupAdmin: Value(isGroupAdmin),
      isDirectChat: Value(isDirectChat),
      pinned: Value(pinned),
      archived: Value(archived),
      joinedGroup: Value(joinedGroup),
      leftGroup: Value(leftGroup),
      deletedContent: Value(deletedContent),
      stateVersionId: Value(stateVersionId),
      stateEncryptionKey: stateEncryptionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(stateEncryptionKey),
      myGroupPrivateKey: myGroupPrivateKey == null && nullToAbsent
          ? const Value.absent()
          : Value(myGroupPrivateKey),
      groupName: Value(groupName),
      draftMessage: draftMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(draftMessage),
      totalMediaCounter: Value(totalMediaCounter),
      alsoBestFriend: Value(alsoBestFriend),
      deleteMessagesAfterMilliseconds: Value(deleteMessagesAfterMilliseconds),
      createdAt: Value(createdAt),
      lastMessageSend: lastMessageSend == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSend),
      lastMessageReceived: lastMessageReceived == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageReceived),
      lastFlameCounterChange: lastFlameCounterChange == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFlameCounterChange),
      lastFlameSync: lastFlameSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFlameSync),
      flameCounter: Value(flameCounter),
      maxFlameCounter: Value(maxFlameCounter),
      maxFlameCounterFrom: maxFlameCounterFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(maxFlameCounterFrom),
      lastMessageExchange: Value(lastMessageExchange),
    );
  }

  factory Group.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      groupId: serializer.fromJson<String>(json['groupId']),
      isGroupAdmin: serializer.fromJson<bool>(json['isGroupAdmin']),
      isDirectChat: serializer.fromJson<bool>(json['isDirectChat']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      archived: serializer.fromJson<bool>(json['archived']),
      joinedGroup: serializer.fromJson<bool>(json['joinedGroup']),
      leftGroup: serializer.fromJson<bool>(json['leftGroup']),
      deletedContent: serializer.fromJson<bool>(json['deletedContent']),
      stateVersionId: serializer.fromJson<int>(json['stateVersionId']),
      stateEncryptionKey:
          serializer.fromJson<Uint8List?>(json['stateEncryptionKey']),
      myGroupPrivateKey:
          serializer.fromJson<Uint8List?>(json['myGroupPrivateKey']),
      groupName: serializer.fromJson<String>(json['groupName']),
      draftMessage: serializer.fromJson<String?>(json['draftMessage']),
      totalMediaCounter: serializer.fromJson<int>(json['totalMediaCounter']),
      alsoBestFriend: serializer.fromJson<bool>(json['alsoBestFriend']),
      deleteMessagesAfterMilliseconds:
          serializer.fromJson<int>(json['deleteMessagesAfterMilliseconds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastMessageSend: serializer.fromJson<DateTime?>(json['lastMessageSend']),
      lastMessageReceived:
          serializer.fromJson<DateTime?>(json['lastMessageReceived']),
      lastFlameCounterChange:
          serializer.fromJson<DateTime?>(json['lastFlameCounterChange']),
      lastFlameSync: serializer.fromJson<DateTime?>(json['lastFlameSync']),
      flameCounter: serializer.fromJson<int>(json['flameCounter']),
      maxFlameCounter: serializer.fromJson<int>(json['maxFlameCounter']),
      maxFlameCounterFrom:
          serializer.fromJson<DateTime?>(json['maxFlameCounterFrom']),
      lastMessageExchange:
          serializer.fromJson<DateTime>(json['lastMessageExchange']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'isGroupAdmin': serializer.toJson<bool>(isGroupAdmin),
      'isDirectChat': serializer.toJson<bool>(isDirectChat),
      'pinned': serializer.toJson<bool>(pinned),
      'archived': serializer.toJson<bool>(archived),
      'joinedGroup': serializer.toJson<bool>(joinedGroup),
      'leftGroup': serializer.toJson<bool>(leftGroup),
      'deletedContent': serializer.toJson<bool>(deletedContent),
      'stateVersionId': serializer.toJson<int>(stateVersionId),
      'stateEncryptionKey': serializer.toJson<Uint8List?>(stateEncryptionKey),
      'myGroupPrivateKey': serializer.toJson<Uint8List?>(myGroupPrivateKey),
      'groupName': serializer.toJson<String>(groupName),
      'draftMessage': serializer.toJson<String?>(draftMessage),
      'totalMediaCounter': serializer.toJson<int>(totalMediaCounter),
      'alsoBestFriend': serializer.toJson<bool>(alsoBestFriend),
      'deleteMessagesAfterMilliseconds':
          serializer.toJson<int>(deleteMessagesAfterMilliseconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastMessageSend': serializer.toJson<DateTime?>(lastMessageSend),
      'lastMessageReceived': serializer.toJson<DateTime?>(lastMessageReceived),
      'lastFlameCounterChange':
          serializer.toJson<DateTime?>(lastFlameCounterChange),
      'lastFlameSync': serializer.toJson<DateTime?>(lastFlameSync),
      'flameCounter': serializer.toJson<int>(flameCounter),
      'maxFlameCounter': serializer.toJson<int>(maxFlameCounter),
      'maxFlameCounterFrom': serializer.toJson<DateTime?>(maxFlameCounterFrom),
      'lastMessageExchange': serializer.toJson<DateTime>(lastMessageExchange),
    };
  }

  Group copyWith(
          {String? groupId,
          bool? isGroupAdmin,
          bool? isDirectChat,
          bool? pinned,
          bool? archived,
          bool? joinedGroup,
          bool? leftGroup,
          bool? deletedContent,
          int? stateVersionId,
          Value<Uint8List?> stateEncryptionKey = const Value.absent(),
          Value<Uint8List?> myGroupPrivateKey = const Value.absent(),
          String? groupName,
          Value<String?> draftMessage = const Value.absent(),
          int? totalMediaCounter,
          bool? alsoBestFriend,
          int? deleteMessagesAfterMilliseconds,
          DateTime? createdAt,
          Value<DateTime?> lastMessageSend = const Value.absent(),
          Value<DateTime?> lastMessageReceived = const Value.absent(),
          Value<DateTime?> lastFlameCounterChange = const Value.absent(),
          Value<DateTime?> lastFlameSync = const Value.absent(),
          int? flameCounter,
          int? maxFlameCounter,
          Value<DateTime?> maxFlameCounterFrom = const Value.absent(),
          DateTime? lastMessageExchange}) =>
      Group(
        groupId: groupId ?? this.groupId,
        isGroupAdmin: isGroupAdmin ?? this.isGroupAdmin,
        isDirectChat: isDirectChat ?? this.isDirectChat,
        pinned: pinned ?? this.pinned,
        archived: archived ?? this.archived,
        joinedGroup: joinedGroup ?? this.joinedGroup,
        leftGroup: leftGroup ?? this.leftGroup,
        deletedContent: deletedContent ?? this.deletedContent,
        stateVersionId: stateVersionId ?? this.stateVersionId,
        stateEncryptionKey: stateEncryptionKey.present
            ? stateEncryptionKey.value
            : this.stateEncryptionKey,
        myGroupPrivateKey: myGroupPrivateKey.present
            ? myGroupPrivateKey.value
            : this.myGroupPrivateKey,
        groupName: groupName ?? this.groupName,
        draftMessage:
            draftMessage.present ? draftMessage.value : this.draftMessage,
        totalMediaCounter: totalMediaCounter ?? this.totalMediaCounter,
        alsoBestFriend: alsoBestFriend ?? this.alsoBestFriend,
        deleteMessagesAfterMilliseconds: deleteMessagesAfterMilliseconds ??
            this.deleteMessagesAfterMilliseconds,
        createdAt: createdAt ?? this.createdAt,
        lastMessageSend: lastMessageSend.present
            ? lastMessageSend.value
            : this.lastMessageSend,
        lastMessageReceived: lastMessageReceived.present
            ? lastMessageReceived.value
            : this.lastMessageReceived,
        lastFlameCounterChange: lastFlameCounterChange.present
            ? lastFlameCounterChange.value
            : this.lastFlameCounterChange,
        lastFlameSync:
            lastFlameSync.present ? lastFlameSync.value : this.lastFlameSync,
        flameCounter: flameCounter ?? this.flameCounter,
        maxFlameCounter: maxFlameCounter ?? this.maxFlameCounter,
        maxFlameCounterFrom: maxFlameCounterFrom.present
            ? maxFlameCounterFrom.value
            : this.maxFlameCounterFrom,
        lastMessageExchange: lastMessageExchange ?? this.lastMessageExchange,
      );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      isGroupAdmin: data.isGroupAdmin.present
          ? data.isGroupAdmin.value
          : this.isGroupAdmin,
      isDirectChat: data.isDirectChat.present
          ? data.isDirectChat.value
          : this.isDirectChat,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      archived: data.archived.present ? data.archived.value : this.archived,
      joinedGroup:
          data.joinedGroup.present ? data.joinedGroup.value : this.joinedGroup,
      leftGroup: data.leftGroup.present ? data.leftGroup.value : this.leftGroup,
      deletedContent: data.deletedContent.present
          ? data.deletedContent.value
          : this.deletedContent,
      stateVersionId: data.stateVersionId.present
          ? data.stateVersionId.value
          : this.stateVersionId,
      stateEncryptionKey: data.stateEncryptionKey.present
          ? data.stateEncryptionKey.value
          : this.stateEncryptionKey,
      myGroupPrivateKey: data.myGroupPrivateKey.present
          ? data.myGroupPrivateKey.value
          : this.myGroupPrivateKey,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      draftMessage: data.draftMessage.present
          ? data.draftMessage.value
          : this.draftMessage,
      totalMediaCounter: data.totalMediaCounter.present
          ? data.totalMediaCounter.value
          : this.totalMediaCounter,
      alsoBestFriend: data.alsoBestFriend.present
          ? data.alsoBestFriend.value
          : this.alsoBestFriend,
      deleteMessagesAfterMilliseconds:
          data.deleteMessagesAfterMilliseconds.present
              ? data.deleteMessagesAfterMilliseconds.value
              : this.deleteMessagesAfterMilliseconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastMessageSend: data.lastMessageSend.present
          ? data.lastMessageSend.value
          : this.lastMessageSend,
      lastMessageReceived: data.lastMessageReceived.present
          ? data.lastMessageReceived.value
          : this.lastMessageReceived,
      lastFlameCounterChange: data.lastFlameCounterChange.present
          ? data.lastFlameCounterChange.value
          : this.lastFlameCounterChange,
      lastFlameSync: data.lastFlameSync.present
          ? data.lastFlameSync.value
          : this.lastFlameSync,
      flameCounter: data.flameCounter.present
          ? data.flameCounter.value
          : this.flameCounter,
      maxFlameCounter: data.maxFlameCounter.present
          ? data.maxFlameCounter.value
          : this.maxFlameCounter,
      maxFlameCounterFrom: data.maxFlameCounterFrom.present
          ? data.maxFlameCounterFrom.value
          : this.maxFlameCounterFrom,
      lastMessageExchange: data.lastMessageExchange.present
          ? data.lastMessageExchange.value
          : this.lastMessageExchange,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('groupId: $groupId, ')
          ..write('isGroupAdmin: $isGroupAdmin, ')
          ..write('isDirectChat: $isDirectChat, ')
          ..write('pinned: $pinned, ')
          ..write('archived: $archived, ')
          ..write('joinedGroup: $joinedGroup, ')
          ..write('leftGroup: $leftGroup, ')
          ..write('deletedContent: $deletedContent, ')
          ..write('stateVersionId: $stateVersionId, ')
          ..write('stateEncryptionKey: $stateEncryptionKey, ')
          ..write('myGroupPrivateKey: $myGroupPrivateKey, ')
          ..write('groupName: $groupName, ')
          ..write('draftMessage: $draftMessage, ')
          ..write('totalMediaCounter: $totalMediaCounter, ')
          ..write('alsoBestFriend: $alsoBestFriend, ')
          ..write(
              'deleteMessagesAfterMilliseconds: $deleteMessagesAfterMilliseconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMessageSend: $lastMessageSend, ')
          ..write('lastMessageReceived: $lastMessageReceived, ')
          ..write('lastFlameCounterChange: $lastFlameCounterChange, ')
          ..write('lastFlameSync: $lastFlameSync, ')
          ..write('flameCounter: $flameCounter, ')
          ..write('maxFlameCounter: $maxFlameCounter, ')
          ..write('maxFlameCounterFrom: $maxFlameCounterFrom, ')
          ..write('lastMessageExchange: $lastMessageExchange')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        groupId,
        isGroupAdmin,
        isDirectChat,
        pinned,
        archived,
        joinedGroup,
        leftGroup,
        deletedContent,
        stateVersionId,
        $driftBlobEquality.hash(stateEncryptionKey),
        $driftBlobEquality.hash(myGroupPrivateKey),
        groupName,
        draftMessage,
        totalMediaCounter,
        alsoBestFriend,
        deleteMessagesAfterMilliseconds,
        createdAt,
        lastMessageSend,
        lastMessageReceived,
        lastFlameCounterChange,
        lastFlameSync,
        flameCounter,
        maxFlameCounter,
        maxFlameCounterFrom,
        lastMessageExchange
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.groupId == this.groupId &&
          other.isGroupAdmin == this.isGroupAdmin &&
          other.isDirectChat == this.isDirectChat &&
          other.pinned == this.pinned &&
          other.archived == this.archived &&
          other.joinedGroup == this.joinedGroup &&
          other.leftGroup == this.leftGroup &&
          other.deletedContent == this.deletedContent &&
          other.stateVersionId == this.stateVersionId &&
          $driftBlobEquality.equals(
              other.stateEncryptionKey, this.stateEncryptionKey) &&
          $driftBlobEquality.equals(
              other.myGroupPrivateKey, this.myGroupPrivateKey) &&
          other.groupName == this.groupName &&
          other.draftMessage == this.draftMessage &&
          other.totalMediaCounter == this.totalMediaCounter &&
          other.alsoBestFriend == this.alsoBestFriend &&
          other.deleteMessagesAfterMilliseconds ==
              this.deleteMessagesAfterMilliseconds &&
          other.createdAt == this.createdAt &&
          other.lastMessageSend == this.lastMessageSend &&
          other.lastMessageReceived == this.lastMessageReceived &&
          other.lastFlameCounterChange == this.lastFlameCounterChange &&
          other.lastFlameSync == this.lastFlameSync &&
          other.flameCounter == this.flameCounter &&
          other.maxFlameCounter == this.maxFlameCounter &&
          other.maxFlameCounterFrom == this.maxFlameCounterFrom &&
          other.lastMessageExchange == this.lastMessageExchange);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<String> groupId;
  final Value<bool> isGroupAdmin;
  final Value<bool> isDirectChat;
  final Value<bool> pinned;
  final Value<bool> archived;
  final Value<bool> joinedGroup;
  final Value<bool> leftGroup;
  final Value<bool> deletedContent;
  final Value<int> stateVersionId;
  final Value<Uint8List?> stateEncryptionKey;
  final Value<Uint8List?> myGroupPrivateKey;
  final Value<String> groupName;
  final Value<String?> draftMessage;
  final Value<int> totalMediaCounter;
  final Value<bool> alsoBestFriend;
  final Value<int> deleteMessagesAfterMilliseconds;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastMessageSend;
  final Value<DateTime?> lastMessageReceived;
  final Value<DateTime?> lastFlameCounterChange;
  final Value<DateTime?> lastFlameSync;
  final Value<int> flameCounter;
  final Value<int> maxFlameCounter;
  final Value<DateTime?> maxFlameCounterFrom;
  final Value<DateTime> lastMessageExchange;
  final Value<int> rowid;
  const GroupsCompanion({
    this.groupId = const Value.absent(),
    this.isGroupAdmin = const Value.absent(),
    this.isDirectChat = const Value.absent(),
    this.pinned = const Value.absent(),
    this.archived = const Value.absent(),
    this.joinedGroup = const Value.absent(),
    this.leftGroup = const Value.absent(),
    this.deletedContent = const Value.absent(),
    this.stateVersionId = const Value.absent(),
    this.stateEncryptionKey = const Value.absent(),
    this.myGroupPrivateKey = const Value.absent(),
    this.groupName = const Value.absent(),
    this.draftMessage = const Value.absent(),
    this.totalMediaCounter = const Value.absent(),
    this.alsoBestFriend = const Value.absent(),
    this.deleteMessagesAfterMilliseconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastMessageSend = const Value.absent(),
    this.lastMessageReceived = const Value.absent(),
    this.lastFlameCounterChange = const Value.absent(),
    this.lastFlameSync = const Value.absent(),
    this.flameCounter = const Value.absent(),
    this.maxFlameCounter = const Value.absent(),
    this.maxFlameCounterFrom = const Value.absent(),
    this.lastMessageExchange = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String groupId,
    this.isGroupAdmin = const Value.absent(),
    this.isDirectChat = const Value.absent(),
    this.pinned = const Value.absent(),
    this.archived = const Value.absent(),
    this.joinedGroup = const Value.absent(),
    this.leftGroup = const Value.absent(),
    this.deletedContent = const Value.absent(),
    this.stateVersionId = const Value.absent(),
    this.stateEncryptionKey = const Value.absent(),
    this.myGroupPrivateKey = const Value.absent(),
    required String groupName,
    this.draftMessage = const Value.absent(),
    this.totalMediaCounter = const Value.absent(),
    this.alsoBestFriend = const Value.absent(),
    this.deleteMessagesAfterMilliseconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastMessageSend = const Value.absent(),
    this.lastMessageReceived = const Value.absent(),
    this.lastFlameCounterChange = const Value.absent(),
    this.lastFlameSync = const Value.absent(),
    this.flameCounter = const Value.absent(),
    this.maxFlameCounter = const Value.absent(),
    this.maxFlameCounterFrom = const Value.absent(),
    this.lastMessageExchange = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : groupId = Value(groupId),
        groupName = Value(groupName);
  static Insertable<Group> custom({
    Expression<String>? groupId,
    Expression<bool>? isGroupAdmin,
    Expression<bool>? isDirectChat,
    Expression<bool>? pinned,
    Expression<bool>? archived,
    Expression<bool>? joinedGroup,
    Expression<bool>? leftGroup,
    Expression<bool>? deletedContent,
    Expression<int>? stateVersionId,
    Expression<Uint8List>? stateEncryptionKey,
    Expression<Uint8List>? myGroupPrivateKey,
    Expression<String>? groupName,
    Expression<String>? draftMessage,
    Expression<int>? totalMediaCounter,
    Expression<bool>? alsoBestFriend,
    Expression<int>? deleteMessagesAfterMilliseconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastMessageSend,
    Expression<DateTime>? lastMessageReceived,
    Expression<DateTime>? lastFlameCounterChange,
    Expression<DateTime>? lastFlameSync,
    Expression<int>? flameCounter,
    Expression<int>? maxFlameCounter,
    Expression<DateTime>? maxFlameCounterFrom,
    Expression<DateTime>? lastMessageExchange,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (isGroupAdmin != null) 'is_group_admin': isGroupAdmin,
      if (isDirectChat != null) 'is_direct_chat': isDirectChat,
      if (pinned != null) 'pinned': pinned,
      if (archived != null) 'archived': archived,
      if (joinedGroup != null) 'joined_group': joinedGroup,
      if (leftGroup != null) 'left_group': leftGroup,
      if (deletedContent != null) 'deleted_content': deletedContent,
      if (stateVersionId != null) 'state_version_id': stateVersionId,
      if (stateEncryptionKey != null)
        'state_encryption_key': stateEncryptionKey,
      if (myGroupPrivateKey != null) 'my_group_private_key': myGroupPrivateKey,
      if (groupName != null) 'group_name': groupName,
      if (draftMessage != null) 'draft_message': draftMessage,
      if (totalMediaCounter != null) 'total_media_counter': totalMediaCounter,
      if (alsoBestFriend != null) 'also_best_friend': alsoBestFriend,
      if (deleteMessagesAfterMilliseconds != null)
        'delete_messages_after_milliseconds': deleteMessagesAfterMilliseconds,
      if (createdAt != null) 'created_at': createdAt,
      if (lastMessageSend != null) 'last_message_send': lastMessageSend,
      if (lastMessageReceived != null)
        'last_message_received': lastMessageReceived,
      if (lastFlameCounterChange != null)
        'last_flame_counter_change': lastFlameCounterChange,
      if (lastFlameSync != null) 'last_flame_sync': lastFlameSync,
      if (flameCounter != null) 'flame_counter': flameCounter,
      if (maxFlameCounter != null) 'max_flame_counter': maxFlameCounter,
      if (maxFlameCounterFrom != null)
        'max_flame_counter_from': maxFlameCounterFrom,
      if (lastMessageExchange != null)
        'last_message_exchange': lastMessageExchange,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith(
      {Value<String>? groupId,
      Value<bool>? isGroupAdmin,
      Value<bool>? isDirectChat,
      Value<bool>? pinned,
      Value<bool>? archived,
      Value<bool>? joinedGroup,
      Value<bool>? leftGroup,
      Value<bool>? deletedContent,
      Value<int>? stateVersionId,
      Value<Uint8List?>? stateEncryptionKey,
      Value<Uint8List?>? myGroupPrivateKey,
      Value<String>? groupName,
      Value<String?>? draftMessage,
      Value<int>? totalMediaCounter,
      Value<bool>? alsoBestFriend,
      Value<int>? deleteMessagesAfterMilliseconds,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastMessageSend,
      Value<DateTime?>? lastMessageReceived,
      Value<DateTime?>? lastFlameCounterChange,
      Value<DateTime?>? lastFlameSync,
      Value<int>? flameCounter,
      Value<int>? maxFlameCounter,
      Value<DateTime?>? maxFlameCounterFrom,
      Value<DateTime>? lastMessageExchange,
      Value<int>? rowid}) {
    return GroupsCompanion(
      groupId: groupId ?? this.groupId,
      isGroupAdmin: isGroupAdmin ?? this.isGroupAdmin,
      isDirectChat: isDirectChat ?? this.isDirectChat,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      joinedGroup: joinedGroup ?? this.joinedGroup,
      leftGroup: leftGroup ?? this.leftGroup,
      deletedContent: deletedContent ?? this.deletedContent,
      stateVersionId: stateVersionId ?? this.stateVersionId,
      stateEncryptionKey: stateEncryptionKey ?? this.stateEncryptionKey,
      myGroupPrivateKey: myGroupPrivateKey ?? this.myGroupPrivateKey,
      groupName: groupName ?? this.groupName,
      draftMessage: draftMessage ?? this.draftMessage,
      totalMediaCounter: totalMediaCounter ?? this.totalMediaCounter,
      alsoBestFriend: alsoBestFriend ?? this.alsoBestFriend,
      deleteMessagesAfterMilliseconds: deleteMessagesAfterMilliseconds ??
          this.deleteMessagesAfterMilliseconds,
      createdAt: createdAt ?? this.createdAt,
      lastMessageSend: lastMessageSend ?? this.lastMessageSend,
      lastMessageReceived: lastMessageReceived ?? this.lastMessageReceived,
      lastFlameCounterChange:
          lastFlameCounterChange ?? this.lastFlameCounterChange,
      lastFlameSync: lastFlameSync ?? this.lastFlameSync,
      flameCounter: flameCounter ?? this.flameCounter,
      maxFlameCounter: maxFlameCounter ?? this.maxFlameCounter,
      maxFlameCounterFrom: maxFlameCounterFrom ?? this.maxFlameCounterFrom,
      lastMessageExchange: lastMessageExchange ?? this.lastMessageExchange,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (isGroupAdmin.present) {
      map['is_group_admin'] = Variable<bool>(isGroupAdmin.value);
    }
    if (isDirectChat.present) {
      map['is_direct_chat'] = Variable<bool>(isDirectChat.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (joinedGroup.present) {
      map['joined_group'] = Variable<bool>(joinedGroup.value);
    }
    if (leftGroup.present) {
      map['left_group'] = Variable<bool>(leftGroup.value);
    }
    if (deletedContent.present) {
      map['deleted_content'] = Variable<bool>(deletedContent.value);
    }
    if (stateVersionId.present) {
      map['state_version_id'] = Variable<int>(stateVersionId.value);
    }
    if (stateEncryptionKey.present) {
      map['state_encryption_key'] =
          Variable<Uint8List>(stateEncryptionKey.value);
    }
    if (myGroupPrivateKey.present) {
      map['my_group_private_key'] =
          Variable<Uint8List>(myGroupPrivateKey.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (draftMessage.present) {
      map['draft_message'] = Variable<String>(draftMessage.value);
    }
    if (totalMediaCounter.present) {
      map['total_media_counter'] = Variable<int>(totalMediaCounter.value);
    }
    if (alsoBestFriend.present) {
      map['also_best_friend'] = Variable<bool>(alsoBestFriend.value);
    }
    if (deleteMessagesAfterMilliseconds.present) {
      map['delete_messages_after_milliseconds'] =
          Variable<int>(deleteMessagesAfterMilliseconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastMessageSend.present) {
      map['last_message_send'] = Variable<DateTime>(lastMessageSend.value);
    }
    if (lastMessageReceived.present) {
      map['last_message_received'] =
          Variable<DateTime>(lastMessageReceived.value);
    }
    if (lastFlameCounterChange.present) {
      map['last_flame_counter_change'] =
          Variable<DateTime>(lastFlameCounterChange.value);
    }
    if (lastFlameSync.present) {
      map['last_flame_sync'] = Variable<DateTime>(lastFlameSync.value);
    }
    if (flameCounter.present) {
      map['flame_counter'] = Variable<int>(flameCounter.value);
    }
    if (maxFlameCounter.present) {
      map['max_flame_counter'] = Variable<int>(maxFlameCounter.value);
    }
    if (maxFlameCounterFrom.present) {
      map['max_flame_counter_from'] =
          Variable<DateTime>(maxFlameCounterFrom.value);
    }
    if (lastMessageExchange.present) {
      map['last_message_exchange'] =
          Variable<DateTime>(lastMessageExchange.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('isGroupAdmin: $isGroupAdmin, ')
          ..write('isDirectChat: $isDirectChat, ')
          ..write('pinned: $pinned, ')
          ..write('archived: $archived, ')
          ..write('joinedGroup: $joinedGroup, ')
          ..write('leftGroup: $leftGroup, ')
          ..write('deletedContent: $deletedContent, ')
          ..write('stateVersionId: $stateVersionId, ')
          ..write('stateEncryptionKey: $stateEncryptionKey, ')
          ..write('myGroupPrivateKey: $myGroupPrivateKey, ')
          ..write('groupName: $groupName, ')
          ..write('draftMessage: $draftMessage, ')
          ..write('totalMediaCounter: $totalMediaCounter, ')
          ..write('alsoBestFriend: $alsoBestFriend, ')
          ..write(
              'deleteMessagesAfterMilliseconds: $deleteMessagesAfterMilliseconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMessageSend: $lastMessageSend, ')
          ..write('lastMessageReceived: $lastMessageReceived, ')
          ..write('lastFlameCounterChange: $lastFlameCounterChange, ')
          ..write('lastFlameSync: $lastFlameSync, ')
          ..write('flameCounter: $flameCounter, ')
          ..write('maxFlameCounter: $maxFlameCounter, ')
          ..write('maxFlameCounterFrom: $maxFlameCounterFrom, ')
          ..write('lastMessageExchange: $lastMessageExchange, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaFilesTable extends MediaFiles
    with TableInfo<$MediaFilesTable, MediaFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MediaType>($MediaFilesTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<UploadState?, String>
      uploadState = GeneratedColumn<String>('upload_state', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<UploadState?>($MediaFilesTable.$converteruploadStaten);
  @override
  late final GeneratedColumnWithTypeConverter<DownloadState?, String>
      downloadState = GeneratedColumn<String>(
              'download_state', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<DownloadState?>(
              $MediaFilesTable.$converterdownloadStaten);
  static const VerificationMeta _requiresAuthenticationMeta =
      const VerificationMeta('requiresAuthentication');
  @override
  late final GeneratedColumn<bool> requiresAuthentication =
      GeneratedColumn<bool>('requires_authentication', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("requires_authentication" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _storedMeta = const VerificationMeta('stored');
  @override
  late final GeneratedColumn<bool> stored = GeneratedColumn<bool>(
      'stored', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("stored" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDraftMediaMeta =
      const VerificationMeta('isDraftMedia');
  @override
  late final GeneratedColumn<bool> isDraftMedia = GeneratedColumn<bool>(
      'is_draft_media', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_draft_media" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  late final GeneratedColumnWithTypeConverter<List<int>?, String>
      reuploadRequestedBy = GeneratedColumn<String>(
              'reupload_requested_by', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<int>?>(
              $MediaFilesTable.$converterreuploadRequestedByn);
  static const VerificationMeta _displayLimitInMillisecondsMeta =
      const VerificationMeta('displayLimitInMilliseconds');
  @override
  late final GeneratedColumn<int> displayLimitInMilliseconds =
      GeneratedColumn<int>('display_limit_in_milliseconds', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _removeAudioMeta =
      const VerificationMeta('removeAudio');
  @override
  late final GeneratedColumn<bool> removeAudio = GeneratedColumn<bool>(
      'remove_audio', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("remove_audio" IN (0, 1))'));
  static const VerificationMeta _downloadTokenMeta =
      const VerificationMeta('downloadToken');
  @override
  late final GeneratedColumn<Uint8List> downloadToken =
      GeneratedColumn<Uint8List>('download_token', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _encryptionKeyMeta =
      const VerificationMeta('encryptionKey');
  @override
  late final GeneratedColumn<Uint8List> encryptionKey =
      GeneratedColumn<Uint8List>('encryption_key', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _encryptionMacMeta =
      const VerificationMeta('encryptionMac');
  @override
  late final GeneratedColumn<Uint8List> encryptionMac =
      GeneratedColumn<Uint8List>('encryption_mac', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _encryptionNonceMeta =
      const VerificationMeta('encryptionNonce');
  @override
  late final GeneratedColumn<Uint8List> encryptionNonce =
      GeneratedColumn<Uint8List>('encryption_nonce', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _storedFileHashMeta =
      const VerificationMeta('storedFileHash');
  @override
  late final GeneratedColumn<Uint8List> storedFileHash =
      GeneratedColumn<Uint8List>('stored_file_hash', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        mediaId,
        type,
        uploadState,
        downloadState,
        requiresAuthentication,
        stored,
        isDraftMedia,
        reuploadRequestedBy,
        displayLimitInMilliseconds,
        removeAudio,
        downloadToken,
        encryptionKey,
        encryptionMac,
        encryptionNonce,
        storedFileHash,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_files';
  @override
  VerificationContext validateIntegrity(Insertable<MediaFile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('requires_authentication')) {
      context.handle(
          _requiresAuthenticationMeta,
          requiresAuthentication.isAcceptableOrUnknown(
              data['requires_authentication']!, _requiresAuthenticationMeta));
    }
    if (data.containsKey('stored')) {
      context.handle(_storedMeta,
          stored.isAcceptableOrUnknown(data['stored']!, _storedMeta));
    }
    if (data.containsKey('is_draft_media')) {
      context.handle(
          _isDraftMediaMeta,
          isDraftMedia.isAcceptableOrUnknown(
              data['is_draft_media']!, _isDraftMediaMeta));
    }
    if (data.containsKey('display_limit_in_milliseconds')) {
      context.handle(
          _displayLimitInMillisecondsMeta,
          displayLimitInMilliseconds.isAcceptableOrUnknown(
              data['display_limit_in_milliseconds']!,
              _displayLimitInMillisecondsMeta));
    }
    if (data.containsKey('remove_audio')) {
      context.handle(
          _removeAudioMeta,
          removeAudio.isAcceptableOrUnknown(
              data['remove_audio']!, _removeAudioMeta));
    }
    if (data.containsKey('download_token')) {
      context.handle(
          _downloadTokenMeta,
          downloadToken.isAcceptableOrUnknown(
              data['download_token']!, _downloadTokenMeta));
    }
    if (data.containsKey('encryption_key')) {
      context.handle(
          _encryptionKeyMeta,
          encryptionKey.isAcceptableOrUnknown(
              data['encryption_key']!, _encryptionKeyMeta));
    }
    if (data.containsKey('encryption_mac')) {
      context.handle(
          _encryptionMacMeta,
          encryptionMac.isAcceptableOrUnknown(
              data['encryption_mac']!, _encryptionMacMeta));
    }
    if (data.containsKey('encryption_nonce')) {
      context.handle(
          _encryptionNonceMeta,
          encryptionNonce.isAcceptableOrUnknown(
              data['encryption_nonce']!, _encryptionNonceMeta));
    }
    if (data.containsKey('stored_file_hash')) {
      context.handle(
          _storedFileHashMeta,
          storedFileHash.isAcceptableOrUnknown(
              data['stored_file_hash']!, _storedFileHashMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  MediaFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaFile(
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      type: $MediaFilesTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      uploadState: $MediaFilesTable.$converteruploadStaten.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}upload_state'])),
      downloadState: $MediaFilesTable.$converterdownloadStaten.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}download_state'])),
      requiresAuthentication: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}requires_authentication'])!,
      stored: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}stored'])!,
      isDraftMedia: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_draft_media'])!,
      reuploadRequestedBy: $MediaFilesTable.$converterreuploadRequestedByn
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}reupload_requested_by'])),
      displayLimitInMilliseconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}display_limit_in_milliseconds']),
      removeAudio: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}remove_audio']),
      downloadToken: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}download_token']),
      encryptionKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}encryption_key']),
      encryptionMac: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}encryption_mac']),
      encryptionNonce: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}encryption_nonce']),
      storedFileHash: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}stored_file_hash']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MediaFilesTable createAlias(String alias) {
    return $MediaFilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertertype =
      const EnumNameConverter<MediaType>(MediaType.values);
  static JsonTypeConverter2<UploadState, String, String> $converteruploadState =
      const EnumNameConverter<UploadState>(UploadState.values);
  static JsonTypeConverter2<UploadState?, String?, String?>
      $converteruploadStaten =
      JsonTypeConverter2.asNullable($converteruploadState);
  static JsonTypeConverter2<DownloadState, String, String>
      $converterdownloadState =
      const EnumNameConverter<DownloadState>(DownloadState.values);
  static JsonTypeConverter2<DownloadState?, String?, String?>
      $converterdownloadStaten =
      JsonTypeConverter2.asNullable($converterdownloadState);
  static TypeConverter<List<int>, String> $converterreuploadRequestedBy =
      IntListTypeConverter();
  static TypeConverter<List<int>?, String?> $converterreuploadRequestedByn =
      NullAwareTypeConverter.wrap($converterreuploadRequestedBy);
}

class MediaFile extends DataClass implements Insertable<MediaFile> {
  final String mediaId;
  final MediaType type;
  final UploadState? uploadState;
  final DownloadState? downloadState;
  final bool requiresAuthentication;
  final bool stored;
  final bool isDraftMedia;
  final List<int>? reuploadRequestedBy;
  final int? displayLimitInMilliseconds;
  final bool? removeAudio;
  final Uint8List? downloadToken;
  final Uint8List? encryptionKey;
  final Uint8List? encryptionMac;
  final Uint8List? encryptionNonce;
  final Uint8List? storedFileHash;
  final DateTime createdAt;
  const MediaFile(
      {required this.mediaId,
      required this.type,
      this.uploadState,
      this.downloadState,
      required this.requiresAuthentication,
      required this.stored,
      required this.isDraftMedia,
      this.reuploadRequestedBy,
      this.displayLimitInMilliseconds,
      this.removeAudio,
      this.downloadToken,
      this.encryptionKey,
      this.encryptionMac,
      this.encryptionNonce,
      this.storedFileHash,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<String>(mediaId);
    {
      map['type'] =
          Variable<String>($MediaFilesTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || uploadState != null) {
      map['upload_state'] = Variable<String>(
          $MediaFilesTable.$converteruploadStaten.toSql(uploadState));
    }
    if (!nullToAbsent || downloadState != null) {
      map['download_state'] = Variable<String>(
          $MediaFilesTable.$converterdownloadStaten.toSql(downloadState));
    }
    map['requires_authentication'] = Variable<bool>(requiresAuthentication);
    map['stored'] = Variable<bool>(stored);
    map['is_draft_media'] = Variable<bool>(isDraftMedia);
    if (!nullToAbsent || reuploadRequestedBy != null) {
      map['reupload_requested_by'] = Variable<String>($MediaFilesTable
          .$converterreuploadRequestedByn
          .toSql(reuploadRequestedBy));
    }
    if (!nullToAbsent || displayLimitInMilliseconds != null) {
      map['display_limit_in_milliseconds'] =
          Variable<int>(displayLimitInMilliseconds);
    }
    if (!nullToAbsent || removeAudio != null) {
      map['remove_audio'] = Variable<bool>(removeAudio);
    }
    if (!nullToAbsent || downloadToken != null) {
      map['download_token'] = Variable<Uint8List>(downloadToken);
    }
    if (!nullToAbsent || encryptionKey != null) {
      map['encryption_key'] = Variable<Uint8List>(encryptionKey);
    }
    if (!nullToAbsent || encryptionMac != null) {
      map['encryption_mac'] = Variable<Uint8List>(encryptionMac);
    }
    if (!nullToAbsent || encryptionNonce != null) {
      map['encryption_nonce'] = Variable<Uint8List>(encryptionNonce);
    }
    if (!nullToAbsent || storedFileHash != null) {
      map['stored_file_hash'] = Variable<Uint8List>(storedFileHash);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MediaFilesCompanion toCompanion(bool nullToAbsent) {
    return MediaFilesCompanion(
      mediaId: Value(mediaId),
      type: Value(type),
      uploadState: uploadState == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadState),
      downloadState: downloadState == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadState),
      requiresAuthentication: Value(requiresAuthentication),
      stored: Value(stored),
      isDraftMedia: Value(isDraftMedia),
      reuploadRequestedBy: reuploadRequestedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reuploadRequestedBy),
      displayLimitInMilliseconds:
          displayLimitInMilliseconds == null && nullToAbsent
              ? const Value.absent()
              : Value(displayLimitInMilliseconds),
      removeAudio: removeAudio == null && nullToAbsent
          ? const Value.absent()
          : Value(removeAudio),
      downloadToken: downloadToken == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadToken),
      encryptionKey: encryptionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptionKey),
      encryptionMac: encryptionMac == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptionMac),
      encryptionNonce: encryptionNonce == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptionNonce),
      storedFileHash: storedFileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(storedFileHash),
      createdAt: Value(createdAt),
    );
  }

  factory MediaFile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaFile(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      type: $MediaFilesTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      uploadState: $MediaFilesTable.$converteruploadStaten
          .fromJson(serializer.fromJson<String?>(json['uploadState'])),
      downloadState: $MediaFilesTable.$converterdownloadStaten
          .fromJson(serializer.fromJson<String?>(json['downloadState'])),
      requiresAuthentication:
          serializer.fromJson<bool>(json['requiresAuthentication']),
      stored: serializer.fromJson<bool>(json['stored']),
      isDraftMedia: serializer.fromJson<bool>(json['isDraftMedia']),
      reuploadRequestedBy:
          serializer.fromJson<List<int>?>(json['reuploadRequestedBy']),
      displayLimitInMilliseconds:
          serializer.fromJson<int?>(json['displayLimitInMilliseconds']),
      removeAudio: serializer.fromJson<bool?>(json['removeAudio']),
      downloadToken: serializer.fromJson<Uint8List?>(json['downloadToken']),
      encryptionKey: serializer.fromJson<Uint8List?>(json['encryptionKey']),
      encryptionMac: serializer.fromJson<Uint8List?>(json['encryptionMac']),
      encryptionNonce: serializer.fromJson<Uint8List?>(json['encryptionNonce']),
      storedFileHash: serializer.fromJson<Uint8List?>(json['storedFileHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'type': serializer
          .toJson<String>($MediaFilesTable.$convertertype.toJson(type)),
      'uploadState': serializer.toJson<String?>(
          $MediaFilesTable.$converteruploadStaten.toJson(uploadState)),
      'downloadState': serializer.toJson<String?>(
          $MediaFilesTable.$converterdownloadStaten.toJson(downloadState)),
      'requiresAuthentication': serializer.toJson<bool>(requiresAuthentication),
      'stored': serializer.toJson<bool>(stored),
      'isDraftMedia': serializer.toJson<bool>(isDraftMedia),
      'reuploadRequestedBy': serializer.toJson<List<int>?>(reuploadRequestedBy),
      'displayLimitInMilliseconds':
          serializer.toJson<int?>(displayLimitInMilliseconds),
      'removeAudio': serializer.toJson<bool?>(removeAudio),
      'downloadToken': serializer.toJson<Uint8List?>(downloadToken),
      'encryptionKey': serializer.toJson<Uint8List?>(encryptionKey),
      'encryptionMac': serializer.toJson<Uint8List?>(encryptionMac),
      'encryptionNonce': serializer.toJson<Uint8List?>(encryptionNonce),
      'storedFileHash': serializer.toJson<Uint8List?>(storedFileHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MediaFile copyWith(
          {String? mediaId,
          MediaType? type,
          Value<UploadState?> uploadState = const Value.absent(),
          Value<DownloadState?> downloadState = const Value.absent(),
          bool? requiresAuthentication,
          bool? stored,
          bool? isDraftMedia,
          Value<List<int>?> reuploadRequestedBy = const Value.absent(),
          Value<int?> displayLimitInMilliseconds = const Value.absent(),
          Value<bool?> removeAudio = const Value.absent(),
          Value<Uint8List?> downloadToken = const Value.absent(),
          Value<Uint8List?> encryptionKey = const Value.absent(),
          Value<Uint8List?> encryptionMac = const Value.absent(),
          Value<Uint8List?> encryptionNonce = const Value.absent(),
          Value<Uint8List?> storedFileHash = const Value.absent(),
          DateTime? createdAt}) =>
      MediaFile(
        mediaId: mediaId ?? this.mediaId,
        type: type ?? this.type,
        uploadState: uploadState.present ? uploadState.value : this.uploadState,
        downloadState:
            downloadState.present ? downloadState.value : this.downloadState,
        requiresAuthentication:
            requiresAuthentication ?? this.requiresAuthentication,
        stored: stored ?? this.stored,
        isDraftMedia: isDraftMedia ?? this.isDraftMedia,
        reuploadRequestedBy: reuploadRequestedBy.present
            ? reuploadRequestedBy.value
            : this.reuploadRequestedBy,
        displayLimitInMilliseconds: displayLimitInMilliseconds.present
            ? displayLimitInMilliseconds.value
            : this.displayLimitInMilliseconds,
        removeAudio: removeAudio.present ? removeAudio.value : this.removeAudio,
        downloadToken:
            downloadToken.present ? downloadToken.value : this.downloadToken,
        encryptionKey:
            encryptionKey.present ? encryptionKey.value : this.encryptionKey,
        encryptionMac:
            encryptionMac.present ? encryptionMac.value : this.encryptionMac,
        encryptionNonce: encryptionNonce.present
            ? encryptionNonce.value
            : this.encryptionNonce,
        storedFileHash:
            storedFileHash.present ? storedFileHash.value : this.storedFileHash,
        createdAt: createdAt ?? this.createdAt,
      );
  MediaFile copyWithCompanion(MediaFilesCompanion data) {
    return MediaFile(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      type: data.type.present ? data.type.value : this.type,
      uploadState:
          data.uploadState.present ? data.uploadState.value : this.uploadState,
      downloadState: data.downloadState.present
          ? data.downloadState.value
          : this.downloadState,
      requiresAuthentication: data.requiresAuthentication.present
          ? data.requiresAuthentication.value
          : this.requiresAuthentication,
      stored: data.stored.present ? data.stored.value : this.stored,
      isDraftMedia: data.isDraftMedia.present
          ? data.isDraftMedia.value
          : this.isDraftMedia,
      reuploadRequestedBy: data.reuploadRequestedBy.present
          ? data.reuploadRequestedBy.value
          : this.reuploadRequestedBy,
      displayLimitInMilliseconds: data.displayLimitInMilliseconds.present
          ? data.displayLimitInMilliseconds.value
          : this.displayLimitInMilliseconds,
      removeAudio:
          data.removeAudio.present ? data.removeAudio.value : this.removeAudio,
      downloadToken: data.downloadToken.present
          ? data.downloadToken.value
          : this.downloadToken,
      encryptionKey: data.encryptionKey.present
          ? data.encryptionKey.value
          : this.encryptionKey,
      encryptionMac: data.encryptionMac.present
          ? data.encryptionMac.value
          : this.encryptionMac,
      encryptionNonce: data.encryptionNonce.present
          ? data.encryptionNonce.value
          : this.encryptionNonce,
      storedFileHash: data.storedFileHash.present
          ? data.storedFileHash.value
          : this.storedFileHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaFile(')
          ..write('mediaId: $mediaId, ')
          ..write('type: $type, ')
          ..write('uploadState: $uploadState, ')
          ..write('downloadState: $downloadState, ')
          ..write('requiresAuthentication: $requiresAuthentication, ')
          ..write('stored: $stored, ')
          ..write('isDraftMedia: $isDraftMedia, ')
          ..write('reuploadRequestedBy: $reuploadRequestedBy, ')
          ..write('displayLimitInMilliseconds: $displayLimitInMilliseconds, ')
          ..write('removeAudio: $removeAudio, ')
          ..write('downloadToken: $downloadToken, ')
          ..write('encryptionKey: $encryptionKey, ')
          ..write('encryptionMac: $encryptionMac, ')
          ..write('encryptionNonce: $encryptionNonce, ')
          ..write('storedFileHash: $storedFileHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      mediaId,
      type,
      uploadState,
      downloadState,
      requiresAuthentication,
      stored,
      isDraftMedia,
      reuploadRequestedBy,
      displayLimitInMilliseconds,
      removeAudio,
      $driftBlobEquality.hash(downloadToken),
      $driftBlobEquality.hash(encryptionKey),
      $driftBlobEquality.hash(encryptionMac),
      $driftBlobEquality.hash(encryptionNonce),
      $driftBlobEquality.hash(storedFileHash),
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaFile &&
          other.mediaId == this.mediaId &&
          other.type == this.type &&
          other.uploadState == this.uploadState &&
          other.downloadState == this.downloadState &&
          other.requiresAuthentication == this.requiresAuthentication &&
          other.stored == this.stored &&
          other.isDraftMedia == this.isDraftMedia &&
          other.reuploadRequestedBy == this.reuploadRequestedBy &&
          other.displayLimitInMilliseconds == this.displayLimitInMilliseconds &&
          other.removeAudio == this.removeAudio &&
          $driftBlobEquality.equals(other.downloadToken, this.downloadToken) &&
          $driftBlobEquality.equals(other.encryptionKey, this.encryptionKey) &&
          $driftBlobEquality.equals(other.encryptionMac, this.encryptionMac) &&
          $driftBlobEquality.equals(
              other.encryptionNonce, this.encryptionNonce) &&
          $driftBlobEquality.equals(
              other.storedFileHash, this.storedFileHash) &&
          other.createdAt == this.createdAt);
}

class MediaFilesCompanion extends UpdateCompanion<MediaFile> {
  final Value<String> mediaId;
  final Value<MediaType> type;
  final Value<UploadState?> uploadState;
  final Value<DownloadState?> downloadState;
  final Value<bool> requiresAuthentication;
  final Value<bool> stored;
  final Value<bool> isDraftMedia;
  final Value<List<int>?> reuploadRequestedBy;
  final Value<int?> displayLimitInMilliseconds;
  final Value<bool?> removeAudio;
  final Value<Uint8List?> downloadToken;
  final Value<Uint8List?> encryptionKey;
  final Value<Uint8List?> encryptionMac;
  final Value<Uint8List?> encryptionNonce;
  final Value<Uint8List?> storedFileHash;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MediaFilesCompanion({
    this.mediaId = const Value.absent(),
    this.type = const Value.absent(),
    this.uploadState = const Value.absent(),
    this.downloadState = const Value.absent(),
    this.requiresAuthentication = const Value.absent(),
    this.stored = const Value.absent(),
    this.isDraftMedia = const Value.absent(),
    this.reuploadRequestedBy = const Value.absent(),
    this.displayLimitInMilliseconds = const Value.absent(),
    this.removeAudio = const Value.absent(),
    this.downloadToken = const Value.absent(),
    this.encryptionKey = const Value.absent(),
    this.encryptionMac = const Value.absent(),
    this.encryptionNonce = const Value.absent(),
    this.storedFileHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaFilesCompanion.insert({
    required String mediaId,
    required MediaType type,
    this.uploadState = const Value.absent(),
    this.downloadState = const Value.absent(),
    this.requiresAuthentication = const Value.absent(),
    this.stored = const Value.absent(),
    this.isDraftMedia = const Value.absent(),
    this.reuploadRequestedBy = const Value.absent(),
    this.displayLimitInMilliseconds = const Value.absent(),
    this.removeAudio = const Value.absent(),
    this.downloadToken = const Value.absent(),
    this.encryptionKey = const Value.absent(),
    this.encryptionMac = const Value.absent(),
    this.encryptionNonce = const Value.absent(),
    this.storedFileHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : mediaId = Value(mediaId),
        type = Value(type);
  static Insertable<MediaFile> custom({
    Expression<String>? mediaId,
    Expression<String>? type,
    Expression<String>? uploadState,
    Expression<String>? downloadState,
    Expression<bool>? requiresAuthentication,
    Expression<bool>? stored,
    Expression<bool>? isDraftMedia,
    Expression<String>? reuploadRequestedBy,
    Expression<int>? displayLimitInMilliseconds,
    Expression<bool>? removeAudio,
    Expression<Uint8List>? downloadToken,
    Expression<Uint8List>? encryptionKey,
    Expression<Uint8List>? encryptionMac,
    Expression<Uint8List>? encryptionNonce,
    Expression<Uint8List>? storedFileHash,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (type != null) 'type': type,
      if (uploadState != null) 'upload_state': uploadState,
      if (downloadState != null) 'download_state': downloadState,
      if (requiresAuthentication != null)
        'requires_authentication': requiresAuthentication,
      if (stored != null) 'stored': stored,
      if (isDraftMedia != null) 'is_draft_media': isDraftMedia,
      if (reuploadRequestedBy != null)
        'reupload_requested_by': reuploadRequestedBy,
      if (displayLimitInMilliseconds != null)
        'display_limit_in_milliseconds': displayLimitInMilliseconds,
      if (removeAudio != null) 'remove_audio': removeAudio,
      if (downloadToken != null) 'download_token': downloadToken,
      if (encryptionKey != null) 'encryption_key': encryptionKey,
      if (encryptionMac != null) 'encryption_mac': encryptionMac,
      if (encryptionNonce != null) 'encryption_nonce': encryptionNonce,
      if (storedFileHash != null) 'stored_file_hash': storedFileHash,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaFilesCompanion copyWith(
      {Value<String>? mediaId,
      Value<MediaType>? type,
      Value<UploadState?>? uploadState,
      Value<DownloadState?>? downloadState,
      Value<bool>? requiresAuthentication,
      Value<bool>? stored,
      Value<bool>? isDraftMedia,
      Value<List<int>?>? reuploadRequestedBy,
      Value<int?>? displayLimitInMilliseconds,
      Value<bool?>? removeAudio,
      Value<Uint8List?>? downloadToken,
      Value<Uint8List?>? encryptionKey,
      Value<Uint8List?>? encryptionMac,
      Value<Uint8List?>? encryptionNonce,
      Value<Uint8List?>? storedFileHash,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return MediaFilesCompanion(
      mediaId: mediaId ?? this.mediaId,
      type: type ?? this.type,
      uploadState: uploadState ?? this.uploadState,
      downloadState: downloadState ?? this.downloadState,
      requiresAuthentication:
          requiresAuthentication ?? this.requiresAuthentication,
      stored: stored ?? this.stored,
      isDraftMedia: isDraftMedia ?? this.isDraftMedia,
      reuploadRequestedBy: reuploadRequestedBy ?? this.reuploadRequestedBy,
      displayLimitInMilliseconds:
          displayLimitInMilliseconds ?? this.displayLimitInMilliseconds,
      removeAudio: removeAudio ?? this.removeAudio,
      downloadToken: downloadToken ?? this.downloadToken,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      encryptionMac: encryptionMac ?? this.encryptionMac,
      encryptionNonce: encryptionNonce ?? this.encryptionNonce,
      storedFileHash: storedFileHash ?? this.storedFileHash,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($MediaFilesTable.$convertertype.toSql(type.value));
    }
    if (uploadState.present) {
      map['upload_state'] = Variable<String>(
          $MediaFilesTable.$converteruploadStaten.toSql(uploadState.value));
    }
    if (downloadState.present) {
      map['download_state'] = Variable<String>(
          $MediaFilesTable.$converterdownloadStaten.toSql(downloadState.value));
    }
    if (requiresAuthentication.present) {
      map['requires_authentication'] =
          Variable<bool>(requiresAuthentication.value);
    }
    if (stored.present) {
      map['stored'] = Variable<bool>(stored.value);
    }
    if (isDraftMedia.present) {
      map['is_draft_media'] = Variable<bool>(isDraftMedia.value);
    }
    if (reuploadRequestedBy.present) {
      map['reupload_requested_by'] = Variable<String>($MediaFilesTable
          .$converterreuploadRequestedByn
          .toSql(reuploadRequestedBy.value));
    }
    if (displayLimitInMilliseconds.present) {
      map['display_limit_in_milliseconds'] =
          Variable<int>(displayLimitInMilliseconds.value);
    }
    if (removeAudio.present) {
      map['remove_audio'] = Variable<bool>(removeAudio.value);
    }
    if (downloadToken.present) {
      map['download_token'] = Variable<Uint8List>(downloadToken.value);
    }
    if (encryptionKey.present) {
      map['encryption_key'] = Variable<Uint8List>(encryptionKey.value);
    }
    if (encryptionMac.present) {
      map['encryption_mac'] = Variable<Uint8List>(encryptionMac.value);
    }
    if (encryptionNonce.present) {
      map['encryption_nonce'] = Variable<Uint8List>(encryptionNonce.value);
    }
    if (storedFileHash.present) {
      map['stored_file_hash'] = Variable<Uint8List>(storedFileHash.value);
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
    return (StringBuffer('MediaFilesCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('type: $type, ')
          ..write('uploadState: $uploadState, ')
          ..write('downloadState: $downloadState, ')
          ..write('requiresAuthentication: $requiresAuthentication, ')
          ..write('stored: $stored, ')
          ..write('isDraftMedia: $isDraftMedia, ')
          ..write('reuploadRequestedBy: $reuploadRequestedBy, ')
          ..write('displayLimitInMilliseconds: $displayLimitInMilliseconds, ')
          ..write('removeAudio: $removeAudio, ')
          ..write('downloadToken: $downloadToken, ')
          ..write('encryptionKey: $encryptionKey, ')
          ..write('encryptionMac: $encryptionMac, ')
          ..write('encryptionNonce: $encryptionNonce, ')
          ..write('storedFileHash: $storedFileHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES "groups" (group_id) ON DELETE CASCADE'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
      'sender_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (user_id)'));
  @override
  late final GeneratedColumnWithTypeConverter<MessageType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MessageType>($MessagesTable.$convertertype);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaIdMeta =
      const VerificationMeta('mediaId');
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES media_files (media_id) ON DELETE SET NULL'));
  static const VerificationMeta _additionalMessageDataMeta =
      const VerificationMeta('additionalMessageData');
  @override
  late final GeneratedColumn<Uint8List> additionalMessageData =
      GeneratedColumn<Uint8List>('additional_message_data', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _mediaStoredMeta =
      const VerificationMeta('mediaStored');
  @override
  late final GeneratedColumn<bool> mediaStored = GeneratedColumn<bool>(
      'media_stored', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("media_stored" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _mediaReopenedMeta =
      const VerificationMeta('mediaReopened');
  @override
  late final GeneratedColumn<bool> mediaReopened = GeneratedColumn<bool>(
      'media_reopened', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("media_reopened" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _downloadTokenMeta =
      const VerificationMeta('downloadToken');
  @override
  late final GeneratedColumn<Uint8List> downloadToken =
      GeneratedColumn<Uint8List>('download_token', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _quotesMessageIdMeta =
      const VerificationMeta('quotesMessageId');
  @override
  late final GeneratedColumn<String> quotesMessageId = GeneratedColumn<String>(
      'quotes_message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedFromSenderMeta =
      const VerificationMeta('isDeletedFromSender');
  @override
  late final GeneratedColumn<bool> isDeletedFromSender = GeneratedColumn<bool>(
      'is_deleted_from_sender', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_deleted_from_sender" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _openedByAllMeta =
      const VerificationMeta('openedByAll');
  @override
  late final GeneratedColumn<DateTime> openedByAll = GeneratedColumn<DateTime>(
      'opened_by_all', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _ackByUserMeta =
      const VerificationMeta('ackByUser');
  @override
  late final GeneratedColumn<DateTime> ackByUser = GeneratedColumn<DateTime>(
      'ack_by_user', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _ackByServerMeta =
      const VerificationMeta('ackByServer');
  @override
  late final GeneratedColumn<DateTime> ackByServer = GeneratedColumn<DateTime>(
      'ack_by_server', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        groupId,
        messageId,
        senderId,
        type,
        content,
        mediaId,
        additionalMessageData,
        mediaStored,
        mediaReopened,
        downloadToken,
        quotesMessageId,
        isDeletedFromSender,
        openedAt,
        openedByAll,
        createdAt,
        modifiedAt,
        ackByUser,
        ackByServer
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('media_id')) {
      context.handle(_mediaIdMeta,
          mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta));
    }
    if (data.containsKey('additional_message_data')) {
      context.handle(
          _additionalMessageDataMeta,
          additionalMessageData.isAcceptableOrUnknown(
              data['additional_message_data']!, _additionalMessageDataMeta));
    }
    if (data.containsKey('media_stored')) {
      context.handle(
          _mediaStoredMeta,
          mediaStored.isAcceptableOrUnknown(
              data['media_stored']!, _mediaStoredMeta));
    }
    if (data.containsKey('media_reopened')) {
      context.handle(
          _mediaReopenedMeta,
          mediaReopened.isAcceptableOrUnknown(
              data['media_reopened']!, _mediaReopenedMeta));
    }
    if (data.containsKey('download_token')) {
      context.handle(
          _downloadTokenMeta,
          downloadToken.isAcceptableOrUnknown(
              data['download_token']!, _downloadTokenMeta));
    }
    if (data.containsKey('quotes_message_id')) {
      context.handle(
          _quotesMessageIdMeta,
          quotesMessageId.isAcceptableOrUnknown(
              data['quotes_message_id']!, _quotesMessageIdMeta));
    }
    if (data.containsKey('is_deleted_from_sender')) {
      context.handle(
          _isDeletedFromSenderMeta,
          isDeletedFromSender.isAcceptableOrUnknown(
              data['is_deleted_from_sender']!, _isDeletedFromSenderMeta));
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    }
    if (data.containsKey('opened_by_all')) {
      context.handle(
          _openedByAllMeta,
          openedByAll.isAcceptableOrUnknown(
              data['opened_by_all']!, _openedByAllMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    }
    if (data.containsKey('ack_by_user')) {
      context.handle(
          _ackByUserMeta,
          ackByUser.isAcceptableOrUnknown(
              data['ack_by_user']!, _ackByUserMeta));
    }
    if (data.containsKey('ack_by_server')) {
      context.handle(
          _ackByServerMeta,
          ackByServer.isAcceptableOrUnknown(
              data['ack_by_server']!, _ackByServerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sender_id']),
      type: $MessagesTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id']),
      additionalMessageData: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}additional_message_data']),
      mediaStored: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}media_stored'])!,
      mediaReopened: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}media_reopened'])!,
      downloadToken: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}download_token']),
      quotesMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}quotes_message_id']),
      isDeletedFromSender: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_deleted_from_sender'])!,
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_at']),
      openedByAll: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_by_all']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at']),
      ackByUser: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ack_by_user']),
      ackByServer: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ack_by_server']),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MessageType, String, String> $convertertype =
      const EnumNameConverter<MessageType>(MessageType.values);
}

class Message extends DataClass implements Insertable<Message> {
  final String groupId;
  final String messageId;
  final int? senderId;
  final MessageType type;
  final String? content;
  final String? mediaId;
  final Uint8List? additionalMessageData;
  final bool mediaStored;
  final bool mediaReopened;
  final Uint8List? downloadToken;
  final String? quotesMessageId;
  final bool isDeletedFromSender;
  final DateTime? openedAt;
  final DateTime? openedByAll;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final DateTime? ackByUser;
  final DateTime? ackByServer;
  const Message(
      {required this.groupId,
      required this.messageId,
      this.senderId,
      required this.type,
      this.content,
      this.mediaId,
      this.additionalMessageData,
      required this.mediaStored,
      required this.mediaReopened,
      this.downloadToken,
      this.quotesMessageId,
      required this.isDeletedFromSender,
      this.openedAt,
      this.openedByAll,
      required this.createdAt,
      this.modifiedAt,
      this.ackByUser,
      this.ackByServer});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<int>(senderId);
    }
    {
      map['type'] = Variable<String>($MessagesTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || mediaId != null) {
      map['media_id'] = Variable<String>(mediaId);
    }
    if (!nullToAbsent || additionalMessageData != null) {
      map['additional_message_data'] =
          Variable<Uint8List>(additionalMessageData);
    }
    map['media_stored'] = Variable<bool>(mediaStored);
    map['media_reopened'] = Variable<bool>(mediaReopened);
    if (!nullToAbsent || downloadToken != null) {
      map['download_token'] = Variable<Uint8List>(downloadToken);
    }
    if (!nullToAbsent || quotesMessageId != null) {
      map['quotes_message_id'] = Variable<String>(quotesMessageId);
    }
    map['is_deleted_from_sender'] = Variable<bool>(isDeletedFromSender);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    if (!nullToAbsent || openedByAll != null) {
      map['opened_by_all'] = Variable<DateTime>(openedByAll);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<DateTime>(modifiedAt);
    }
    if (!nullToAbsent || ackByUser != null) {
      map['ack_by_user'] = Variable<DateTime>(ackByUser);
    }
    if (!nullToAbsent || ackByServer != null) {
      map['ack_by_server'] = Variable<DateTime>(ackByServer);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      groupId: Value(groupId),
      messageId: Value(messageId),
      senderId: senderId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderId),
      type: Value(type),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      mediaId: mediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaId),
      additionalMessageData: additionalMessageData == null && nullToAbsent
          ? const Value.absent()
          : Value(additionalMessageData),
      mediaStored: Value(mediaStored),
      mediaReopened: Value(mediaReopened),
      downloadToken: downloadToken == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadToken),
      quotesMessageId: quotesMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(quotesMessageId),
      isDeletedFromSender: Value(isDeletedFromSender),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      openedByAll: openedByAll == null && nullToAbsent
          ? const Value.absent()
          : Value(openedByAll),
      createdAt: Value(createdAt),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      ackByUser: ackByUser == null && nullToAbsent
          ? const Value.absent()
          : Value(ackByUser),
      ackByServer: ackByServer == null && nullToAbsent
          ? const Value.absent()
          : Value(ackByServer),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      groupId: serializer.fromJson<String>(json['groupId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      senderId: serializer.fromJson<int?>(json['senderId']),
      type: $MessagesTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      content: serializer.fromJson<String?>(json['content']),
      mediaId: serializer.fromJson<String?>(json['mediaId']),
      additionalMessageData:
          serializer.fromJson<Uint8List?>(json['additionalMessageData']),
      mediaStored: serializer.fromJson<bool>(json['mediaStored']),
      mediaReopened: serializer.fromJson<bool>(json['mediaReopened']),
      downloadToken: serializer.fromJson<Uint8List?>(json['downloadToken']),
      quotesMessageId: serializer.fromJson<String?>(json['quotesMessageId']),
      isDeletedFromSender:
          serializer.fromJson<bool>(json['isDeletedFromSender']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      openedByAll: serializer.fromJson<DateTime?>(json['openedByAll']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      ackByUser: serializer.fromJson<DateTime?>(json['ackByUser']),
      ackByServer: serializer.fromJson<DateTime?>(json['ackByServer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'messageId': serializer.toJson<String>(messageId),
      'senderId': serializer.toJson<int?>(senderId),
      'type':
          serializer.toJson<String>($MessagesTable.$convertertype.toJson(type)),
      'content': serializer.toJson<String?>(content),
      'mediaId': serializer.toJson<String?>(mediaId),
      'additionalMessageData':
          serializer.toJson<Uint8List?>(additionalMessageData),
      'mediaStored': serializer.toJson<bool>(mediaStored),
      'mediaReopened': serializer.toJson<bool>(mediaReopened),
      'downloadToken': serializer.toJson<Uint8List?>(downloadToken),
      'quotesMessageId': serializer.toJson<String?>(quotesMessageId),
      'isDeletedFromSender': serializer.toJson<bool>(isDeletedFromSender),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'openedByAll': serializer.toJson<DateTime?>(openedByAll),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime?>(modifiedAt),
      'ackByUser': serializer.toJson<DateTime?>(ackByUser),
      'ackByServer': serializer.toJson<DateTime?>(ackByServer),
    };
  }

  Message copyWith(
          {String? groupId,
          String? messageId,
          Value<int?> senderId = const Value.absent(),
          MessageType? type,
          Value<String?> content = const Value.absent(),
          Value<String?> mediaId = const Value.absent(),
          Value<Uint8List?> additionalMessageData = const Value.absent(),
          bool? mediaStored,
          bool? mediaReopened,
          Value<Uint8List?> downloadToken = const Value.absent(),
          Value<String?> quotesMessageId = const Value.absent(),
          bool? isDeletedFromSender,
          Value<DateTime?> openedAt = const Value.absent(),
          Value<DateTime?> openedByAll = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> modifiedAt = const Value.absent(),
          Value<DateTime?> ackByUser = const Value.absent(),
          Value<DateTime?> ackByServer = const Value.absent()}) =>
      Message(
        groupId: groupId ?? this.groupId,
        messageId: messageId ?? this.messageId,
        senderId: senderId.present ? senderId.value : this.senderId,
        type: type ?? this.type,
        content: content.present ? content.value : this.content,
        mediaId: mediaId.present ? mediaId.value : this.mediaId,
        additionalMessageData: additionalMessageData.present
            ? additionalMessageData.value
            : this.additionalMessageData,
        mediaStored: mediaStored ?? this.mediaStored,
        mediaReopened: mediaReopened ?? this.mediaReopened,
        downloadToken:
            downloadToken.present ? downloadToken.value : this.downloadToken,
        quotesMessageId: quotesMessageId.present
            ? quotesMessageId.value
            : this.quotesMessageId,
        isDeletedFromSender: isDeletedFromSender ?? this.isDeletedFromSender,
        openedAt: openedAt.present ? openedAt.value : this.openedAt,
        openedByAll: openedByAll.present ? openedByAll.value : this.openedByAll,
        createdAt: createdAt ?? this.createdAt,
        modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
        ackByUser: ackByUser.present ? ackByUser.value : this.ackByUser,
        ackByServer: ackByServer.present ? ackByServer.value : this.ackByServer,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      additionalMessageData: data.additionalMessageData.present
          ? data.additionalMessageData.value
          : this.additionalMessageData,
      mediaStored:
          data.mediaStored.present ? data.mediaStored.value : this.mediaStored,
      mediaReopened: data.mediaReopened.present
          ? data.mediaReopened.value
          : this.mediaReopened,
      downloadToken: data.downloadToken.present
          ? data.downloadToken.value
          : this.downloadToken,
      quotesMessageId: data.quotesMessageId.present
          ? data.quotesMessageId.value
          : this.quotesMessageId,
      isDeletedFromSender: data.isDeletedFromSender.present
          ? data.isDeletedFromSender.value
          : this.isDeletedFromSender,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      openedByAll:
          data.openedByAll.present ? data.openedByAll.value : this.openedByAll,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      ackByUser: data.ackByUser.present ? data.ackByUser.value : this.ackByUser,
      ackByServer:
          data.ackByServer.present ? data.ackByServer.value : this.ackByServer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('groupId: $groupId, ')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('mediaId: $mediaId, ')
          ..write('additionalMessageData: $additionalMessageData, ')
          ..write('mediaStored: $mediaStored, ')
          ..write('mediaReopened: $mediaReopened, ')
          ..write('downloadToken: $downloadToken, ')
          ..write('quotesMessageId: $quotesMessageId, ')
          ..write('isDeletedFromSender: $isDeletedFromSender, ')
          ..write('openedAt: $openedAt, ')
          ..write('openedByAll: $openedByAll, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('ackByUser: $ackByUser, ')
          ..write('ackByServer: $ackByServer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      groupId,
      messageId,
      senderId,
      type,
      content,
      mediaId,
      $driftBlobEquality.hash(additionalMessageData),
      mediaStored,
      mediaReopened,
      $driftBlobEquality.hash(downloadToken),
      quotesMessageId,
      isDeletedFromSender,
      openedAt,
      openedByAll,
      createdAt,
      modifiedAt,
      ackByUser,
      ackByServer);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.groupId == this.groupId &&
          other.messageId == this.messageId &&
          other.senderId == this.senderId &&
          other.type == this.type &&
          other.content == this.content &&
          other.mediaId == this.mediaId &&
          $driftBlobEquality.equals(
              other.additionalMessageData, this.additionalMessageData) &&
          other.mediaStored == this.mediaStored &&
          other.mediaReopened == this.mediaReopened &&
          $driftBlobEquality.equals(other.downloadToken, this.downloadToken) &&
          other.quotesMessageId == this.quotesMessageId &&
          other.isDeletedFromSender == this.isDeletedFromSender &&
          other.openedAt == this.openedAt &&
          other.openedByAll == this.openedByAll &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.ackByUser == this.ackByUser &&
          other.ackByServer == this.ackByServer);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> groupId;
  final Value<String> messageId;
  final Value<int?> senderId;
  final Value<MessageType> type;
  final Value<String?> content;
  final Value<String?> mediaId;
  final Value<Uint8List?> additionalMessageData;
  final Value<bool> mediaStored;
  final Value<bool> mediaReopened;
  final Value<Uint8List?> downloadToken;
  final Value<String?> quotesMessageId;
  final Value<bool> isDeletedFromSender;
  final Value<DateTime?> openedAt;
  final Value<DateTime?> openedByAll;
  final Value<DateTime> createdAt;
  final Value<DateTime?> modifiedAt;
  final Value<DateTime?> ackByUser;
  final Value<DateTime?> ackByServer;
  final Value<int> rowid;
  const MessagesCompanion({
    this.groupId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.additionalMessageData = const Value.absent(),
    this.mediaStored = const Value.absent(),
    this.mediaReopened = const Value.absent(),
    this.downloadToken = const Value.absent(),
    this.quotesMessageId = const Value.absent(),
    this.isDeletedFromSender = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openedByAll = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.ackByUser = const Value.absent(),
    this.ackByServer = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String groupId,
    required String messageId,
    this.senderId = const Value.absent(),
    required MessageType type,
    this.content = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.additionalMessageData = const Value.absent(),
    this.mediaStored = const Value.absent(),
    this.mediaReopened = const Value.absent(),
    this.downloadToken = const Value.absent(),
    this.quotesMessageId = const Value.absent(),
    this.isDeletedFromSender = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.openedByAll = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.ackByUser = const Value.absent(),
    this.ackByServer = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : groupId = Value(groupId),
        messageId = Value(messageId),
        type = Value(type);
  static Insertable<Message> custom({
    Expression<String>? groupId,
    Expression<String>? messageId,
    Expression<int>? senderId,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? mediaId,
    Expression<Uint8List>? additionalMessageData,
    Expression<bool>? mediaStored,
    Expression<bool>? mediaReopened,
    Expression<Uint8List>? downloadToken,
    Expression<String>? quotesMessageId,
    Expression<bool>? isDeletedFromSender,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? openedByAll,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? ackByUser,
    Expression<DateTime>? ackByServer,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (messageId != null) 'message_id': messageId,
      if (senderId != null) 'sender_id': senderId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (mediaId != null) 'media_id': mediaId,
      if (additionalMessageData != null)
        'additional_message_data': additionalMessageData,
      if (mediaStored != null) 'media_stored': mediaStored,
      if (mediaReopened != null) 'media_reopened': mediaReopened,
      if (downloadToken != null) 'download_token': downloadToken,
      if (quotesMessageId != null) 'quotes_message_id': quotesMessageId,
      if (isDeletedFromSender != null)
        'is_deleted_from_sender': isDeletedFromSender,
      if (openedAt != null) 'opened_at': openedAt,
      if (openedByAll != null) 'opened_by_all': openedByAll,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (ackByUser != null) 'ack_by_user': ackByUser,
      if (ackByServer != null) 'ack_by_server': ackByServer,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith(
      {Value<String>? groupId,
      Value<String>? messageId,
      Value<int?>? senderId,
      Value<MessageType>? type,
      Value<String?>? content,
      Value<String?>? mediaId,
      Value<Uint8List?>? additionalMessageData,
      Value<bool>? mediaStored,
      Value<bool>? mediaReopened,
      Value<Uint8List?>? downloadToken,
      Value<String?>? quotesMessageId,
      Value<bool>? isDeletedFromSender,
      Value<DateTime?>? openedAt,
      Value<DateTime?>? openedByAll,
      Value<DateTime>? createdAt,
      Value<DateTime?>? modifiedAt,
      Value<DateTime?>? ackByUser,
      Value<DateTime?>? ackByServer,
      Value<int>? rowid}) {
    return MessagesCompanion(
      groupId: groupId ?? this.groupId,
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaId: mediaId ?? this.mediaId,
      additionalMessageData:
          additionalMessageData ?? this.additionalMessageData,
      mediaStored: mediaStored ?? this.mediaStored,
      mediaReopened: mediaReopened ?? this.mediaReopened,
      downloadToken: downloadToken ?? this.downloadToken,
      quotesMessageId: quotesMessageId ?? this.quotesMessageId,
      isDeletedFromSender: isDeletedFromSender ?? this.isDeletedFromSender,
      openedAt: openedAt ?? this.openedAt,
      openedByAll: openedByAll ?? this.openedByAll,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      ackByUser: ackByUser ?? this.ackByUser,
      ackByServer: ackByServer ?? this.ackByServer,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<int>(senderId.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($MessagesTable.$convertertype.toSql(type.value));
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (additionalMessageData.present) {
      map['additional_message_data'] =
          Variable<Uint8List>(additionalMessageData.value);
    }
    if (mediaStored.present) {
      map['media_stored'] = Variable<bool>(mediaStored.value);
    }
    if (mediaReopened.present) {
      map['media_reopened'] = Variable<bool>(mediaReopened.value);
    }
    if (downloadToken.present) {
      map['download_token'] = Variable<Uint8List>(downloadToken.value);
    }
    if (quotesMessageId.present) {
      map['quotes_message_id'] = Variable<String>(quotesMessageId.value);
    }
    if (isDeletedFromSender.present) {
      map['is_deleted_from_sender'] = Variable<bool>(isDeletedFromSender.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (openedByAll.present) {
      map['opened_by_all'] = Variable<DateTime>(openedByAll.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (ackByUser.present) {
      map['ack_by_user'] = Variable<DateTime>(ackByUser.value);
    }
    if (ackByServer.present) {
      map['ack_by_server'] = Variable<DateTime>(ackByServer.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('groupId: $groupId, ')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('mediaId: $mediaId, ')
          ..write('additionalMessageData: $additionalMessageData, ')
          ..write('mediaStored: $mediaStored, ')
          ..write('mediaReopened: $mediaReopened, ')
          ..write('downloadToken: $downloadToken, ')
          ..write('quotesMessageId: $quotesMessageId, ')
          ..write('isDeletedFromSender: $isDeletedFromSender, ')
          ..write('openedAt: $openedAt, ')
          ..write('openedByAll: $openedByAll, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('ackByUser: $ackByUser, ')
          ..write('ackByServer: $ackByServer, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessageHistoriesTable extends MessageHistories
    with TableInfo<$MessageHistoriesTable, MessageHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES messages (message_id) ON DELETE CASCADE'));
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, messageId, contactId, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_histories';
  @override
  VerificationContext validateIntegrity(Insertable<MessageHistory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageHistory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MessageHistoriesTable createAlias(String alias) {
    return $MessageHistoriesTable(attachedDatabase, alias);
  }
}

class MessageHistory extends DataClass implements Insertable<MessageHistory> {
  final int id;
  final String messageId;
  final int? contactId;
  final String? content;
  final DateTime createdAt;
  const MessageHistory(
      {required this.id,
      required this.messageId,
      this.contactId,
      this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<int>(contactId);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessageHistoriesCompanion toCompanion(bool nullToAbsent) {
    return MessageHistoriesCompanion(
      id: Value(id),
      messageId: Value(messageId),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory MessageHistory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageHistory(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      contactId: serializer.fromJson<int?>(json['contactId']),
      content: serializer.fromJson<String?>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'contactId': serializer.toJson<int?>(contactId),
      'content': serializer.toJson<String?>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessageHistory copyWith(
          {int? id,
          String? messageId,
          Value<int?> contactId = const Value.absent(),
          Value<String?> content = const Value.absent(),
          DateTime? createdAt}) =>
      MessageHistory(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        contactId: contactId.present ? contactId.value : this.contactId,
        content: content.present ? content.value : this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  MessageHistory copyWithCompanion(MessageHistoriesCompanion data) {
    return MessageHistory(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageHistory(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('contactId: $contactId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, messageId, contactId, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageHistory &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.contactId == this.contactId &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class MessageHistoriesCompanion extends UpdateCompanion<MessageHistory> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<int?> contactId;
  final Value<String?> content;
  final Value<DateTime> createdAt;
  const MessageHistoriesCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MessageHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    this.contactId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : messageId = Value(messageId);
  static Insertable<MessageHistory> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<int>? contactId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (contactId != null) 'contact_id': contactId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MessageHistoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? messageId,
      Value<int?>? contactId,
      Value<String?>? content,
      Value<DateTime>? createdAt}) {
    return MessageHistoriesCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      contactId: contactId ?? this.contactId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('contactId: $contactId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReactionsTable extends Reactions
    with TableInfo<$ReactionsTable, Reaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES messages (message_id) ON DELETE CASCADE'));
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderIdMeta =
      const VerificationMeta('senderId');
  @override
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
      'sender_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [messageId, emoji, senderId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  VerificationContext validateIntegrity(Insertable<Reaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(_senderIdMeta,
          senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, senderId, emoji};
  @override
  Reaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reaction(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sender_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ReactionsTable createAlias(String alias) {
    return $ReactionsTable(attachedDatabase, alias);
  }
}

class Reaction extends DataClass implements Insertable<Reaction> {
  final String messageId;
  final String emoji;
  final int? senderId;
  final DateTime createdAt;
  const Reaction(
      {required this.messageId,
      required this.emoji,
      this.senderId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['emoji'] = Variable<String>(emoji);
    if (!nullToAbsent || senderId != null) {
      map['sender_id'] = Variable<int>(senderId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReactionsCompanion toCompanion(bool nullToAbsent) {
    return ReactionsCompanion(
      messageId: Value(messageId),
      emoji: Value(emoji),
      senderId: senderId == null && nullToAbsent
          ? const Value.absent()
          : Value(senderId),
      createdAt: Value(createdAt),
    );
  }

  factory Reaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reaction(
      messageId: serializer.fromJson<String>(json['messageId']),
      emoji: serializer.fromJson<String>(json['emoji']),
      senderId: serializer.fromJson<int?>(json['senderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'emoji': serializer.toJson<String>(emoji),
      'senderId': serializer.toJson<int?>(senderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Reaction copyWith(
          {String? messageId,
          String? emoji,
          Value<int?> senderId = const Value.absent(),
          DateTime? createdAt}) =>
      Reaction(
        messageId: messageId ?? this.messageId,
        emoji: emoji ?? this.emoji,
        senderId: senderId.present ? senderId.value : this.senderId,
        createdAt: createdAt ?? this.createdAt,
      );
  Reaction copyWithCompanion(ReactionsCompanion data) {
    return Reaction(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reaction(')
          ..write('messageId: $messageId, ')
          ..write('emoji: $emoji, ')
          ..write('senderId: $senderId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, emoji, senderId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reaction &&
          other.messageId == this.messageId &&
          other.emoji == this.emoji &&
          other.senderId == this.senderId &&
          other.createdAt == this.createdAt);
}

class ReactionsCompanion extends UpdateCompanion<Reaction> {
  final Value<String> messageId;
  final Value<String> emoji;
  final Value<int?> senderId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReactionsCompanion({
    this.messageId = const Value.absent(),
    this.emoji = const Value.absent(),
    this.senderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReactionsCompanion.insert({
    required String messageId,
    required String emoji,
    this.senderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        emoji = Value(emoji);
  static Insertable<Reaction> custom({
    Expression<String>? messageId,
    Expression<String>? emoji,
    Expression<int>? senderId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (emoji != null) 'emoji': emoji,
      if (senderId != null) 'sender_id': senderId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReactionsCompanion copyWith(
      {Value<String>? messageId,
      Value<String>? emoji,
      Value<int?>? senderId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ReactionsCompanion(
      messageId: messageId ?? this.messageId,
      emoji: emoji ?? this.emoji,
      senderId: senderId ?? this.senderId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<int>(senderId.value);
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
    return (StringBuffer('ReactionsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('emoji: $emoji, ')
          ..write('senderId: $senderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES "groups" (group_id) ON DELETE CASCADE'));
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (user_id)'));
  @override
  late final GeneratedColumnWithTypeConverter<MemberState?, String>
      memberState = GeneratedColumn<String>('member_state', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<MemberState?>(
              $GroupMembersTable.$convertermemberStaten);
  static const VerificationMeta _groupPublicKeyMeta =
      const VerificationMeta('groupPublicKey');
  @override
  late final GeneratedColumn<Uint8List> groupPublicKey =
      GeneratedColumn<Uint8List>('group_public_key', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _lastMessageMeta =
      const VerificationMeta('lastMessage');
  @override
  late final GeneratedColumn<DateTime> lastMessage = GeneratedColumn<DateTime>(
      'last_message', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [groupId, contactId, memberState, groupPublicKey, lastMessage, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(Insertable<GroupMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('group_public_key')) {
      context.handle(
          _groupPublicKeyMeta,
          groupPublicKey.isAcceptableOrUnknown(
              data['group_public_key']!, _groupPublicKeyMeta));
    }
    if (data.containsKey('last_message')) {
      context.handle(
          _lastMessageMeta,
          lastMessage.isAcceptableOrUnknown(
              data['last_message']!, _lastMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, contactId};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id'])!,
      memberState: $GroupMembersTable.$convertermemberStaten.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}member_state'])),
      groupPublicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}group_public_key']),
      lastMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MemberState, String, String> $convertermemberState =
      const EnumNameConverter<MemberState>(MemberState.values);
  static JsonTypeConverter2<MemberState?, String?, String?>
      $convertermemberStaten =
      JsonTypeConverter2.asNullable($convertermemberState);
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final String groupId;
  final int contactId;
  final MemberState? memberState;
  final Uint8List? groupPublicKey;
  final DateTime? lastMessage;
  final DateTime createdAt;
  const GroupMember(
      {required this.groupId,
      required this.contactId,
      this.memberState,
      this.groupPublicKey,
      this.lastMessage,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['contact_id'] = Variable<int>(contactId);
    if (!nullToAbsent || memberState != null) {
      map['member_state'] = Variable<String>(
          $GroupMembersTable.$convertermemberStaten.toSql(memberState));
    }
    if (!nullToAbsent || groupPublicKey != null) {
      map['group_public_key'] = Variable<Uint8List>(groupPublicKey);
    }
    if (!nullToAbsent || lastMessage != null) {
      map['last_message'] = Variable<DateTime>(lastMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      contactId: Value(contactId),
      memberState: memberState == null && nullToAbsent
          ? const Value.absent()
          : Value(memberState),
      groupPublicKey: groupPublicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(groupPublicKey),
      lastMessage: lastMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessage),
      createdAt: Value(createdAt),
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      groupId: serializer.fromJson<String>(json['groupId']),
      contactId: serializer.fromJson<int>(json['contactId']),
      memberState: $GroupMembersTable.$convertermemberStaten
          .fromJson(serializer.fromJson<String?>(json['memberState'])),
      groupPublicKey: serializer.fromJson<Uint8List?>(json['groupPublicKey']),
      lastMessage: serializer.fromJson<DateTime?>(json['lastMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'contactId': serializer.toJson<int>(contactId),
      'memberState': serializer.toJson<String?>(
          $GroupMembersTable.$convertermemberStaten.toJson(memberState)),
      'groupPublicKey': serializer.toJson<Uint8List?>(groupPublicKey),
      'lastMessage': serializer.toJson<DateTime?>(lastMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GroupMember copyWith(
          {String? groupId,
          int? contactId,
          Value<MemberState?> memberState = const Value.absent(),
          Value<Uint8List?> groupPublicKey = const Value.absent(),
          Value<DateTime?> lastMessage = const Value.absent(),
          DateTime? createdAt}) =>
      GroupMember(
        groupId: groupId ?? this.groupId,
        contactId: contactId ?? this.contactId,
        memberState: memberState.present ? memberState.value : this.memberState,
        groupPublicKey:
            groupPublicKey.present ? groupPublicKey.value : this.groupPublicKey,
        lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
        createdAt: createdAt ?? this.createdAt,
      );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      memberState:
          data.memberState.present ? data.memberState.value : this.memberState,
      groupPublicKey: data.groupPublicKey.present
          ? data.groupPublicKey.value
          : this.groupPublicKey,
      lastMessage:
          data.lastMessage.present ? data.lastMessage.value : this.lastMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('groupId: $groupId, ')
          ..write('contactId: $contactId, ')
          ..write('memberState: $memberState, ')
          ..write('groupPublicKey: $groupPublicKey, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, contactId, memberState,
      $driftBlobEquality.hash(groupPublicKey), lastMessage, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.groupId == this.groupId &&
          other.contactId == this.contactId &&
          other.memberState == this.memberState &&
          $driftBlobEquality.equals(
              other.groupPublicKey, this.groupPublicKey) &&
          other.lastMessage == this.lastMessage &&
          other.createdAt == this.createdAt);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> groupId;
  final Value<int> contactId;
  final Value<MemberState?> memberState;
  final Value<Uint8List?> groupPublicKey;
  final Value<DateTime?> lastMessage;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.memberState = const Value.absent(),
    this.groupPublicKey = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String groupId,
    required int contactId,
    this.memberState = const Value.absent(),
    this.groupPublicKey = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : groupId = Value(groupId),
        contactId = Value(contactId);
  static Insertable<GroupMember> custom({
    Expression<String>? groupId,
    Expression<int>? contactId,
    Expression<String>? memberState,
    Expression<Uint8List>? groupPublicKey,
    Expression<DateTime>? lastMessage,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (contactId != null) 'contact_id': contactId,
      if (memberState != null) 'member_state': memberState,
      if (groupPublicKey != null) 'group_public_key': groupPublicKey,
      if (lastMessage != null) 'last_message': lastMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith(
      {Value<String>? groupId,
      Value<int>? contactId,
      Value<MemberState?>? memberState,
      Value<Uint8List?>? groupPublicKey,
      Value<DateTime?>? lastMessage,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      contactId: contactId ?? this.contactId,
      memberState: memberState ?? this.memberState,
      groupPublicKey: groupPublicKey ?? this.groupPublicKey,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (memberState.present) {
      map['member_state'] = Variable<String>(
          $GroupMembersTable.$convertermemberStaten.toSql(memberState.value));
    }
    if (groupPublicKey.present) {
      map['group_public_key'] = Variable<Uint8List>(groupPublicKey.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<DateTime>(lastMessage.value);
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
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('contactId: $contactId, ')
          ..write('memberState: $memberState, ')
          ..write('groupPublicKey: $groupPublicKey, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _receiptIdMeta =
      const VerificationMeta('receiptId');
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
      'receipt_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES messages (message_id) ON DELETE CASCADE'));
  static const VerificationMeta _messageMeta =
      const VerificationMeta('message');
  @override
  late final GeneratedColumn<Uint8List> message = GeneratedColumn<Uint8List>(
      'message', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _contactWillSendsReceiptMeta =
      const VerificationMeta('contactWillSendsReceipt');
  @override
  late final GeneratedColumn<bool> contactWillSendsReceipt =
      GeneratedColumn<bool>('contact_will_sends_receipt', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("contact_will_sends_receipt" IN (0, 1))'),
          defaultValue: const Constant(true));
  static const VerificationMeta _markForRetryMeta =
      const VerificationMeta('markForRetry');
  @override
  late final GeneratedColumn<DateTime> markForRetry = GeneratedColumn<DateTime>(
      'mark_for_retry', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _markForRetryAfterAcceptedMeta =
      const VerificationMeta('markForRetryAfterAccepted');
  @override
  late final GeneratedColumn<DateTime> markForRetryAfterAccepted =
      GeneratedColumn<DateTime>(
          'mark_for_retry_after_accepted', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _ackByServerAtMeta =
      const VerificationMeta('ackByServerAt');
  @override
  late final GeneratedColumn<DateTime> ackByServerAt =
      GeneratedColumn<DateTime>('ack_by_server_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastRetryMeta =
      const VerificationMeta('lastRetry');
  @override
  late final GeneratedColumn<DateTime> lastRetry = GeneratedColumn<DateTime>(
      'last_retry', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        receiptId,
        contactId,
        messageId,
        message,
        contactWillSendsReceipt,
        markForRetry,
        markForRetryAfterAccepted,
        ackByServerAt,
        retryCount,
        lastRetry,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(Insertable<Receipt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('receipt_id')) {
      context.handle(_receiptIdMeta,
          receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta));
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    }
    if (data.containsKey('message')) {
      context.handle(_messageMeta,
          message.isAcceptableOrUnknown(data['message']!, _messageMeta));
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('contact_will_sends_receipt')) {
      context.handle(
          _contactWillSendsReceiptMeta,
          contactWillSendsReceipt.isAcceptableOrUnknown(
              data['contact_will_sends_receipt']!,
              _contactWillSendsReceiptMeta));
    }
    if (data.containsKey('mark_for_retry')) {
      context.handle(
          _markForRetryMeta,
          markForRetry.isAcceptableOrUnknown(
              data['mark_for_retry']!, _markForRetryMeta));
    }
    if (data.containsKey('mark_for_retry_after_accepted')) {
      context.handle(
          _markForRetryAfterAcceptedMeta,
          markForRetryAfterAccepted.isAcceptableOrUnknown(
              data['mark_for_retry_after_accepted']!,
              _markForRetryAfterAcceptedMeta));
    }
    if (data.containsKey('ack_by_server_at')) {
      context.handle(
          _ackByServerAtMeta,
          ackByServerAt.isAcceptableOrUnknown(
              data['ack_by_server_at']!, _ackByServerAtMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('last_retry')) {
      context.handle(_lastRetryMeta,
          lastRetry.isAcceptableOrUnknown(data['last_retry']!, _lastRetryMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {receiptId};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      receiptId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id']),
      message: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}message'])!,
      contactWillSendsReceipt: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}contact_will_sends_receipt'])!,
      markForRetry: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}mark_for_retry']),
      markForRetryAfterAccepted: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}mark_for_retry_after_accepted']),
      ackByServerAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}ack_by_server_at']),
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      lastRetry: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_retry']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final String receiptId;
  final int contactId;
  final String? messageId;

  /// This is the protobuf 'Message'
  final Uint8List message;
  final bool contactWillSendsReceipt;
  final DateTime? markForRetry;
  final DateTime? markForRetryAfterAccepted;
  final DateTime? ackByServerAt;
  final int retryCount;
  final DateTime? lastRetry;
  final DateTime createdAt;
  const Receipt(
      {required this.receiptId,
      required this.contactId,
      this.messageId,
      required this.message,
      required this.contactWillSendsReceipt,
      this.markForRetry,
      this.markForRetryAfterAccepted,
      this.ackByServerAt,
      required this.retryCount,
      this.lastRetry,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['receipt_id'] = Variable<String>(receiptId);
    map['contact_id'] = Variable<int>(contactId);
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['message'] = Variable<Uint8List>(message);
    map['contact_will_sends_receipt'] = Variable<bool>(contactWillSendsReceipt);
    if (!nullToAbsent || markForRetry != null) {
      map['mark_for_retry'] = Variable<DateTime>(markForRetry);
    }
    if (!nullToAbsent || markForRetryAfterAccepted != null) {
      map['mark_for_retry_after_accepted'] =
          Variable<DateTime>(markForRetryAfterAccepted);
    }
    if (!nullToAbsent || ackByServerAt != null) {
      map['ack_by_server_at'] = Variable<DateTime>(ackByServerAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastRetry != null) {
      map['last_retry'] = Variable<DateTime>(lastRetry);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      receiptId: Value(receiptId),
      contactId: Value(contactId),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      message: Value(message),
      contactWillSendsReceipt: Value(contactWillSendsReceipt),
      markForRetry: markForRetry == null && nullToAbsent
          ? const Value.absent()
          : Value(markForRetry),
      markForRetryAfterAccepted:
          markForRetryAfterAccepted == null && nullToAbsent
              ? const Value.absent()
              : Value(markForRetryAfterAccepted),
      ackByServerAt: ackByServerAt == null && nullToAbsent
          ? const Value.absent()
          : Value(ackByServerAt),
      retryCount: Value(retryCount),
      lastRetry: lastRetry == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRetry),
      createdAt: Value(createdAt),
    );
  }

  factory Receipt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      receiptId: serializer.fromJson<String>(json['receiptId']),
      contactId: serializer.fromJson<int>(json['contactId']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      message: serializer.fromJson<Uint8List>(json['message']),
      contactWillSendsReceipt:
          serializer.fromJson<bool>(json['contactWillSendsReceipt']),
      markForRetry: serializer.fromJson<DateTime?>(json['markForRetry']),
      markForRetryAfterAccepted:
          serializer.fromJson<DateTime?>(json['markForRetryAfterAccepted']),
      ackByServerAt: serializer.fromJson<DateTime?>(json['ackByServerAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastRetry: serializer.fromJson<DateTime?>(json['lastRetry']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'receiptId': serializer.toJson<String>(receiptId),
      'contactId': serializer.toJson<int>(contactId),
      'messageId': serializer.toJson<String?>(messageId),
      'message': serializer.toJson<Uint8List>(message),
      'contactWillSendsReceipt':
          serializer.toJson<bool>(contactWillSendsReceipt),
      'markForRetry': serializer.toJson<DateTime?>(markForRetry),
      'markForRetryAfterAccepted':
          serializer.toJson<DateTime?>(markForRetryAfterAccepted),
      'ackByServerAt': serializer.toJson<DateTime?>(ackByServerAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastRetry': serializer.toJson<DateTime?>(lastRetry),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Receipt copyWith(
          {String? receiptId,
          int? contactId,
          Value<String?> messageId = const Value.absent(),
          Uint8List? message,
          bool? contactWillSendsReceipt,
          Value<DateTime?> markForRetry = const Value.absent(),
          Value<DateTime?> markForRetryAfterAccepted = const Value.absent(),
          Value<DateTime?> ackByServerAt = const Value.absent(),
          int? retryCount,
          Value<DateTime?> lastRetry = const Value.absent(),
          DateTime? createdAt}) =>
      Receipt(
        receiptId: receiptId ?? this.receiptId,
        contactId: contactId ?? this.contactId,
        messageId: messageId.present ? messageId.value : this.messageId,
        message: message ?? this.message,
        contactWillSendsReceipt:
            contactWillSendsReceipt ?? this.contactWillSendsReceipt,
        markForRetry:
            markForRetry.present ? markForRetry.value : this.markForRetry,
        markForRetryAfterAccepted: markForRetryAfterAccepted.present
            ? markForRetryAfterAccepted.value
            : this.markForRetryAfterAccepted,
        ackByServerAt:
            ackByServerAt.present ? ackByServerAt.value : this.ackByServerAt,
        retryCount: retryCount ?? this.retryCount,
        lastRetry: lastRetry.present ? lastRetry.value : this.lastRetry,
        createdAt: createdAt ?? this.createdAt,
      );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      message: data.message.present ? data.message.value : this.message,
      contactWillSendsReceipt: data.contactWillSendsReceipt.present
          ? data.contactWillSendsReceipt.value
          : this.contactWillSendsReceipt,
      markForRetry: data.markForRetry.present
          ? data.markForRetry.value
          : this.markForRetry,
      markForRetryAfterAccepted: data.markForRetryAfterAccepted.present
          ? data.markForRetryAfterAccepted.value
          : this.markForRetryAfterAccepted,
      ackByServerAt: data.ackByServerAt.present
          ? data.ackByServerAt.value
          : this.ackByServerAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      lastRetry: data.lastRetry.present ? data.lastRetry.value : this.lastRetry,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('receiptId: $receiptId, ')
          ..write('contactId: $contactId, ')
          ..write('messageId: $messageId, ')
          ..write('message: $message, ')
          ..write('contactWillSendsReceipt: $contactWillSendsReceipt, ')
          ..write('markForRetry: $markForRetry, ')
          ..write('markForRetryAfterAccepted: $markForRetryAfterAccepted, ')
          ..write('ackByServerAt: $ackByServerAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetry: $lastRetry, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      receiptId,
      contactId,
      messageId,
      $driftBlobEquality.hash(message),
      contactWillSendsReceipt,
      markForRetry,
      markForRetryAfterAccepted,
      ackByServerAt,
      retryCount,
      lastRetry,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.receiptId == this.receiptId &&
          other.contactId == this.contactId &&
          other.messageId == this.messageId &&
          $driftBlobEquality.equals(other.message, this.message) &&
          other.contactWillSendsReceipt == this.contactWillSendsReceipt &&
          other.markForRetry == this.markForRetry &&
          other.markForRetryAfterAccepted == this.markForRetryAfterAccepted &&
          other.ackByServerAt == this.ackByServerAt &&
          other.retryCount == this.retryCount &&
          other.lastRetry == this.lastRetry &&
          other.createdAt == this.createdAt);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<String> receiptId;
  final Value<int> contactId;
  final Value<String?> messageId;
  final Value<Uint8List> message;
  final Value<bool> contactWillSendsReceipt;
  final Value<DateTime?> markForRetry;
  final Value<DateTime?> markForRetryAfterAccepted;
  final Value<DateTime?> ackByServerAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastRetry;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.receiptId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.message = const Value.absent(),
    this.contactWillSendsReceipt = const Value.absent(),
    this.markForRetry = const Value.absent(),
    this.markForRetryAfterAccepted = const Value.absent(),
    this.ackByServerAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetry = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required String receiptId,
    required int contactId,
    this.messageId = const Value.absent(),
    required Uint8List message,
    this.contactWillSendsReceipt = const Value.absent(),
    this.markForRetry = const Value.absent(),
    this.markForRetryAfterAccepted = const Value.absent(),
    this.ackByServerAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetry = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : receiptId = Value(receiptId),
        contactId = Value(contactId),
        message = Value(message);
  static Insertable<Receipt> custom({
    Expression<String>? receiptId,
    Expression<int>? contactId,
    Expression<String>? messageId,
    Expression<Uint8List>? message,
    Expression<bool>? contactWillSendsReceipt,
    Expression<DateTime>? markForRetry,
    Expression<DateTime>? markForRetryAfterAccepted,
    Expression<DateTime>? ackByServerAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastRetry,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (receiptId != null) 'receipt_id': receiptId,
      if (contactId != null) 'contact_id': contactId,
      if (messageId != null) 'message_id': messageId,
      if (message != null) 'message': message,
      if (contactWillSendsReceipt != null)
        'contact_will_sends_receipt': contactWillSendsReceipt,
      if (markForRetry != null) 'mark_for_retry': markForRetry,
      if (markForRetryAfterAccepted != null)
        'mark_for_retry_after_accepted': markForRetryAfterAccepted,
      if (ackByServerAt != null) 'ack_by_server_at': ackByServerAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastRetry != null) 'last_retry': lastRetry,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith(
      {Value<String>? receiptId,
      Value<int>? contactId,
      Value<String?>? messageId,
      Value<Uint8List>? message,
      Value<bool>? contactWillSendsReceipt,
      Value<DateTime?>? markForRetry,
      Value<DateTime?>? markForRetryAfterAccepted,
      Value<DateTime?>? ackByServerAt,
      Value<int>? retryCount,
      Value<DateTime?>? lastRetry,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ReceiptsCompanion(
      receiptId: receiptId ?? this.receiptId,
      contactId: contactId ?? this.contactId,
      messageId: messageId ?? this.messageId,
      message: message ?? this.message,
      contactWillSendsReceipt:
          contactWillSendsReceipt ?? this.contactWillSendsReceipt,
      markForRetry: markForRetry ?? this.markForRetry,
      markForRetryAfterAccepted:
          markForRetryAfterAccepted ?? this.markForRetryAfterAccepted,
      ackByServerAt: ackByServerAt ?? this.ackByServerAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetry: lastRetry ?? this.lastRetry,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (message.present) {
      map['message'] = Variable<Uint8List>(message.value);
    }
    if (contactWillSendsReceipt.present) {
      map['contact_will_sends_receipt'] =
          Variable<bool>(contactWillSendsReceipt.value);
    }
    if (markForRetry.present) {
      map['mark_for_retry'] = Variable<DateTime>(markForRetry.value);
    }
    if (markForRetryAfterAccepted.present) {
      map['mark_for_retry_after_accepted'] =
          Variable<DateTime>(markForRetryAfterAccepted.value);
    }
    if (ackByServerAt.present) {
      map['ack_by_server_at'] = Variable<DateTime>(ackByServerAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastRetry.present) {
      map['last_retry'] = Variable<DateTime>(lastRetry.value);
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
    return (StringBuffer('ReceiptsCompanion(')
          ..write('receiptId: $receiptId, ')
          ..write('contactId: $contactId, ')
          ..write('messageId: $messageId, ')
          ..write('message: $message, ')
          ..write('contactWillSendsReceipt: $contactWillSendsReceipt, ')
          ..write('markForRetry: $markForRetry, ')
          ..write('markForRetryAfterAccepted: $markForRetryAfterAccepted, ')
          ..write('ackByServerAt: $ackByServerAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetry: $lastRetry, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceivedReceiptsTable extends ReceivedReceipts
    with TableInfo<$ReceivedReceiptsTable, ReceivedReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceivedReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _receiptIdMeta =
      const VerificationMeta('receiptId');
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
      'receipt_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [receiptId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'received_receipts';
  @override
  VerificationContext validateIntegrity(Insertable<ReceivedReceipt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('receipt_id')) {
      context.handle(_receiptIdMeta,
          receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta));
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {receiptId};
  @override
  ReceivedReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceivedReceipt(
      receiptId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ReceivedReceiptsTable createAlias(String alias) {
    return $ReceivedReceiptsTable(attachedDatabase, alias);
  }
}

class ReceivedReceipt extends DataClass implements Insertable<ReceivedReceipt> {
  final String receiptId;
  final DateTime createdAt;
  const ReceivedReceipt({required this.receiptId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['receipt_id'] = Variable<String>(receiptId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReceivedReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceivedReceiptsCompanion(
      receiptId: Value(receiptId),
      createdAt: Value(createdAt),
    );
  }

  factory ReceivedReceipt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceivedReceipt(
      receiptId: serializer.fromJson<String>(json['receiptId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'receiptId': serializer.toJson<String>(receiptId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReceivedReceipt copyWith({String? receiptId, DateTime? createdAt}) =>
      ReceivedReceipt(
        receiptId: receiptId ?? this.receiptId,
        createdAt: createdAt ?? this.createdAt,
      );
  ReceivedReceipt copyWithCompanion(ReceivedReceiptsCompanion data) {
    return ReceivedReceipt(
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceivedReceipt(')
          ..write('receiptId: $receiptId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(receiptId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceivedReceipt &&
          other.receiptId == this.receiptId &&
          other.createdAt == this.createdAt);
}

class ReceivedReceiptsCompanion extends UpdateCompanion<ReceivedReceipt> {
  final Value<String> receiptId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReceivedReceiptsCompanion({
    this.receiptId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceivedReceiptsCompanion.insert({
    required String receiptId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : receiptId = Value(receiptId);
  static Insertable<ReceivedReceipt> custom({
    Expression<String>? receiptId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (receiptId != null) 'receipt_id': receiptId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceivedReceiptsCompanion copyWith(
      {Value<String>? receiptId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ReceivedReceiptsCompanion(
      receiptId: receiptId ?? this.receiptId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
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
    return (StringBuffer('ReceivedReceiptsCompanion(')
          ..write('receiptId: $receiptId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalIdentityKeyStoresTable extends SignalIdentityKeyStores
    with TableInfo<$SignalIdentityKeyStoresTable, SignalIdentityKeyStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalIdentityKeyStoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
      'device_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _identityKeyMeta =
      const VerificationMeta('identityKey');
  @override
  late final GeneratedColumn<Uint8List> identityKey =
      GeneratedColumn<Uint8List>('identity_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [deviceId, name, identityKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_identity_key_stores';
  @override
  VerificationContext validateIntegrity(
      Insertable<SignalIdentityKeyStore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('identity_key')) {
      context.handle(
          _identityKeyMeta,
          identityKey.isAcceptableOrUnknown(
              data['identity_key']!, _identityKeyMeta));
    } else if (isInserting) {
      context.missing(_identityKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, name};
  @override
  SignalIdentityKeyStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalIdentityKeyStore(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      identityKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}identity_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
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
  const SignalIdentityKeyStore(
      {required this.deviceId,
      required this.name,
      required this.identityKey,
      required this.createdAt});
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

  factory SignalIdentityKeyStore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  SignalIdentityKeyStore copyWith(
          {int? deviceId,
          String? name,
          Uint8List? identityKey,
          DateTime? createdAt}) =>
      SignalIdentityKeyStore(
        deviceId: deviceId ?? this.deviceId,
        name: name ?? this.name,
        identityKey: identityKey ?? this.identityKey,
        createdAt: createdAt ?? this.createdAt,
      );
  SignalIdentityKeyStore copyWithCompanion(
      SignalIdentityKeyStoresCompanion data) {
    return SignalIdentityKeyStore(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      identityKey:
          data.identityKey.present ? data.identityKey.value : this.identityKey,
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
      deviceId, name, $driftBlobEquality.hash(identityKey), createdAt);
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
  })  : deviceId = Value(deviceId),
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

  SignalIdentityKeyStoresCompanion copyWith(
      {Value<int>? deviceId,
      Value<String>? name,
      Value<Uint8List>? identityKey,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
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
  static const VerificationMeta _preKeyIdMeta =
      const VerificationMeta('preKeyId');
  @override
  late final GeneratedColumn<int> preKeyId = GeneratedColumn<int>(
      'pre_key_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _preKeyMeta = const VerificationMeta('preKey');
  @override
  late final GeneratedColumn<Uint8List> preKey = GeneratedColumn<Uint8List>(
      'pre_key', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [preKeyId, preKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_pre_key_stores';
  @override
  VerificationContext validateIntegrity(Insertable<SignalPreKeyStore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pre_key_id')) {
      context.handle(_preKeyIdMeta,
          preKeyId.isAcceptableOrUnknown(data['pre_key_id']!, _preKeyIdMeta));
    }
    if (data.containsKey('pre_key')) {
      context.handle(_preKeyMeta,
          preKey.isAcceptableOrUnknown(data['pre_key']!, _preKeyMeta));
    } else if (isInserting) {
      context.missing(_preKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {preKeyId};
  @override
  SignalPreKeyStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalPreKeyStore(
      preKeyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pre_key_id'])!,
      preKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}pre_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
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
  const SignalPreKeyStore(
      {required this.preKeyId, required this.preKey, required this.createdAt});
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

  factory SignalPreKeyStore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  SignalPreKeyStore copyWith(
          {int? preKeyId, Uint8List? preKey, DateTime? createdAt}) =>
      SignalPreKeyStore(
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

  SignalPreKeyStoresCompanion copyWith(
      {Value<int>? preKeyId,
      Value<Uint8List>? preKey,
      Value<DateTime>? createdAt}) {
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
  static const VerificationMeta _senderKeyNameMeta =
      const VerificationMeta('senderKeyName');
  @override
  late final GeneratedColumn<String> senderKeyName = GeneratedColumn<String>(
      'sender_key_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderKeyMeta =
      const VerificationMeta('senderKey');
  @override
  late final GeneratedColumn<Uint8List> senderKey = GeneratedColumn<Uint8List>(
      'sender_key', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [senderKeyName, senderKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_sender_key_stores';
  @override
  VerificationContext validateIntegrity(
      Insertable<SignalSenderKeyStore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sender_key_name')) {
      context.handle(
          _senderKeyNameMeta,
          senderKeyName.isAcceptableOrUnknown(
              data['sender_key_name']!, _senderKeyNameMeta));
    } else if (isInserting) {
      context.missing(_senderKeyNameMeta);
    }
    if (data.containsKey('sender_key')) {
      context.handle(_senderKeyMeta,
          senderKey.isAcceptableOrUnknown(data['sender_key']!, _senderKeyMeta));
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
          DriftSqlType.string, data['${effectivePrefix}sender_key_name'])!,
      senderKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}sender_key'])!,
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
  const SignalSenderKeyStore(
      {required this.senderKeyName, required this.senderKey});
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

  factory SignalSenderKeyStore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  SignalSenderKeyStore copyWith(
          {String? senderKeyName, Uint8List? senderKey}) =>
      SignalSenderKeyStore(
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
  })  : senderKeyName = Value(senderKeyName),
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

  SignalSenderKeyStoresCompanion copyWith(
      {Value<String>? senderKeyName,
      Value<Uint8List>? senderKey,
      Value<int>? rowid}) {
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
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
      'device_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionRecordMeta =
      const VerificationMeta('sessionRecord');
  @override
  late final GeneratedColumn<Uint8List> sessionRecord =
      GeneratedColumn<Uint8List>('session_record', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [deviceId, name, sessionRecord, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_session_stores';
  @override
  VerificationContext validateIntegrity(Insertable<SignalSessionStore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('session_record')) {
      context.handle(
          _sessionRecordMeta,
          sessionRecord.isAcceptableOrUnknown(
              data['session_record']!, _sessionRecordMeta));
    } else if (isInserting) {
      context.missing(_sessionRecordMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, name};
  @override
  SignalSessionStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSessionStore(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sessionRecord: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}session_record'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
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
  const SignalSessionStore(
      {required this.deviceId,
      required this.name,
      required this.sessionRecord,
      required this.createdAt});
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

  factory SignalSessionStore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
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

  SignalSessionStore copyWith(
          {int? deviceId,
          String? name,
          Uint8List? sessionRecord,
          DateTime? createdAt}) =>
      SignalSessionStore(
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
      deviceId, name, $driftBlobEquality.hash(sessionRecord), createdAt);
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
  })  : deviceId = Value(deviceId),
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

  SignalSessionStoresCompanion copyWith(
      {Value<int>? deviceId,
      Value<String>? name,
      Value<Uint8List>? sessionRecord,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
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

class $SignalContactPreKeysTable extends SignalContactPreKeys
    with TableInfo<$SignalContactPreKeysTable, SignalContactPreKey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalContactPreKeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  static const VerificationMeta _preKeyIdMeta =
      const VerificationMeta('preKeyId');
  @override
  late final GeneratedColumn<int> preKeyId = GeneratedColumn<int>(
      'pre_key_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _preKeyMeta = const VerificationMeta('preKey');
  @override
  late final GeneratedColumn<Uint8List> preKey = GeneratedColumn<Uint8List>(
      'pre_key', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [contactId, preKeyId, preKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_contact_pre_keys';
  @override
  VerificationContext validateIntegrity(
      Insertable<SignalContactPreKey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('pre_key_id')) {
      context.handle(_preKeyIdMeta,
          preKeyId.isAcceptableOrUnknown(data['pre_key_id']!, _preKeyIdMeta));
    } else if (isInserting) {
      context.missing(_preKeyIdMeta);
    }
    if (data.containsKey('pre_key')) {
      context.handle(_preKeyMeta,
          preKey.isAcceptableOrUnknown(data['pre_key']!, _preKeyMeta));
    } else if (isInserting) {
      context.missing(_preKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contactId, preKeyId};
  @override
  SignalContactPreKey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalContactPreKey(
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id'])!,
      preKeyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pre_key_id'])!,
      preKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}pre_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SignalContactPreKeysTable createAlias(String alias) {
    return $SignalContactPreKeysTable(attachedDatabase, alias);
  }
}

class SignalContactPreKey extends DataClass
    implements Insertable<SignalContactPreKey> {
  final int contactId;
  final int preKeyId;
  final Uint8List preKey;
  final DateTime createdAt;
  const SignalContactPreKey(
      {required this.contactId,
      required this.preKeyId,
      required this.preKey,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_id'] = Variable<int>(contactId);
    map['pre_key_id'] = Variable<int>(preKeyId);
    map['pre_key'] = Variable<Uint8List>(preKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SignalContactPreKeysCompanion toCompanion(bool nullToAbsent) {
    return SignalContactPreKeysCompanion(
      contactId: Value(contactId),
      preKeyId: Value(preKeyId),
      preKey: Value(preKey),
      createdAt: Value(createdAt),
    );
  }

  factory SignalContactPreKey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalContactPreKey(
      contactId: serializer.fromJson<int>(json['contactId']),
      preKeyId: serializer.fromJson<int>(json['preKeyId']),
      preKey: serializer.fromJson<Uint8List>(json['preKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<int>(contactId),
      'preKeyId': serializer.toJson<int>(preKeyId),
      'preKey': serializer.toJson<Uint8List>(preKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalContactPreKey copyWith(
          {int? contactId,
          int? preKeyId,
          Uint8List? preKey,
          DateTime? createdAt}) =>
      SignalContactPreKey(
        contactId: contactId ?? this.contactId,
        preKeyId: preKeyId ?? this.preKeyId,
        preKey: preKey ?? this.preKey,
        createdAt: createdAt ?? this.createdAt,
      );
  SignalContactPreKey copyWithCompanion(SignalContactPreKeysCompanion data) {
    return SignalContactPreKey(
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      preKeyId: data.preKeyId.present ? data.preKeyId.value : this.preKeyId,
      preKey: data.preKey.present ? data.preKey.value : this.preKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalContactPreKey(')
          ..write('contactId: $contactId, ')
          ..write('preKeyId: $preKeyId, ')
          ..write('preKey: $preKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      contactId, preKeyId, $driftBlobEquality.hash(preKey), createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalContactPreKey &&
          other.contactId == this.contactId &&
          other.preKeyId == this.preKeyId &&
          $driftBlobEquality.equals(other.preKey, this.preKey) &&
          other.createdAt == this.createdAt);
}

class SignalContactPreKeysCompanion
    extends UpdateCompanion<SignalContactPreKey> {
  final Value<int> contactId;
  final Value<int> preKeyId;
  final Value<Uint8List> preKey;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SignalContactPreKeysCompanion({
    this.contactId = const Value.absent(),
    this.preKeyId = const Value.absent(),
    this.preKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalContactPreKeysCompanion.insert({
    required int contactId,
    required int preKeyId,
    required Uint8List preKey,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : contactId = Value(contactId),
        preKeyId = Value(preKeyId),
        preKey = Value(preKey);
  static Insertable<SignalContactPreKey> custom({
    Expression<int>? contactId,
    Expression<int>? preKeyId,
    Expression<Uint8List>? preKey,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contactId != null) 'contact_id': contactId,
      if (preKeyId != null) 'pre_key_id': preKeyId,
      if (preKey != null) 'pre_key': preKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignalContactPreKeysCompanion copyWith(
      {Value<int>? contactId,
      Value<int>? preKeyId,
      Value<Uint8List>? preKey,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SignalContactPreKeysCompanion(
      contactId: contactId ?? this.contactId,
      preKeyId: preKeyId ?? this.preKeyId,
      preKey: preKey ?? this.preKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (preKeyId.present) {
      map['pre_key_id'] = Variable<int>(preKeyId.value);
    }
    if (preKey.present) {
      map['pre_key'] = Variable<Uint8List>(preKey.value);
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
    return (StringBuffer('SignalContactPreKeysCompanion(')
          ..write('contactId: $contactId, ')
          ..write('preKeyId: $preKeyId, ')
          ..write('preKey: $preKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignalContactSignedPreKeysTable extends SignalContactSignedPreKeys
    with
        TableInfo<$SignalContactSignedPreKeysTable, SignalContactSignedPreKey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalContactSignedPreKeysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  static const VerificationMeta _signedPreKeyIdMeta =
      const VerificationMeta('signedPreKeyId');
  @override
  late final GeneratedColumn<int> signedPreKeyId = GeneratedColumn<int>(
      'signed_pre_key_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _signedPreKeyMeta =
      const VerificationMeta('signedPreKey');
  @override
  late final GeneratedColumn<Uint8List> signedPreKey =
      GeneratedColumn<Uint8List>('signed_pre_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _signedPreKeySignatureMeta =
      const VerificationMeta('signedPreKeySignature');
  @override
  late final GeneratedColumn<Uint8List> signedPreKeySignature =
      GeneratedColumn<Uint8List>('signed_pre_key_signature', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        contactId,
        signedPreKeyId,
        signedPreKey,
        signedPreKeySignature,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_contact_signed_pre_keys';
  @override
  VerificationContext validateIntegrity(
      Insertable<SignalContactSignedPreKey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    }
    if (data.containsKey('signed_pre_key_id')) {
      context.handle(
          _signedPreKeyIdMeta,
          signedPreKeyId.isAcceptableOrUnknown(
              data['signed_pre_key_id']!, _signedPreKeyIdMeta));
    } else if (isInserting) {
      context.missing(_signedPreKeyIdMeta);
    }
    if (data.containsKey('signed_pre_key')) {
      context.handle(
          _signedPreKeyMeta,
          signedPreKey.isAcceptableOrUnknown(
              data['signed_pre_key']!, _signedPreKeyMeta));
    } else if (isInserting) {
      context.missing(_signedPreKeyMeta);
    }
    if (data.containsKey('signed_pre_key_signature')) {
      context.handle(
          _signedPreKeySignatureMeta,
          signedPreKeySignature.isAcceptableOrUnknown(
              data['signed_pre_key_signature']!, _signedPreKeySignatureMeta));
    } else if (isInserting) {
      context.missing(_signedPreKeySignatureMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contactId};
  @override
  SignalContactSignedPreKey map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalContactSignedPreKey(
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id'])!,
      signedPreKeyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}signed_pre_key_id'])!,
      signedPreKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}signed_pre_key'])!,
      signedPreKeySignature: attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}signed_pre_key_signature'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SignalContactSignedPreKeysTable createAlias(String alias) {
    return $SignalContactSignedPreKeysTable(attachedDatabase, alias);
  }
}

class SignalContactSignedPreKey extends DataClass
    implements Insertable<SignalContactSignedPreKey> {
  final int contactId;
  final int signedPreKeyId;
  final Uint8List signedPreKey;
  final Uint8List signedPreKeySignature;
  final DateTime createdAt;
  const SignalContactSignedPreKey(
      {required this.contactId,
      required this.signedPreKeyId,
      required this.signedPreKey,
      required this.signedPreKeySignature,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_id'] = Variable<int>(contactId);
    map['signed_pre_key_id'] = Variable<int>(signedPreKeyId);
    map['signed_pre_key'] = Variable<Uint8List>(signedPreKey);
    map['signed_pre_key_signature'] =
        Variable<Uint8List>(signedPreKeySignature);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SignalContactSignedPreKeysCompanion toCompanion(bool nullToAbsent) {
    return SignalContactSignedPreKeysCompanion(
      contactId: Value(contactId),
      signedPreKeyId: Value(signedPreKeyId),
      signedPreKey: Value(signedPreKey),
      signedPreKeySignature: Value(signedPreKeySignature),
      createdAt: Value(createdAt),
    );
  }

  factory SignalContactSignedPreKey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalContactSignedPreKey(
      contactId: serializer.fromJson<int>(json['contactId']),
      signedPreKeyId: serializer.fromJson<int>(json['signedPreKeyId']),
      signedPreKey: serializer.fromJson<Uint8List>(json['signedPreKey']),
      signedPreKeySignature:
          serializer.fromJson<Uint8List>(json['signedPreKeySignature']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<int>(contactId),
      'signedPreKeyId': serializer.toJson<int>(signedPreKeyId),
      'signedPreKey': serializer.toJson<Uint8List>(signedPreKey),
      'signedPreKeySignature':
          serializer.toJson<Uint8List>(signedPreKeySignature),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalContactSignedPreKey copyWith(
          {int? contactId,
          int? signedPreKeyId,
          Uint8List? signedPreKey,
          Uint8List? signedPreKeySignature,
          DateTime? createdAt}) =>
      SignalContactSignedPreKey(
        contactId: contactId ?? this.contactId,
        signedPreKeyId: signedPreKeyId ?? this.signedPreKeyId,
        signedPreKey: signedPreKey ?? this.signedPreKey,
        signedPreKeySignature:
            signedPreKeySignature ?? this.signedPreKeySignature,
        createdAt: createdAt ?? this.createdAt,
      );
  SignalContactSignedPreKey copyWithCompanion(
      SignalContactSignedPreKeysCompanion data) {
    return SignalContactSignedPreKey(
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      signedPreKeyId: data.signedPreKeyId.present
          ? data.signedPreKeyId.value
          : this.signedPreKeyId,
      signedPreKey: data.signedPreKey.present
          ? data.signedPreKey.value
          : this.signedPreKey,
      signedPreKeySignature: data.signedPreKeySignature.present
          ? data.signedPreKeySignature.value
          : this.signedPreKeySignature,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalContactSignedPreKey(')
          ..write('contactId: $contactId, ')
          ..write('signedPreKeyId: $signedPreKeyId, ')
          ..write('signedPreKey: $signedPreKey, ')
          ..write('signedPreKeySignature: $signedPreKeySignature, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      contactId,
      signedPreKeyId,
      $driftBlobEquality.hash(signedPreKey),
      $driftBlobEquality.hash(signedPreKeySignature),
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignalContactSignedPreKey &&
          other.contactId == this.contactId &&
          other.signedPreKeyId == this.signedPreKeyId &&
          $driftBlobEquality.equals(other.signedPreKey, this.signedPreKey) &&
          $driftBlobEquality.equals(
              other.signedPreKeySignature, this.signedPreKeySignature) &&
          other.createdAt == this.createdAt);
}

class SignalContactSignedPreKeysCompanion
    extends UpdateCompanion<SignalContactSignedPreKey> {
  final Value<int> contactId;
  final Value<int> signedPreKeyId;
  final Value<Uint8List> signedPreKey;
  final Value<Uint8List> signedPreKeySignature;
  final Value<DateTime> createdAt;
  const SignalContactSignedPreKeysCompanion({
    this.contactId = const Value.absent(),
    this.signedPreKeyId = const Value.absent(),
    this.signedPreKey = const Value.absent(),
    this.signedPreKeySignature = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SignalContactSignedPreKeysCompanion.insert({
    this.contactId = const Value.absent(),
    required int signedPreKeyId,
    required Uint8List signedPreKey,
    required Uint8List signedPreKeySignature,
    this.createdAt = const Value.absent(),
  })  : signedPreKeyId = Value(signedPreKeyId),
        signedPreKey = Value(signedPreKey),
        signedPreKeySignature = Value(signedPreKeySignature);
  static Insertable<SignalContactSignedPreKey> custom({
    Expression<int>? contactId,
    Expression<int>? signedPreKeyId,
    Expression<Uint8List>? signedPreKey,
    Expression<Uint8List>? signedPreKeySignature,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (contactId != null) 'contact_id': contactId,
      if (signedPreKeyId != null) 'signed_pre_key_id': signedPreKeyId,
      if (signedPreKey != null) 'signed_pre_key': signedPreKey,
      if (signedPreKeySignature != null)
        'signed_pre_key_signature': signedPreKeySignature,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SignalContactSignedPreKeysCompanion copyWith(
      {Value<int>? contactId,
      Value<int>? signedPreKeyId,
      Value<Uint8List>? signedPreKey,
      Value<Uint8List>? signedPreKeySignature,
      Value<DateTime>? createdAt}) {
    return SignalContactSignedPreKeysCompanion(
      contactId: contactId ?? this.contactId,
      signedPreKeyId: signedPreKeyId ?? this.signedPreKeyId,
      signedPreKey: signedPreKey ?? this.signedPreKey,
      signedPreKeySignature:
          signedPreKeySignature ?? this.signedPreKeySignature,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (signedPreKeyId.present) {
      map['signed_pre_key_id'] = Variable<int>(signedPreKeyId.value);
    }
    if (signedPreKey.present) {
      map['signed_pre_key'] = Variable<Uint8List>(signedPreKey.value);
    }
    if (signedPreKeySignature.present) {
      map['signed_pre_key_signature'] =
          Variable<Uint8List>(signedPreKeySignature.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalContactSignedPreKeysCompanion(')
          ..write('contactId: $contactId, ')
          ..write('signedPreKeyId: $signedPreKeyId, ')
          ..write('signedPreKey: $signedPreKey, ')
          ..write('signedPreKeySignature: $signedPreKeySignature, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MessageActionsTable extends MessageActions
    with TableInfo<$MessageActionsTable, MessageAction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES messages (message_id) ON DELETE CASCADE'));
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  @override
  late final GeneratedColumnWithTypeConverter<MessageActionType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MessageActionType>(
              $MessageActionsTable.$convertertype);
  static const VerificationMeta _actionAtMeta =
      const VerificationMeta('actionAt');
  @override
  late final GeneratedColumn<DateTime> actionAt = GeneratedColumn<DateTime>(
      'action_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [messageId, contactId, type, actionAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_actions';
  @override
  VerificationContext validateIntegrity(Insertable<MessageAction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('action_at')) {
      context.handle(_actionAtMeta,
          actionAt.isAcceptableOrUnknown(data['action_at']!, _actionAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, contactId, type};
  @override
  MessageAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageAction(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id'])!,
      type: $MessageActionsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      actionAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}action_at'])!,
    );
  }

  @override
  $MessageActionsTable createAlias(String alias) {
    return $MessageActionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MessageActionType, String, String> $convertertype =
      const EnumNameConverter<MessageActionType>(MessageActionType.values);
}

class MessageAction extends DataClass implements Insertable<MessageAction> {
  final String messageId;
  final int contactId;
  final MessageActionType type;
  final DateTime actionAt;
  const MessageAction(
      {required this.messageId,
      required this.contactId,
      required this.type,
      required this.actionAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['contact_id'] = Variable<int>(contactId);
    {
      map['type'] =
          Variable<String>($MessageActionsTable.$convertertype.toSql(type));
    }
    map['action_at'] = Variable<DateTime>(actionAt);
    return map;
  }

  MessageActionsCompanion toCompanion(bool nullToAbsent) {
    return MessageActionsCompanion(
      messageId: Value(messageId),
      contactId: Value(contactId),
      type: Value(type),
      actionAt: Value(actionAt),
    );
  }

  factory MessageAction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageAction(
      messageId: serializer.fromJson<String>(json['messageId']),
      contactId: serializer.fromJson<int>(json['contactId']),
      type: $MessageActionsTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      actionAt: serializer.fromJson<DateTime>(json['actionAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'contactId': serializer.toJson<int>(contactId),
      'type': serializer
          .toJson<String>($MessageActionsTable.$convertertype.toJson(type)),
      'actionAt': serializer.toJson<DateTime>(actionAt),
    };
  }

  MessageAction copyWith(
          {String? messageId,
          int? contactId,
          MessageActionType? type,
          DateTime? actionAt}) =>
      MessageAction(
        messageId: messageId ?? this.messageId,
        contactId: contactId ?? this.contactId,
        type: type ?? this.type,
        actionAt: actionAt ?? this.actionAt,
      );
  MessageAction copyWithCompanion(MessageActionsCompanion data) {
    return MessageAction(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      type: data.type.present ? data.type.value : this.type,
      actionAt: data.actionAt.present ? data.actionAt.value : this.actionAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageAction(')
          ..write('messageId: $messageId, ')
          ..write('contactId: $contactId, ')
          ..write('type: $type, ')
          ..write('actionAt: $actionAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, contactId, type, actionAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageAction &&
          other.messageId == this.messageId &&
          other.contactId == this.contactId &&
          other.type == this.type &&
          other.actionAt == this.actionAt);
}

class MessageActionsCompanion extends UpdateCompanion<MessageAction> {
  final Value<String> messageId;
  final Value<int> contactId;
  final Value<MessageActionType> type;
  final Value<DateTime> actionAt;
  final Value<int> rowid;
  const MessageActionsCompanion({
    this.messageId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.type = const Value.absent(),
    this.actionAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessageActionsCompanion.insert({
    required String messageId,
    required int contactId,
    required MessageActionType type,
    this.actionAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        contactId = Value(contactId),
        type = Value(type);
  static Insertable<MessageAction> custom({
    Expression<String>? messageId,
    Expression<int>? contactId,
    Expression<String>? type,
    Expression<DateTime>? actionAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (contactId != null) 'contact_id': contactId,
      if (type != null) 'type': type,
      if (actionAt != null) 'action_at': actionAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessageActionsCompanion copyWith(
      {Value<String>? messageId,
      Value<int>? contactId,
      Value<MessageActionType>? type,
      Value<DateTime>? actionAt,
      Value<int>? rowid}) {
    return MessageActionsCompanion(
      messageId: messageId ?? this.messageId,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      actionAt: actionAt ?? this.actionAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
          $MessageActionsTable.$convertertype.toSql(type.value));
    }
    if (actionAt.present) {
      map['action_at'] = Variable<DateTime>(actionAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageActionsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('contactId: $contactId, ')
          ..write('type: $type, ')
          ..write('actionAt: $actionAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupHistoriesTable extends GroupHistories
    with TableInfo<$GroupHistoriesTable, GroupHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupHistoryIdMeta =
      const VerificationMeta('groupHistoryId');
  @override
  late final GeneratedColumn<String> groupHistoryId = GeneratedColumn<String>(
      'group_history_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES "groups" (group_id) ON DELETE CASCADE'));
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (user_id)'));
  static const VerificationMeta _affectedContactIdMeta =
      const VerificationMeta('affectedContactId');
  @override
  late final GeneratedColumn<int> affectedContactId = GeneratedColumn<int>(
      'affected_contact_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _oldGroupNameMeta =
      const VerificationMeta('oldGroupName');
  @override
  late final GeneratedColumn<String> oldGroupName = GeneratedColumn<String>(
      'old_group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newGroupNameMeta =
      const VerificationMeta('newGroupName');
  @override
  late final GeneratedColumn<String> newGroupName = GeneratedColumn<String>(
      'new_group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newDeleteMessagesAfterMillisecondsMeta =
      const VerificationMeta('newDeleteMessagesAfterMilliseconds');
  @override
  late final GeneratedColumn<int> newDeleteMessagesAfterMilliseconds =
      GeneratedColumn<int>(
          'new_delete_messages_after_milliseconds', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<GroupActionType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<GroupActionType>($GroupHistoriesTable.$convertertype);
  static const VerificationMeta _actionAtMeta =
      const VerificationMeta('actionAt');
  @override
  late final GeneratedColumn<DateTime> actionAt = GeneratedColumn<DateTime>(
      'action_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        groupHistoryId,
        groupId,
        contactId,
        affectedContactId,
        oldGroupName,
        newGroupName,
        newDeleteMessagesAfterMilliseconds,
        type,
        actionAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_histories';
  @override
  VerificationContext validateIntegrity(Insertable<GroupHistory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_history_id')) {
      context.handle(
          _groupHistoryIdMeta,
          groupHistoryId.isAcceptableOrUnknown(
              data['group_history_id']!, _groupHistoryIdMeta));
    } else if (isInserting) {
      context.missing(_groupHistoryIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(_contactIdMeta,
          contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta));
    }
    if (data.containsKey('affected_contact_id')) {
      context.handle(
          _affectedContactIdMeta,
          affectedContactId.isAcceptableOrUnknown(
              data['affected_contact_id']!, _affectedContactIdMeta));
    }
    if (data.containsKey('old_group_name')) {
      context.handle(
          _oldGroupNameMeta,
          oldGroupName.isAcceptableOrUnknown(
              data['old_group_name']!, _oldGroupNameMeta));
    }
    if (data.containsKey('new_group_name')) {
      context.handle(
          _newGroupNameMeta,
          newGroupName.isAcceptableOrUnknown(
              data['new_group_name']!, _newGroupNameMeta));
    }
    if (data.containsKey('new_delete_messages_after_milliseconds')) {
      context.handle(
          _newDeleteMessagesAfterMillisecondsMeta,
          newDeleteMessagesAfterMilliseconds.isAcceptableOrUnknown(
              data['new_delete_messages_after_milliseconds']!,
              _newDeleteMessagesAfterMillisecondsMeta));
    }
    if (data.containsKey('action_at')) {
      context.handle(_actionAtMeta,
          actionAt.isAcceptableOrUnknown(data['action_at']!, _actionAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupHistoryId};
  @override
  GroupHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupHistory(
      groupHistoryId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}group_history_id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id']),
      affectedContactId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}affected_contact_id']),
      oldGroupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}old_group_name']),
      newGroupName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_group_name']),
      newDeleteMessagesAfterMilliseconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}new_delete_messages_after_milliseconds']),
      type: $GroupHistoriesTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      actionAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}action_at'])!,
    );
  }

  @override
  $GroupHistoriesTable createAlias(String alias) {
    return $GroupHistoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GroupActionType, String, String> $convertertype =
      const EnumNameConverter<GroupActionType>(GroupActionType.values);
}

class GroupHistory extends DataClass implements Insertable<GroupHistory> {
  final String groupHistoryId;
  final String groupId;
  final int? contactId;
  final int? affectedContactId;
  final String? oldGroupName;
  final String? newGroupName;
  final int? newDeleteMessagesAfterMilliseconds;
  final GroupActionType type;
  final DateTime actionAt;
  const GroupHistory(
      {required this.groupHistoryId,
      required this.groupId,
      this.contactId,
      this.affectedContactId,
      this.oldGroupName,
      this.newGroupName,
      this.newDeleteMessagesAfterMilliseconds,
      required this.type,
      required this.actionAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_history_id'] = Variable<String>(groupHistoryId);
    map['group_id'] = Variable<String>(groupId);
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<int>(contactId);
    }
    if (!nullToAbsent || affectedContactId != null) {
      map['affected_contact_id'] = Variable<int>(affectedContactId);
    }
    if (!nullToAbsent || oldGroupName != null) {
      map['old_group_name'] = Variable<String>(oldGroupName);
    }
    if (!nullToAbsent || newGroupName != null) {
      map['new_group_name'] = Variable<String>(newGroupName);
    }
    if (!nullToAbsent || newDeleteMessagesAfterMilliseconds != null) {
      map['new_delete_messages_after_milliseconds'] =
          Variable<int>(newDeleteMessagesAfterMilliseconds);
    }
    {
      map['type'] =
          Variable<String>($GroupHistoriesTable.$convertertype.toSql(type));
    }
    map['action_at'] = Variable<DateTime>(actionAt);
    return map;
  }

  GroupHistoriesCompanion toCompanion(bool nullToAbsent) {
    return GroupHistoriesCompanion(
      groupHistoryId: Value(groupHistoryId),
      groupId: Value(groupId),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      affectedContactId: affectedContactId == null && nullToAbsent
          ? const Value.absent()
          : Value(affectedContactId),
      oldGroupName: oldGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(oldGroupName),
      newGroupName: newGroupName == null && nullToAbsent
          ? const Value.absent()
          : Value(newGroupName),
      newDeleteMessagesAfterMilliseconds:
          newDeleteMessagesAfterMilliseconds == null && nullToAbsent
              ? const Value.absent()
              : Value(newDeleteMessagesAfterMilliseconds),
      type: Value(type),
      actionAt: Value(actionAt),
    );
  }

  factory GroupHistory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupHistory(
      groupHistoryId: serializer.fromJson<String>(json['groupHistoryId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      contactId: serializer.fromJson<int?>(json['contactId']),
      affectedContactId: serializer.fromJson<int?>(json['affectedContactId']),
      oldGroupName: serializer.fromJson<String?>(json['oldGroupName']),
      newGroupName: serializer.fromJson<String?>(json['newGroupName']),
      newDeleteMessagesAfterMilliseconds:
          serializer.fromJson<int?>(json['newDeleteMessagesAfterMilliseconds']),
      type: $GroupHistoriesTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      actionAt: serializer.fromJson<DateTime>(json['actionAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupHistoryId': serializer.toJson<String>(groupHistoryId),
      'groupId': serializer.toJson<String>(groupId),
      'contactId': serializer.toJson<int?>(contactId),
      'affectedContactId': serializer.toJson<int?>(affectedContactId),
      'oldGroupName': serializer.toJson<String?>(oldGroupName),
      'newGroupName': serializer.toJson<String?>(newGroupName),
      'newDeleteMessagesAfterMilliseconds':
          serializer.toJson<int?>(newDeleteMessagesAfterMilliseconds),
      'type': serializer
          .toJson<String>($GroupHistoriesTable.$convertertype.toJson(type)),
      'actionAt': serializer.toJson<DateTime>(actionAt),
    };
  }

  GroupHistory copyWith(
          {String? groupHistoryId,
          String? groupId,
          Value<int?> contactId = const Value.absent(),
          Value<int?> affectedContactId = const Value.absent(),
          Value<String?> oldGroupName = const Value.absent(),
          Value<String?> newGroupName = const Value.absent(),
          Value<int?> newDeleteMessagesAfterMilliseconds = const Value.absent(),
          GroupActionType? type,
          DateTime? actionAt}) =>
      GroupHistory(
        groupHistoryId: groupHistoryId ?? this.groupHistoryId,
        groupId: groupId ?? this.groupId,
        contactId: contactId.present ? contactId.value : this.contactId,
        affectedContactId: affectedContactId.present
            ? affectedContactId.value
            : this.affectedContactId,
        oldGroupName:
            oldGroupName.present ? oldGroupName.value : this.oldGroupName,
        newGroupName:
            newGroupName.present ? newGroupName.value : this.newGroupName,
        newDeleteMessagesAfterMilliseconds:
            newDeleteMessagesAfterMilliseconds.present
                ? newDeleteMessagesAfterMilliseconds.value
                : this.newDeleteMessagesAfterMilliseconds,
        type: type ?? this.type,
        actionAt: actionAt ?? this.actionAt,
      );
  GroupHistory copyWithCompanion(GroupHistoriesCompanion data) {
    return GroupHistory(
      groupHistoryId: data.groupHistoryId.present
          ? data.groupHistoryId.value
          : this.groupHistoryId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      affectedContactId: data.affectedContactId.present
          ? data.affectedContactId.value
          : this.affectedContactId,
      oldGroupName: data.oldGroupName.present
          ? data.oldGroupName.value
          : this.oldGroupName,
      newGroupName: data.newGroupName.present
          ? data.newGroupName.value
          : this.newGroupName,
      newDeleteMessagesAfterMilliseconds:
          data.newDeleteMessagesAfterMilliseconds.present
              ? data.newDeleteMessagesAfterMilliseconds.value
              : this.newDeleteMessagesAfterMilliseconds,
      type: data.type.present ? data.type.value : this.type,
      actionAt: data.actionAt.present ? data.actionAt.value : this.actionAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupHistory(')
          ..write('groupHistoryId: $groupHistoryId, ')
          ..write('groupId: $groupId, ')
          ..write('contactId: $contactId, ')
          ..write('affectedContactId: $affectedContactId, ')
          ..write('oldGroupName: $oldGroupName, ')
          ..write('newGroupName: $newGroupName, ')
          ..write(
              'newDeleteMessagesAfterMilliseconds: $newDeleteMessagesAfterMilliseconds, ')
          ..write('type: $type, ')
          ..write('actionAt: $actionAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      groupHistoryId,
      groupId,
      contactId,
      affectedContactId,
      oldGroupName,
      newGroupName,
      newDeleteMessagesAfterMilliseconds,
      type,
      actionAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupHistory &&
          other.groupHistoryId == this.groupHistoryId &&
          other.groupId == this.groupId &&
          other.contactId == this.contactId &&
          other.affectedContactId == this.affectedContactId &&
          other.oldGroupName == this.oldGroupName &&
          other.newGroupName == this.newGroupName &&
          other.newDeleteMessagesAfterMilliseconds ==
              this.newDeleteMessagesAfterMilliseconds &&
          other.type == this.type &&
          other.actionAt == this.actionAt);
}

class GroupHistoriesCompanion extends UpdateCompanion<GroupHistory> {
  final Value<String> groupHistoryId;
  final Value<String> groupId;
  final Value<int?> contactId;
  final Value<int?> affectedContactId;
  final Value<String?> oldGroupName;
  final Value<String?> newGroupName;
  final Value<int?> newDeleteMessagesAfterMilliseconds;
  final Value<GroupActionType> type;
  final Value<DateTime> actionAt;
  final Value<int> rowid;
  const GroupHistoriesCompanion({
    this.groupHistoryId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.affectedContactId = const Value.absent(),
    this.oldGroupName = const Value.absent(),
    this.newGroupName = const Value.absent(),
    this.newDeleteMessagesAfterMilliseconds = const Value.absent(),
    this.type = const Value.absent(),
    this.actionAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupHistoriesCompanion.insert({
    required String groupHistoryId,
    required String groupId,
    this.contactId = const Value.absent(),
    this.affectedContactId = const Value.absent(),
    this.oldGroupName = const Value.absent(),
    this.newGroupName = const Value.absent(),
    this.newDeleteMessagesAfterMilliseconds = const Value.absent(),
    required GroupActionType type,
    this.actionAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : groupHistoryId = Value(groupHistoryId),
        groupId = Value(groupId),
        type = Value(type);
  static Insertable<GroupHistory> custom({
    Expression<String>? groupHistoryId,
    Expression<String>? groupId,
    Expression<int>? contactId,
    Expression<int>? affectedContactId,
    Expression<String>? oldGroupName,
    Expression<String>? newGroupName,
    Expression<int>? newDeleteMessagesAfterMilliseconds,
    Expression<String>? type,
    Expression<DateTime>? actionAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupHistoryId != null) 'group_history_id': groupHistoryId,
      if (groupId != null) 'group_id': groupId,
      if (contactId != null) 'contact_id': contactId,
      if (affectedContactId != null) 'affected_contact_id': affectedContactId,
      if (oldGroupName != null) 'old_group_name': oldGroupName,
      if (newGroupName != null) 'new_group_name': newGroupName,
      if (newDeleteMessagesAfterMilliseconds != null)
        'new_delete_messages_after_milliseconds':
            newDeleteMessagesAfterMilliseconds,
      if (type != null) 'type': type,
      if (actionAt != null) 'action_at': actionAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupHistoriesCompanion copyWith(
      {Value<String>? groupHistoryId,
      Value<String>? groupId,
      Value<int?>? contactId,
      Value<int?>? affectedContactId,
      Value<String?>? oldGroupName,
      Value<String?>? newGroupName,
      Value<int?>? newDeleteMessagesAfterMilliseconds,
      Value<GroupActionType>? type,
      Value<DateTime>? actionAt,
      Value<int>? rowid}) {
    return GroupHistoriesCompanion(
      groupHistoryId: groupHistoryId ?? this.groupHistoryId,
      groupId: groupId ?? this.groupId,
      contactId: contactId ?? this.contactId,
      affectedContactId: affectedContactId ?? this.affectedContactId,
      oldGroupName: oldGroupName ?? this.oldGroupName,
      newGroupName: newGroupName ?? this.newGroupName,
      newDeleteMessagesAfterMilliseconds: newDeleteMessagesAfterMilliseconds ??
          this.newDeleteMessagesAfterMilliseconds,
      type: type ?? this.type,
      actionAt: actionAt ?? this.actionAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupHistoryId.present) {
      map['group_history_id'] = Variable<String>(groupHistoryId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (affectedContactId.present) {
      map['affected_contact_id'] = Variable<int>(affectedContactId.value);
    }
    if (oldGroupName.present) {
      map['old_group_name'] = Variable<String>(oldGroupName.value);
    }
    if (newGroupName.present) {
      map['new_group_name'] = Variable<String>(newGroupName.value);
    }
    if (newDeleteMessagesAfterMilliseconds.present) {
      map['new_delete_messages_after_milliseconds'] =
          Variable<int>(newDeleteMessagesAfterMilliseconds.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
          $GroupHistoriesTable.$convertertype.toSql(type.value));
    }
    if (actionAt.present) {
      map['action_at'] = Variable<DateTime>(actionAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupHistoriesCompanion(')
          ..write('groupHistoryId: $groupHistoryId, ')
          ..write('groupId: $groupId, ')
          ..write('contactId: $contactId, ')
          ..write('affectedContactId: $affectedContactId, ')
          ..write('oldGroupName: $oldGroupName, ')
          ..write('newGroupName: $newGroupName, ')
          ..write(
              'newDeleteMessagesAfterMilliseconds: $newDeleteMessagesAfterMilliseconds, ')
          ..write('type: $type, ')
          ..write('actionAt: $actionAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TwonlyDB extends GeneratedDatabase {
  _$TwonlyDB(QueryExecutor e) : super(e);
  $TwonlyDBManager get managers => $TwonlyDBManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $MediaFilesTable mediaFiles = $MediaFilesTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageHistoriesTable messageHistories =
      $MessageHistoriesTable(this);
  late final $ReactionsTable reactions = $ReactionsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $ReceivedReceiptsTable receivedReceipts =
      $ReceivedReceiptsTable(this);
  late final $SignalIdentityKeyStoresTable signalIdentityKeyStores =
      $SignalIdentityKeyStoresTable(this);
  late final $SignalPreKeyStoresTable signalPreKeyStores =
      $SignalPreKeyStoresTable(this);
  late final $SignalSenderKeyStoresTable signalSenderKeyStores =
      $SignalSenderKeyStoresTable(this);
  late final $SignalSessionStoresTable signalSessionStores =
      $SignalSessionStoresTable(this);
  late final $SignalContactPreKeysTable signalContactPreKeys =
      $SignalContactPreKeysTable(this);
  late final $SignalContactSignedPreKeysTable signalContactSignedPreKeys =
      $SignalContactSignedPreKeysTable(this);
  late final $MessageActionsTable messageActions = $MessageActionsTable(this);
  late final $GroupHistoriesTable groupHistories = $GroupHistoriesTable(this);
  late final MessagesDao messagesDao = MessagesDao(this as TwonlyDB);
  late final ContactsDao contactsDao = ContactsDao(this as TwonlyDB);
  late final SignalDao signalDao = SignalDao(this as TwonlyDB);
  late final ReceiptsDao receiptsDao = ReceiptsDao(this as TwonlyDB);
  late final GroupsDao groupsDao = GroupsDao(this as TwonlyDB);
  late final ReactionsDao reactionsDao = ReactionsDao(this as TwonlyDB);
  late final MediaFilesDao mediaFilesDao = MediaFilesDao(this as TwonlyDB);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        contacts,
        groups,
        mediaFiles,
        messages,
        messageHistories,
        reactions,
        groupMembers,
        receipts,
        receivedReceipts,
        signalIdentityKeyStores,
        signalPreKeyStores,
        signalSenderKeyStores,
        signalSessionStores,
        signalContactPreKeys,
        signalContactSignedPreKeys,
        messageActions,
        groupHistories
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('groups',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('messages', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('media_files',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('messages', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('messages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('message_histories', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('contacts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('message_histories', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('messages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('contacts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('groups',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('group_members', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('contacts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('receipts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('messages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('receipts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('contacts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('signal_contact_pre_keys', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('contacts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('signal_contact_signed_pre_keys',
                  kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('messages',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('message_actions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('contacts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('message_actions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('groups',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('group_histories', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  Value<int> userId,
  required String username,
  Value<String?> displayName,
  Value<String?> nickName,
  Value<Uint8List?> avatarSvgCompressed,
  Value<int> senderProfileCounter,
  Value<bool> accepted,
  Value<bool> deletedByUser,
  Value<bool> requested,
  Value<bool> blocked,
  Value<bool> verified,
  Value<bool> accountDeleted,
  Value<DateTime> createdAt,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<int> userId,
  Value<String> username,
  Value<String?> displayName,
  Value<String?> nickName,
  Value<Uint8List?> avatarSvgCompressed,
  Value<int> senderProfileCounter,
  Value<bool> accepted,
  Value<bool> deletedByUser,
  Value<bool> requested,
  Value<bool> blocked,
  Value<bool> verified,
  Value<bool> accountDeleted,
  Value<DateTime> createdAt,
});

final class $$ContactsTableReferences
    extends BaseReferences<_$TwonlyDB, $ContactsTable, Contact> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
          _$TwonlyDB db) =>
      MultiTypedResultKey.fromTable(db.messages,
          aliasName:
              $_aliasNameGenerator(db.contacts.userId, db.messages.senderId));

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages).filter(
        (f) => f.senderId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MessageHistoriesTable, List<MessageHistory>>
      _messageHistoriesRefsTable(_$TwonlyDB db) =>
          MultiTypedResultKey.fromTable(db.messageHistories,
              aliasName: $_aliasNameGenerator(
                  db.contacts.userId, db.messageHistories.contactId));

  $$MessageHistoriesTableProcessedTableManager get messageHistoriesRefs {
    final manager =
        $$MessageHistoriesTableTableManager($_db, $_db.messageHistories).filter(
            (f) => f.contactId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache =
        $_typedResult.readTableOrNull(_messageHistoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReactionsTable, List<Reaction>>
      _reactionsRefsTable(_$TwonlyDB db) => MultiTypedResultKey.fromTable(
          db.reactions,
          aliasName:
              $_aliasNameGenerator(db.contacts.userId, db.reactions.senderId));

  $$ReactionsTableProcessedTableManager get reactionsRefs {
    final manager = $$ReactionsTableTableManager($_db, $_db.reactions).filter(
        (f) => f.senderId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_reactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
      _groupMembersRefsTable(_$TwonlyDB db) =>
          MultiTypedResultKey.fromTable(db.groupMembers,
              aliasName: $_aliasNameGenerator(
                  db.contacts.userId, db.groupMembers.contactId));

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager($_db, $_db.groupMembers)
        .filter(
            (f) => f.contactId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReceiptsTable, List<Receipt>> _receiptsRefsTable(
          _$TwonlyDB db) =>
      MultiTypedResultKey.fromTable(db.receipts,
          aliasName:
              $_aliasNameGenerator(db.contacts.userId, db.receipts.contactId));

  $$ReceiptsTableProcessedTableManager get receiptsRefs {
    final manager = $$ReceiptsTableTableManager($_db, $_db.receipts).filter(
        (f) => f.contactId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_receiptsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SignalContactPreKeysTable,
      List<SignalContactPreKey>> _signalContactPreKeysRefsTable(
          _$TwonlyDB db) =>
      MultiTypedResultKey.fromTable(db.signalContactPreKeys,
          aliasName: $_aliasNameGenerator(
              db.contacts.userId, db.signalContactPreKeys.contactId));

  $$SignalContactPreKeysTableProcessedTableManager
      get signalContactPreKeysRefs {
    final manager = $$SignalContactPreKeysTableTableManager(
            $_db, $_db.signalContactPreKeys)
        .filter(
            (f) => f.contactId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache =
        $_typedResult.readTableOrNull(_signalContactPreKeysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SignalContactSignedPreKeysTable,
      List<SignalContactSignedPreKey>> _signalContactSignedPreKeysRefsTable(
          _$TwonlyDB db) =>
      MultiTypedResultKey.fromTable(db.signalContactSignedPreKeys,
          aliasName: $_aliasNameGenerator(
              db.contacts.userId, db.signalContactSignedPreKeys.contactId));

  $$SignalContactSignedPreKeysTableProcessedTableManager
      get signalContactSignedPreKeysRefs {
    final manager = $$SignalContactSignedPreKeysTableTableManager(
            $_db, $_db.signalContactSignedPreKeys)
        .filter(
            (f) => f.contactId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult
        .readTableOrNull(_signalContactSignedPreKeysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MessageActionsTable, List<MessageAction>>
      _messageActionsRefsTable(_$TwonlyDB db) =>
          MultiTypedResultKey.fromTable(db.messageActions,
              aliasName: $_aliasNameGenerator(
                  db.contacts.userId, db.messageActions.contactId));

  $$MessageActionsTableProcessedTableManager get messageActionsRefs {
    final manager = $$MessageActionsTableTableManager($_db, $_db.messageActions)
        .filter(
            (f) => f.contactId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_messageActionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GroupHistoriesTable, List<GroupHistory>>
      _groupHistoriesRefsTable(_$TwonlyDB db) =>
          MultiTypedResultKey.fromTable(db.groupHistories,
              aliasName: $_aliasNameGenerator(
                  db.contacts.userId, db.groupHistories.contactId));

  $$GroupHistoriesTableProcessedTableManager get groupHistoriesRefs {
    final manager = $$GroupHistoriesTableTableManager($_db, $_db.groupHistories)
        .filter(
            (f) => f.contactId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_groupHistoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$TwonlyDB, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nickName => $composableBuilder(
      column: $table.nickName, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get avatarSvgCompressed => $composableBuilder(
      column: $table.avatarSvgCompressed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get senderProfileCounter => $composableBuilder(
      column: $table.senderProfileCounter,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get accepted => $composableBuilder(
      column: $table.accepted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deletedByUser => $composableBuilder(
      column: $table.deletedByUser, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requested => $composableBuilder(
      column: $table.requested, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get blocked => $composableBuilder(
      column: $table.blocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get verified => $composableBuilder(
      column: $table.verified, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get accountDeleted => $composableBuilder(
      column: $table.accountDeleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> messagesRefs(
      Expression<bool> Function($$MessagesTableFilterComposer f) f) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.senderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> messageHistoriesRefs(
      Expression<bool> Function($$MessageHistoriesTableFilterComposer f) f) {
    final $$MessageHistoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.messageHistories,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessageHistoriesTableFilterComposer(
              $db: $db,
              $table: $db.messageHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> reactionsRefs(
      Expression<bool> Function($$ReactionsTableFilterComposer f) f) {
    final $$ReactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.reactions,
        getReferencedColumn: (t) => t.senderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReactionsTableFilterComposer(
              $db: $db,
              $table: $db.reactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> groupMembersRefs(
      Expression<bool> Function($$GroupMembersTableFilterComposer f) f) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableFilterComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> receiptsRefs(
      Expression<bool> Function($$ReceiptsTableFilterComposer f) f) {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.receipts,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReceiptsTableFilterComposer(
              $db: $db,
              $table: $db.receipts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> signalContactPreKeysRefs(
      Expression<bool> Function($$SignalContactPreKeysTableFilterComposer f)
          f) {
    final $$SignalContactPreKeysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.signalContactPreKeys,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SignalContactPreKeysTableFilterComposer(
              $db: $db,
              $table: $db.signalContactPreKeys,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> signalContactSignedPreKeysRefs(
      Expression<bool> Function(
              $$SignalContactSignedPreKeysTableFilterComposer f)
          f) {
    final $$SignalContactSignedPreKeysTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.userId,
            referencedTable: $db.signalContactSignedPreKeys,
            getReferencedColumn: (t) => t.contactId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SignalContactSignedPreKeysTableFilterComposer(
                  $db: $db,
                  $table: $db.signalContactSignedPreKeys,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> messageActionsRefs(
      Expression<bool> Function($$MessageActionsTableFilterComposer f) f) {
    final $$MessageActionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.messageActions,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessageActionsTableFilterComposer(
              $db: $db,
              $table: $db.messageActions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> groupHistoriesRefs(
      Expression<bool> Function($$GroupHistoriesTableFilterComposer f) f) {
    final $$GroupHistoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.groupHistories,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupHistoriesTableFilterComposer(
              $db: $db,
              $table: $db.groupHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends Composer<_$TwonlyDB, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nickName => $composableBuilder(
      column: $table.nickName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get avatarSvgCompressed => $composableBuilder(
      column: $table.avatarSvgCompressed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get senderProfileCounter => $composableBuilder(
      column: $table.senderProfileCounter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get accepted => $composableBuilder(
      column: $table.accepted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deletedByUser => $composableBuilder(
      column: $table.deletedByUser,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requested => $composableBuilder(
      column: $table.requested, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get blocked => $composableBuilder(
      column: $table.blocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get verified => $composableBuilder(
      column: $table.verified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get accountDeleted => $composableBuilder(
      column: $table.accountDeleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$TwonlyDB, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get nickName =>
      $composableBuilder(column: $table.nickName, builder: (column) => column);

  GeneratedColumn<Uint8List> get avatarSvgCompressed => $composableBuilder(
      column: $table.avatarSvgCompressed, builder: (column) => column);

  GeneratedColumn<int> get senderProfileCounter => $composableBuilder(
      column: $table.senderProfileCounter, builder: (column) => column);

  GeneratedColumn<bool> get accepted =>
      $composableBuilder(column: $table.accepted, builder: (column) => column);

  GeneratedColumn<bool> get deletedByUser => $composableBuilder(
      column: $table.deletedByUser, builder: (column) => column);

  GeneratedColumn<bool> get requested =>
      $composableBuilder(column: $table.requested, builder: (column) => column);

  GeneratedColumn<bool> get blocked =>
      $composableBuilder(column: $table.blocked, builder: (column) => column);

  GeneratedColumn<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  GeneratedColumn<bool> get accountDeleted => $composableBuilder(
      column: $table.accountDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> messagesRefs<T extends Object>(
      Expression<T> Function($$MessagesTableAnnotationComposer a) f) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.senderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> messageHistoriesRefs<T extends Object>(
      Expression<T> Function($$MessageHistoriesTableAnnotationComposer a) f) {
    final $$MessageHistoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.messageHistories,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessageHistoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.messageHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> reactionsRefs<T extends Object>(
      Expression<T> Function($$ReactionsTableAnnotationComposer a) f) {
    final $$ReactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.reactions,
        getReferencedColumn: (t) => t.senderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.reactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> groupMembersRefs<T extends Object>(
      Expression<T> Function($$GroupMembersTableAnnotationComposer a) f) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> receiptsRefs<T extends Object>(
      Expression<T> Function($$ReceiptsTableAnnotationComposer a) f) {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.receipts,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReceiptsTableAnnotationComposer(
              $db: $db,
              $table: $db.receipts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> signalContactPreKeysRefs<T extends Object>(
      Expression<T> Function($$SignalContactPreKeysTableAnnotationComposer a)
          f) {
    final $$SignalContactPreKeysTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.userId,
            referencedTable: $db.signalContactPreKeys,
            getReferencedColumn: (t) => t.contactId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SignalContactPreKeysTableAnnotationComposer(
                  $db: $db,
                  $table: $db.signalContactPreKeys,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> signalContactSignedPreKeysRefs<T extends Object>(
      Expression<T> Function(
              $$SignalContactSignedPreKeysTableAnnotationComposer a)
          f) {
    final $$SignalContactSignedPreKeysTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.userId,
            referencedTable: $db.signalContactSignedPreKeys,
            getReferencedColumn: (t) => t.contactId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SignalContactSignedPreKeysTableAnnotationComposer(
                  $db: $db,
                  $table: $db.signalContactSignedPreKeys,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> messageActionsRefs<T extends Object>(
      Expression<T> Function($$MessageActionsTableAnnotationComposer a) f) {
    final $$MessageActionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.messageActions,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessageActionsTableAnnotationComposer(
              $db: $db,
              $table: $db.messageActions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> groupHistoriesRefs<T extends Object>(
      Expression<T> Function($$GroupHistoriesTableAnnotationComposer a) f) {
    final $$GroupHistoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.groupHistories,
        getReferencedColumn: (t) => t.contactId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupHistoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.groupHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ContactsTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableAnnotationComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder,
    (Contact, $$ContactsTableReferences),
    Contact,
    PrefetchHooks Function(
        {bool messagesRefs,
        bool messageHistoriesRefs,
        bool reactionsRefs,
        bool groupMembersRefs,
        bool receiptsRefs,
        bool signalContactPreKeysRefs,
        bool signalContactSignedPreKeysRefs,
        bool messageActionsRefs,
        bool groupHistoriesRefs})> {
  $$ContactsTableTableManager(_$TwonlyDB db, $ContactsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<String?> nickName = const Value.absent(),
            Value<Uint8List?> avatarSvgCompressed = const Value.absent(),
            Value<int> senderProfileCounter = const Value.absent(),
            Value<bool> accepted = const Value.absent(),
            Value<bool> deletedByUser = const Value.absent(),
            Value<bool> requested = const Value.absent(),
            Value<bool> blocked = const Value.absent(),
            Value<bool> verified = const Value.absent(),
            Value<bool> accountDeleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ContactsCompanion(
            userId: userId,
            username: username,
            displayName: displayName,
            nickName: nickName,
            avatarSvgCompressed: avatarSvgCompressed,
            senderProfileCounter: senderProfileCounter,
            accepted: accepted,
            deletedByUser: deletedByUser,
            requested: requested,
            blocked: blocked,
            verified: verified,
            accountDeleted: accountDeleted,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            required String username,
            Value<String?> displayName = const Value.absent(),
            Value<String?> nickName = const Value.absent(),
            Value<Uint8List?> avatarSvgCompressed = const Value.absent(),
            Value<int> senderProfileCounter = const Value.absent(),
            Value<bool> accepted = const Value.absent(),
            Value<bool> deletedByUser = const Value.absent(),
            Value<bool> requested = const Value.absent(),
            Value<bool> blocked = const Value.absent(),
            Value<bool> verified = const Value.absent(),
            Value<bool> accountDeleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ContactsCompanion.insert(
            userId: userId,
            username: username,
            displayName: displayName,
            nickName: nickName,
            avatarSvgCompressed: avatarSvgCompressed,
            senderProfileCounter: senderProfileCounter,
            accepted: accepted,
            deletedByUser: deletedByUser,
            requested: requested,
            blocked: blocked,
            verified: verified,
            accountDeleted: accountDeleted,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ContactsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {messagesRefs = false,
              messageHistoriesRefs = false,
              reactionsRefs = false,
              groupMembersRefs = false,
              receiptsRefs = false,
              signalContactPreKeysRefs = false,
              signalContactSignedPreKeysRefs = false,
              messageActionsRefs = false,
              groupHistoriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (messagesRefs) db.messages,
                if (messageHistoriesRefs) db.messageHistories,
                if (reactionsRefs) db.reactions,
                if (groupMembersRefs) db.groupMembers,
                if (receiptsRefs) db.receipts,
                if (signalContactPreKeysRefs) db.signalContactPreKeys,
                if (signalContactSignedPreKeysRefs)
                  db.signalContactSignedPreKeys,
                if (messageActionsRefs) db.messageActions,
                if (groupHistoriesRefs) db.groupHistories
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable, Message>(
                        currentTable: table,
                        referencedTable:
                            $$ContactsTableReferences._messagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .messagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.senderId == item.userId),
                        typedResults: items),
                  if (messageHistoriesRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable,
                            MessageHistory>(
                        currentTable: table,
                        referencedTable: $$ContactsTableReferences
                            ._messageHistoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .messageHistoriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contactId == item.userId),
                        typedResults: items),
                  if (reactionsRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable,
                            Reaction>(
                        currentTable: table,
                        referencedTable:
                            $$ContactsTableReferences._reactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .reactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.senderId == item.userId),
                        typedResults: items),
                  if (groupMembersRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable,
                            GroupMember>(
                        currentTable: table,
                        referencedTable: $$ContactsTableReferences
                            ._groupMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .groupMembersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contactId == item.userId),
                        typedResults: items),
                  if (receiptsRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable, Receipt>(
                        currentTable: table,
                        referencedTable:
                            $$ContactsTableReferences._receiptsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .receiptsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contactId == item.userId),
                        typedResults: items),
                  if (signalContactPreKeysRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable,
                            SignalContactPreKey>(
                        currentTable: table,
                        referencedTable: $$ContactsTableReferences
                            ._signalContactPreKeysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .signalContactPreKeysRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contactId == item.userId),
                        typedResults: items),
                  if (signalContactSignedPreKeysRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable,
                            SignalContactSignedPreKey>(
                        currentTable: table,
                        referencedTable: $$ContactsTableReferences
                            ._signalContactSignedPreKeysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .signalContactSignedPreKeysRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contactId == item.userId),
                        typedResults: items),
                  if (messageActionsRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable,
                            MessageAction>(
                        currentTable: table,
                        referencedTable: $$ContactsTableReferences
                            ._messageActionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .messageActionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contactId == item.userId),
                        typedResults: items),
                  if (groupHistoriesRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable,
                            GroupHistory>(
                        currentTable: table,
                        referencedTable: $$ContactsTableReferences
                            ._groupHistoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContactsTableReferences(db, table, p0)
                                .groupHistoriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contactId == item.userId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ContactsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableAnnotationComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder,
    (Contact, $$ContactsTableReferences),
    Contact,
    PrefetchHooks Function(
        {bool messagesRefs,
        bool messageHistoriesRefs,
        bool reactionsRefs,
        bool groupMembersRefs,
        bool receiptsRefs,
        bool signalContactPreKeysRefs,
        bool signalContactSignedPreKeysRefs,
        bool messageActionsRefs,
        bool groupHistoriesRefs})>;
typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  required String groupId,
  Value<bool> isGroupAdmin,
  Value<bool> isDirectChat,
  Value<bool> pinned,
  Value<bool> archived,
  Value<bool> joinedGroup,
  Value<bool> leftGroup,
  Value<bool> deletedContent,
  Value<int> stateVersionId,
  Value<Uint8List?> stateEncryptionKey,
  Value<Uint8List?> myGroupPrivateKey,
  required String groupName,
  Value<String?> draftMessage,
  Value<int> totalMediaCounter,
  Value<bool> alsoBestFriend,
  Value<int> deleteMessagesAfterMilliseconds,
  Value<DateTime> createdAt,
  Value<DateTime?> lastMessageSend,
  Value<DateTime?> lastMessageReceived,
  Value<DateTime?> lastFlameCounterChange,
  Value<DateTime?> lastFlameSync,
  Value<int> flameCounter,
  Value<int> maxFlameCounter,
  Value<DateTime?> maxFlameCounterFrom,
  Value<DateTime> lastMessageExchange,
  Value<int> rowid,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<String> groupId,
  Value<bool> isGroupAdmin,
  Value<bool> isDirectChat,
  Value<bool> pinned,
  Value<bool> archived,
  Value<bool> joinedGroup,
  Value<bool> leftGroup,
  Value<bool> deletedContent,
  Value<int> stateVersionId,
  Value<Uint8List?> stateEncryptionKey,
  Value<Uint8List?> myGroupPrivateKey,
  Value<String> groupName,
  Value<String?> draftMessage,
  Value<int> totalMediaCounter,
  Value<bool> alsoBestFriend,
  Value<int> deleteMessagesAfterMilliseconds,
  Value<DateTime> createdAt,
  Value<DateTime?> lastMessageSend,
  Value<DateTime?> lastMessageReceived,
  Value<DateTime?> lastFlameCounterChange,
  Value<DateTime?> lastFlameSync,
  Value<int> flameCounter,
  Value<int> maxFlameCounter,
  Value<DateTime?> maxFlameCounterFrom,
  Value<DateTime> lastMessageExchange,
  Value<int> rowid,
});

final class $$GroupsTableReferences
    extends BaseReferences<_$TwonlyDB, $GroupsTable, Group> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
          _$TwonlyDB db) =>
      MultiTypedResultKey.fromTable(db.messages,
          aliasName:
              $_aliasNameGenerator(db.groups.groupId, db.messages.groupId));

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages).filter(
        (f) => f.groupId.groupId.sqlEquals($_itemColumn<String>('group_id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
      _groupMembersRefsTable(_$TwonlyDB db) => MultiTypedResultKey.fromTable(
          db.groupMembers,
          aliasName:
              $_aliasNameGenerator(db.groups.groupId, db.groupMembers.groupId));

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager($_db, $_db.groupMembers)
        .filter((f) =>
            f.groupId.groupId.sqlEquals($_itemColumn<String>('group_id')!));

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GroupHistoriesTable, List<GroupHistory>>
      _groupHistoriesRefsTable(_$TwonlyDB db) =>
          MultiTypedResultKey.fromTable(db.groupHistories,
              aliasName: $_aliasNameGenerator(
                  db.groups.groupId, db.groupHistories.groupId));

  $$GroupHistoriesTableProcessedTableManager get groupHistoriesRefs {
    final manager = $$GroupHistoriesTableTableManager($_db, $_db.groupHistories)
        .filter((f) =>
            f.groupId.groupId.sqlEquals($_itemColumn<String>('group_id')!));

    final cache = $_typedResult.readTableOrNull(_groupHistoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GroupsTableFilterComposer extends Composer<_$TwonlyDB, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isGroupAdmin => $composableBuilder(
      column: $table.isGroupAdmin, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDirectChat => $composableBuilder(
      column: $table.isDirectChat, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get joinedGroup => $composableBuilder(
      column: $table.joinedGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get leftGroup => $composableBuilder(
      column: $table.leftGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deletedContent => $composableBuilder(
      column: $table.deletedContent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stateVersionId => $composableBuilder(
      column: $table.stateVersionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get stateEncryptionKey => $composableBuilder(
      column: $table.stateEncryptionKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get myGroupPrivateKey => $composableBuilder(
      column: $table.myGroupPrivateKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get draftMessage => $composableBuilder(
      column: $table.draftMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalMediaCounter => $composableBuilder(
      column: $table.totalMediaCounter,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get alsoBestFriend => $composableBuilder(
      column: $table.alsoBestFriend,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deleteMessagesAfterMilliseconds => $composableBuilder(
      column: $table.deleteMessagesAfterMilliseconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMessageSend => $composableBuilder(
      column: $table.lastMessageSend,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMessageReceived => $composableBuilder(
      column: $table.lastMessageReceived,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastFlameCounterChange => $composableBuilder(
      column: $table.lastFlameCounterChange,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastFlameSync => $composableBuilder(
      column: $table.lastFlameSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get flameCounter => $composableBuilder(
      column: $table.flameCounter, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxFlameCounter => $composableBuilder(
      column: $table.maxFlameCounter,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get maxFlameCounterFrom => $composableBuilder(
      column: $table.maxFlameCounterFrom,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMessageExchange => $composableBuilder(
      column: $table.lastMessageExchange,
      builder: (column) => ColumnFilters(column));

  Expression<bool> messagesRefs(
      Expression<bool> Function($$MessagesTableFilterComposer f) f) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> groupMembersRefs(
      Expression<bool> Function($$GroupMembersTableFilterComposer f) f) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableFilterComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> groupHistoriesRefs(
      Expression<bool> Function($$GroupHistoriesTableFilterComposer f) f) {
    final $$GroupHistoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groupHistories,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupHistoriesTableFilterComposer(
              $db: $db,
              $table: $db.groupHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer extends Composer<_$TwonlyDB, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isGroupAdmin => $composableBuilder(
      column: $table.isGroupAdmin,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDirectChat => $composableBuilder(
      column: $table.isDirectChat,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get joinedGroup => $composableBuilder(
      column: $table.joinedGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get leftGroup => $composableBuilder(
      column: $table.leftGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deletedContent => $composableBuilder(
      column: $table.deletedContent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stateVersionId => $composableBuilder(
      column: $table.stateVersionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get stateEncryptionKey => $composableBuilder(
      column: $table.stateEncryptionKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get myGroupPrivateKey => $composableBuilder(
      column: $table.myGroupPrivateKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupName => $composableBuilder(
      column: $table.groupName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get draftMessage => $composableBuilder(
      column: $table.draftMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalMediaCounter => $composableBuilder(
      column: $table.totalMediaCounter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get alsoBestFriend => $composableBuilder(
      column: $table.alsoBestFriend,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deleteMessagesAfterMilliseconds =>
      $composableBuilder(
          column: $table.deleteMessagesAfterMilliseconds,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMessageSend => $composableBuilder(
      column: $table.lastMessageSend,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMessageReceived => $composableBuilder(
      column: $table.lastMessageReceived,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastFlameCounterChange => $composableBuilder(
      column: $table.lastFlameCounterChange,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastFlameSync => $composableBuilder(
      column: $table.lastFlameSync,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get flameCounter => $composableBuilder(
      column: $table.flameCounter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxFlameCounter => $composableBuilder(
      column: $table.maxFlameCounter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get maxFlameCounterFrom => $composableBuilder(
      column: $table.maxFlameCounterFrom,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMessageExchange => $composableBuilder(
      column: $table.lastMessageExchange,
      builder: (column) => ColumnOrderings(column));
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$TwonlyDB, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<bool> get isGroupAdmin => $composableBuilder(
      column: $table.isGroupAdmin, builder: (column) => column);

  GeneratedColumn<bool> get isDirectChat => $composableBuilder(
      column: $table.isDirectChat, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get joinedGroup => $composableBuilder(
      column: $table.joinedGroup, builder: (column) => column);

  GeneratedColumn<bool> get leftGroup =>
      $composableBuilder(column: $table.leftGroup, builder: (column) => column);

  GeneratedColumn<bool> get deletedContent => $composableBuilder(
      column: $table.deletedContent, builder: (column) => column);

  GeneratedColumn<int> get stateVersionId => $composableBuilder(
      column: $table.stateVersionId, builder: (column) => column);

  GeneratedColumn<Uint8List> get stateEncryptionKey => $composableBuilder(
      column: $table.stateEncryptionKey, builder: (column) => column);

  GeneratedColumn<Uint8List> get myGroupPrivateKey => $composableBuilder(
      column: $table.myGroupPrivateKey, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get draftMessage => $composableBuilder(
      column: $table.draftMessage, builder: (column) => column);

  GeneratedColumn<int> get totalMediaCounter => $composableBuilder(
      column: $table.totalMediaCounter, builder: (column) => column);

  GeneratedColumn<bool> get alsoBestFriend => $composableBuilder(
      column: $table.alsoBestFriend, builder: (column) => column);

  GeneratedColumn<int> get deleteMessagesAfterMilliseconds =>
      $composableBuilder(
          column: $table.deleteMessagesAfterMilliseconds,
          builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageSend => $composableBuilder(
      column: $table.lastMessageSend, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageReceived => $composableBuilder(
      column: $table.lastMessageReceived, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFlameCounterChange => $composableBuilder(
      column: $table.lastFlameCounterChange, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFlameSync => $composableBuilder(
      column: $table.lastFlameSync, builder: (column) => column);

  GeneratedColumn<int> get flameCounter => $composableBuilder(
      column: $table.flameCounter, builder: (column) => column);

  GeneratedColumn<int> get maxFlameCounter => $composableBuilder(
      column: $table.maxFlameCounter, builder: (column) => column);

  GeneratedColumn<DateTime> get maxFlameCounterFrom => $composableBuilder(
      column: $table.maxFlameCounterFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageExchange => $composableBuilder(
      column: $table.lastMessageExchange, builder: (column) => column);

  Expression<T> messagesRefs<T extends Object>(
      Expression<T> Function($$MessagesTableAnnotationComposer a) f) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> groupMembersRefs<T extends Object>(
      Expression<T> Function($$GroupMembersTableAnnotationComposer a) f) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> groupHistoriesRefs<T extends Object>(
      Expression<T> Function($$GroupHistoriesTableAnnotationComposer a) f) {
    final $$GroupHistoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groupHistories,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupHistoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.groupHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GroupsTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $GroupsTable,
    Group,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (Group, $$GroupsTableReferences),
    Group,
    PrefetchHooks Function(
        {bool messagesRefs, bool groupMembersRefs, bool groupHistoriesRefs})> {
  $$GroupsTableTableManager(_$TwonlyDB db, $GroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> groupId = const Value.absent(),
            Value<bool> isGroupAdmin = const Value.absent(),
            Value<bool> isDirectChat = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> joinedGroup = const Value.absent(),
            Value<bool> leftGroup = const Value.absent(),
            Value<bool> deletedContent = const Value.absent(),
            Value<int> stateVersionId = const Value.absent(),
            Value<Uint8List?> stateEncryptionKey = const Value.absent(),
            Value<Uint8List?> myGroupPrivateKey = const Value.absent(),
            Value<String> groupName = const Value.absent(),
            Value<String?> draftMessage = const Value.absent(),
            Value<int> totalMediaCounter = const Value.absent(),
            Value<bool> alsoBestFriend = const Value.absent(),
            Value<int> deleteMessagesAfterMilliseconds = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastMessageSend = const Value.absent(),
            Value<DateTime?> lastMessageReceived = const Value.absent(),
            Value<DateTime?> lastFlameCounterChange = const Value.absent(),
            Value<DateTime?> lastFlameSync = const Value.absent(),
            Value<int> flameCounter = const Value.absent(),
            Value<int> maxFlameCounter = const Value.absent(),
            Value<DateTime?> maxFlameCounterFrom = const Value.absent(),
            Value<DateTime> lastMessageExchange = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion(
            groupId: groupId,
            isGroupAdmin: isGroupAdmin,
            isDirectChat: isDirectChat,
            pinned: pinned,
            archived: archived,
            joinedGroup: joinedGroup,
            leftGroup: leftGroup,
            deletedContent: deletedContent,
            stateVersionId: stateVersionId,
            stateEncryptionKey: stateEncryptionKey,
            myGroupPrivateKey: myGroupPrivateKey,
            groupName: groupName,
            draftMessage: draftMessage,
            totalMediaCounter: totalMediaCounter,
            alsoBestFriend: alsoBestFriend,
            deleteMessagesAfterMilliseconds: deleteMessagesAfterMilliseconds,
            createdAt: createdAt,
            lastMessageSend: lastMessageSend,
            lastMessageReceived: lastMessageReceived,
            lastFlameCounterChange: lastFlameCounterChange,
            lastFlameSync: lastFlameSync,
            flameCounter: flameCounter,
            maxFlameCounter: maxFlameCounter,
            maxFlameCounterFrom: maxFlameCounterFrom,
            lastMessageExchange: lastMessageExchange,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String groupId,
            Value<bool> isGroupAdmin = const Value.absent(),
            Value<bool> isDirectChat = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> joinedGroup = const Value.absent(),
            Value<bool> leftGroup = const Value.absent(),
            Value<bool> deletedContent = const Value.absent(),
            Value<int> stateVersionId = const Value.absent(),
            Value<Uint8List?> stateEncryptionKey = const Value.absent(),
            Value<Uint8List?> myGroupPrivateKey = const Value.absent(),
            required String groupName,
            Value<String?> draftMessage = const Value.absent(),
            Value<int> totalMediaCounter = const Value.absent(),
            Value<bool> alsoBestFriend = const Value.absent(),
            Value<int> deleteMessagesAfterMilliseconds = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastMessageSend = const Value.absent(),
            Value<DateTime?> lastMessageReceived = const Value.absent(),
            Value<DateTime?> lastFlameCounterChange = const Value.absent(),
            Value<DateTime?> lastFlameSync = const Value.absent(),
            Value<int> flameCounter = const Value.absent(),
            Value<int> maxFlameCounter = const Value.absent(),
            Value<DateTime?> maxFlameCounterFrom = const Value.absent(),
            Value<DateTime> lastMessageExchange = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupsCompanion.insert(
            groupId: groupId,
            isGroupAdmin: isGroupAdmin,
            isDirectChat: isDirectChat,
            pinned: pinned,
            archived: archived,
            joinedGroup: joinedGroup,
            leftGroup: leftGroup,
            deletedContent: deletedContent,
            stateVersionId: stateVersionId,
            stateEncryptionKey: stateEncryptionKey,
            myGroupPrivateKey: myGroupPrivateKey,
            groupName: groupName,
            draftMessage: draftMessage,
            totalMediaCounter: totalMediaCounter,
            alsoBestFriend: alsoBestFriend,
            deleteMessagesAfterMilliseconds: deleteMessagesAfterMilliseconds,
            createdAt: createdAt,
            lastMessageSend: lastMessageSend,
            lastMessageReceived: lastMessageReceived,
            lastFlameCounterChange: lastFlameCounterChange,
            lastFlameSync: lastFlameSync,
            flameCounter: flameCounter,
            maxFlameCounter: maxFlameCounter,
            maxFlameCounterFrom: maxFlameCounterFrom,
            lastMessageExchange: lastMessageExchange,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GroupsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {messagesRefs = false,
              groupMembersRefs = false,
              groupHistoriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (messagesRefs) db.messages,
                if (groupMembersRefs) db.groupMembers,
                if (groupHistoriesRefs) db.groupHistories
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedData<Group, $GroupsTable, Message>(
                        currentTable: table,
                        referencedTable:
                            $$GroupsTableReferences._messagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GroupsTableReferences(db, table, p0).messagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.groupId == item.groupId),
                        typedResults: items),
                  if (groupMembersRefs)
                    await $_getPrefetchedData<Group, $GroupsTable, GroupMember>(
                        currentTable: table,
                        referencedTable:
                            $$GroupsTableReferences._groupMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GroupsTableReferences(db, table, p0)
                                .groupMembersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.groupId == item.groupId),
                        typedResults: items),
                  if (groupHistoriesRefs)
                    await $_getPrefetchedData<Group, $GroupsTable,
                            GroupHistory>(
                        currentTable: table,
                        referencedTable: $$GroupsTableReferences
                            ._groupHistoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GroupsTableReferences(db, table, p0)
                                .groupHistoriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.groupId == item.groupId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GroupsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $GroupsTable,
    Group,
    $$GroupsTableFilterComposer,
    $$GroupsTableOrderingComposer,
    $$GroupsTableAnnotationComposer,
    $$GroupsTableCreateCompanionBuilder,
    $$GroupsTableUpdateCompanionBuilder,
    (Group, $$GroupsTableReferences),
    Group,
    PrefetchHooks Function(
        {bool messagesRefs, bool groupMembersRefs, bool groupHistoriesRefs})>;
typedef $$MediaFilesTableCreateCompanionBuilder = MediaFilesCompanion Function({
  required String mediaId,
  required MediaType type,
  Value<UploadState?> uploadState,
  Value<DownloadState?> downloadState,
  Value<bool> requiresAuthentication,
  Value<bool> stored,
  Value<bool> isDraftMedia,
  Value<List<int>?> reuploadRequestedBy,
  Value<int?> displayLimitInMilliseconds,
  Value<bool?> removeAudio,
  Value<Uint8List?> downloadToken,
  Value<Uint8List?> encryptionKey,
  Value<Uint8List?> encryptionMac,
  Value<Uint8List?> encryptionNonce,
  Value<Uint8List?> storedFileHash,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$MediaFilesTableUpdateCompanionBuilder = MediaFilesCompanion Function({
  Value<String> mediaId,
  Value<MediaType> type,
  Value<UploadState?> uploadState,
  Value<DownloadState?> downloadState,
  Value<bool> requiresAuthentication,
  Value<bool> stored,
  Value<bool> isDraftMedia,
  Value<List<int>?> reuploadRequestedBy,
  Value<int?> displayLimitInMilliseconds,
  Value<bool?> removeAudio,
  Value<Uint8List?> downloadToken,
  Value<Uint8List?> encryptionKey,
  Value<Uint8List?> encryptionMac,
  Value<Uint8List?> encryptionNonce,
  Value<Uint8List?> storedFileHash,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$MediaFilesTableReferences
    extends BaseReferences<_$TwonlyDB, $MediaFilesTable, MediaFile> {
  $$MediaFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
          _$TwonlyDB db) =>
      MultiTypedResultKey.fromTable(db.messages,
          aliasName:
              $_aliasNameGenerator(db.mediaFiles.mediaId, db.messages.mediaId));

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages).filter(
        (f) => f.mediaId.mediaId.sqlEquals($_itemColumn<String>('media_id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MediaFilesTableFilterComposer
    extends Composer<_$TwonlyDB, $MediaFilesTable> {
  $$MediaFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<UploadState?, UploadState, String>
      get uploadState => $composableBuilder(
          column: $table.uploadState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<DownloadState?, DownloadState, String>
      get downloadState => $composableBuilder(
          column: $table.downloadState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get requiresAuthentication => $composableBuilder(
      column: $table.requiresAuthentication,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get stored => $composableBuilder(
      column: $table.stored, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDraftMedia => $composableBuilder(
      column: $table.isDraftMedia, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<int>?, List<int>, String>
      get reuploadRequestedBy => $composableBuilder(
          column: $table.reuploadRequestedBy,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get displayLimitInMilliseconds => $composableBuilder(
      column: $table.displayLimitInMilliseconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get removeAudio => $composableBuilder(
      column: $table.removeAudio, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get downloadToken => $composableBuilder(
      column: $table.downloadToken, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get encryptionKey => $composableBuilder(
      column: $table.encryptionKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get encryptionMac => $composableBuilder(
      column: $table.encryptionMac, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get encryptionNonce => $composableBuilder(
      column: $table.encryptionNonce,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get storedFileHash => $composableBuilder(
      column: $table.storedFileHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> messagesRefs(
      Expression<bool> Function($$MessagesTableFilterComposer f) f) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mediaId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.mediaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MediaFilesTableOrderingComposer
    extends Composer<_$TwonlyDB, $MediaFilesTable> {
  $$MediaFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mediaId => $composableBuilder(
      column: $table.mediaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploadState => $composableBuilder(
      column: $table.uploadState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get downloadState => $composableBuilder(
      column: $table.downloadState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requiresAuthentication => $composableBuilder(
      column: $table.requiresAuthentication,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get stored => $composableBuilder(
      column: $table.stored, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDraftMedia => $composableBuilder(
      column: $table.isDraftMedia,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reuploadRequestedBy => $composableBuilder(
      column: $table.reuploadRequestedBy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get displayLimitInMilliseconds => $composableBuilder(
      column: $table.displayLimitInMilliseconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get removeAudio => $composableBuilder(
      column: $table.removeAudio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get downloadToken => $composableBuilder(
      column: $table.downloadToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get encryptionKey => $composableBuilder(
      column: $table.encryptionKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get encryptionMac => $composableBuilder(
      column: $table.encryptionMac,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get encryptionNonce => $composableBuilder(
      column: $table.encryptionNonce,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get storedFileHash => $composableBuilder(
      column: $table.storedFileHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaFilesTableAnnotationComposer
    extends Composer<_$TwonlyDB, $MediaFilesTable> {
  $$MediaFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UploadState?, String> get uploadState =>
      $composableBuilder(
          column: $table.uploadState, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadState?, String> get downloadState =>
      $composableBuilder(
          column: $table.downloadState, builder: (column) => column);

  GeneratedColumn<bool> get requiresAuthentication => $composableBuilder(
      column: $table.requiresAuthentication, builder: (column) => column);

  GeneratedColumn<bool> get stored =>
      $composableBuilder(column: $table.stored, builder: (column) => column);

  GeneratedColumn<bool> get isDraftMedia => $composableBuilder(
      column: $table.isDraftMedia, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<int>?, String>
      get reuploadRequestedBy => $composableBuilder(
          column: $table.reuploadRequestedBy, builder: (column) => column);

  GeneratedColumn<int> get displayLimitInMilliseconds => $composableBuilder(
      column: $table.displayLimitInMilliseconds, builder: (column) => column);

  GeneratedColumn<bool> get removeAudio => $composableBuilder(
      column: $table.removeAudio, builder: (column) => column);

  GeneratedColumn<Uint8List> get downloadToken => $composableBuilder(
      column: $table.downloadToken, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptionKey => $composableBuilder(
      column: $table.encryptionKey, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptionMac => $composableBuilder(
      column: $table.encryptionMac, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptionNonce => $composableBuilder(
      column: $table.encryptionNonce, builder: (column) => column);

  GeneratedColumn<Uint8List> get storedFileHash => $composableBuilder(
      column: $table.storedFileHash, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> messagesRefs<T extends Object>(
      Expression<T> Function($$MessagesTableAnnotationComposer a) f) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mediaId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.mediaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MediaFilesTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $MediaFilesTable,
    MediaFile,
    $$MediaFilesTableFilterComposer,
    $$MediaFilesTableOrderingComposer,
    $$MediaFilesTableAnnotationComposer,
    $$MediaFilesTableCreateCompanionBuilder,
    $$MediaFilesTableUpdateCompanionBuilder,
    (MediaFile, $$MediaFilesTableReferences),
    MediaFile,
    PrefetchHooks Function({bool messagesRefs})> {
  $$MediaFilesTableTableManager(_$TwonlyDB db, $MediaFilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> mediaId = const Value.absent(),
            Value<MediaType> type = const Value.absent(),
            Value<UploadState?> uploadState = const Value.absent(),
            Value<DownloadState?> downloadState = const Value.absent(),
            Value<bool> requiresAuthentication = const Value.absent(),
            Value<bool> stored = const Value.absent(),
            Value<bool> isDraftMedia = const Value.absent(),
            Value<List<int>?> reuploadRequestedBy = const Value.absent(),
            Value<int?> displayLimitInMilliseconds = const Value.absent(),
            Value<bool?> removeAudio = const Value.absent(),
            Value<Uint8List?> downloadToken = const Value.absent(),
            Value<Uint8List?> encryptionKey = const Value.absent(),
            Value<Uint8List?> encryptionMac = const Value.absent(),
            Value<Uint8List?> encryptionNonce = const Value.absent(),
            Value<Uint8List?> storedFileHash = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaFilesCompanion(
            mediaId: mediaId,
            type: type,
            uploadState: uploadState,
            downloadState: downloadState,
            requiresAuthentication: requiresAuthentication,
            stored: stored,
            isDraftMedia: isDraftMedia,
            reuploadRequestedBy: reuploadRequestedBy,
            displayLimitInMilliseconds: displayLimitInMilliseconds,
            removeAudio: removeAudio,
            downloadToken: downloadToken,
            encryptionKey: encryptionKey,
            encryptionMac: encryptionMac,
            encryptionNonce: encryptionNonce,
            storedFileHash: storedFileHash,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String mediaId,
            required MediaType type,
            Value<UploadState?> uploadState = const Value.absent(),
            Value<DownloadState?> downloadState = const Value.absent(),
            Value<bool> requiresAuthentication = const Value.absent(),
            Value<bool> stored = const Value.absent(),
            Value<bool> isDraftMedia = const Value.absent(),
            Value<List<int>?> reuploadRequestedBy = const Value.absent(),
            Value<int?> displayLimitInMilliseconds = const Value.absent(),
            Value<bool?> removeAudio = const Value.absent(),
            Value<Uint8List?> downloadToken = const Value.absent(),
            Value<Uint8List?> encryptionKey = const Value.absent(),
            Value<Uint8List?> encryptionMac = const Value.absent(),
            Value<Uint8List?> encryptionNonce = const Value.absent(),
            Value<Uint8List?> storedFileHash = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaFilesCompanion.insert(
            mediaId: mediaId,
            type: type,
            uploadState: uploadState,
            downloadState: downloadState,
            requiresAuthentication: requiresAuthentication,
            stored: stored,
            isDraftMedia: isDraftMedia,
            reuploadRequestedBy: reuploadRequestedBy,
            displayLimitInMilliseconds: displayLimitInMilliseconds,
            removeAudio: removeAudio,
            downloadToken: downloadToken,
            encryptionKey: encryptionKey,
            encryptionMac: encryptionMac,
            encryptionNonce: encryptionNonce,
            storedFileHash: storedFileHash,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MediaFilesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedData<MediaFile, $MediaFilesTable,
                            Message>(
                        currentTable: table,
                        referencedTable:
                            $$MediaFilesTableReferences._messagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MediaFilesTableReferences(db, table, p0)
                                .messagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.mediaId == item.mediaId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MediaFilesTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $MediaFilesTable,
    MediaFile,
    $$MediaFilesTableFilterComposer,
    $$MediaFilesTableOrderingComposer,
    $$MediaFilesTableAnnotationComposer,
    $$MediaFilesTableCreateCompanionBuilder,
    $$MediaFilesTableUpdateCompanionBuilder,
    (MediaFile, $$MediaFilesTableReferences),
    MediaFile,
    PrefetchHooks Function({bool messagesRefs})>;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String groupId,
  required String messageId,
  Value<int?> senderId,
  required MessageType type,
  Value<String?> content,
  Value<String?> mediaId,
  Value<Uint8List?> additionalMessageData,
  Value<bool> mediaStored,
  Value<bool> mediaReopened,
  Value<Uint8List?> downloadToken,
  Value<String?> quotesMessageId,
  Value<bool> isDeletedFromSender,
  Value<DateTime?> openedAt,
  Value<DateTime?> openedByAll,
  Value<DateTime> createdAt,
  Value<DateTime?> modifiedAt,
  Value<DateTime?> ackByUser,
  Value<DateTime?> ackByServer,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> groupId,
  Value<String> messageId,
  Value<int?> senderId,
  Value<MessageType> type,
  Value<String?> content,
  Value<String?> mediaId,
  Value<Uint8List?> additionalMessageData,
  Value<bool> mediaStored,
  Value<bool> mediaReopened,
  Value<Uint8List?> downloadToken,
  Value<String?> quotesMessageId,
  Value<bool> isDeletedFromSender,
  Value<DateTime?> openedAt,
  Value<DateTime?> openedByAll,
  Value<DateTime> createdAt,
  Value<DateTime?> modifiedAt,
  Value<DateTime?> ackByUser,
  Value<DateTime?> ackByServer,
  Value<int> rowid,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$TwonlyDB, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$TwonlyDB db) => db.groups.createAlias(
      $_aliasNameGenerator(db.messages.groupId, db.groups.groupId));

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager($_db, $_db.groups)
        .filter((f) => f.groupId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContactsTable _senderIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias(
          $_aliasNameGenerator(db.messages.senderId, db.contacts.userId));

  $$ContactsTableProcessedTableManager? get senderId {
    final $_column = $_itemColumn<int>('sender_id');
    if ($_column == null) return null;
    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_senderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $MediaFilesTable _mediaIdTable(_$TwonlyDB db) =>
      db.mediaFiles.createAlias(
          $_aliasNameGenerator(db.messages.mediaId, db.mediaFiles.mediaId));

  $$MediaFilesTableProcessedTableManager? get mediaId {
    final $_column = $_itemColumn<String>('media_id');
    if ($_column == null) return null;
    final manager = $$MediaFilesTableTableManager($_db, $_db.mediaFiles)
        .filter((f) => f.mediaId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$MessageHistoriesTable, List<MessageHistory>>
      _messageHistoriesRefsTable(_$TwonlyDB db) =>
          MultiTypedResultKey.fromTable(db.messageHistories,
              aliasName: $_aliasNameGenerator(
                  db.messages.messageId, db.messageHistories.messageId));

  $$MessageHistoriesTableProcessedTableManager get messageHistoriesRefs {
    final manager =
        $$MessageHistoriesTableTableManager($_db, $_db.messageHistories).filter(
            (f) => f.messageId.messageId
                .sqlEquals($_itemColumn<String>('message_id')!));

    final cache =
        $_typedResult.readTableOrNull(_messageHistoriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReactionsTable, List<Reaction>>
      _reactionsRefsTable(_$TwonlyDB db) =>
          MultiTypedResultKey.fromTable(db.reactions,
              aliasName: $_aliasNameGenerator(
                  db.messages.messageId, db.reactions.messageId));

  $$ReactionsTableProcessedTableManager get reactionsRefs {
    final manager = $$ReactionsTableTableManager($_db, $_db.reactions).filter(
        (f) => f.messageId.messageId
            .sqlEquals($_itemColumn<String>('message_id')!));

    final cache = $_typedResult.readTableOrNull(_reactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReceiptsTable, List<Receipt>> _receiptsRefsTable(
          _$TwonlyDB db) =>
      MultiTypedResultKey.fromTable(db.receipts,
          aliasName: $_aliasNameGenerator(
              db.messages.messageId, db.receipts.messageId));

  $$ReceiptsTableProcessedTableManager get receiptsRefs {
    final manager = $$ReceiptsTableTableManager($_db, $_db.receipts).filter(
        (f) => f.messageId.messageId
            .sqlEquals($_itemColumn<String>('message_id')!));

    final cache = $_typedResult.readTableOrNull(_receiptsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MessageActionsTable, List<MessageAction>>
      _messageActionsRefsTable(_$TwonlyDB db) =>
          MultiTypedResultKey.fromTable(db.messageActions,
              aliasName: $_aliasNameGenerator(
                  db.messages.messageId, db.messageActions.messageId));

  $$MessageActionsTableProcessedTableManager get messageActionsRefs {
    final manager = $$MessageActionsTableTableManager($_db, $_db.messageActions)
        .filter((f) => f.messageId.messageId
            .sqlEquals($_itemColumn<String>('message_id')!));

    final cache = $_typedResult.readTableOrNull(_messageActionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$TwonlyDB, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MessageType, MessageType, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get additionalMessageData => $composableBuilder(
      column: $table.additionalMessageData,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get mediaStored => $composableBuilder(
      column: $table.mediaStored, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get mediaReopened => $composableBuilder(
      column: $table.mediaReopened, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get downloadToken => $composableBuilder(
      column: $table.downloadToken, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quotesMessageId => $composableBuilder(
      column: $table.quotesMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeletedFromSender => $composableBuilder(
      column: $table.isDeletedFromSender,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedByAll => $composableBuilder(
      column: $table.openedByAll, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ackByUser => $composableBuilder(
      column: $table.ackByUser, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ackByServer => $composableBuilder(
      column: $table.ackByServer, builder: (column) => ColumnFilters(column));

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableFilterComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableFilterComposer get senderId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MediaFilesTableFilterComposer get mediaId {
    final $$MediaFilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mediaId,
        referencedTable: $db.mediaFiles,
        getReferencedColumn: (t) => t.mediaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MediaFilesTableFilterComposer(
              $db: $db,
              $table: $db.mediaFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> messageHistoriesRefs(
      Expression<bool> Function($$MessageHistoriesTableFilterComposer f) f) {
    final $$MessageHistoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messageHistories,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessageHistoriesTableFilterComposer(
              $db: $db,
              $table: $db.messageHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> reactionsRefs(
      Expression<bool> Function($$ReactionsTableFilterComposer f) f) {
    final $$ReactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.reactions,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReactionsTableFilterComposer(
              $db: $db,
              $table: $db.reactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> receiptsRefs(
      Expression<bool> Function($$ReceiptsTableFilterComposer f) f) {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.receipts,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReceiptsTableFilterComposer(
              $db: $db,
              $table: $db.receipts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> messageActionsRefs(
      Expression<bool> Function($$MessageActionsTableFilterComposer f) f) {
    final $$MessageActionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messageActions,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessageActionsTableFilterComposer(
              $db: $db,
              $table: $db.messageActions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$TwonlyDB, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get additionalMessageData => $composableBuilder(
      column: $table.additionalMessageData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get mediaStored => $composableBuilder(
      column: $table.mediaStored, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get mediaReopened => $composableBuilder(
      column: $table.mediaReopened,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get downloadToken => $composableBuilder(
      column: $table.downloadToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quotesMessageId => $composableBuilder(
      column: $table.quotesMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeletedFromSender => $composableBuilder(
      column: $table.isDeletedFromSender,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedByAll => $composableBuilder(
      column: $table.openedByAll, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ackByUser => $composableBuilder(
      column: $table.ackByUser, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ackByServer => $composableBuilder(
      column: $table.ackByServer, builder: (column) => ColumnOrderings(column));

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableOrderingComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableOrderingComposer get senderId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MediaFilesTableOrderingComposer get mediaId {
    final $$MediaFilesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mediaId,
        referencedTable: $db.mediaFiles,
        getReferencedColumn: (t) => t.mediaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MediaFilesTableOrderingComposer(
              $db: $db,
              $table: $db.mediaFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$TwonlyDB, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<Uint8List> get additionalMessageData => $composableBuilder(
      column: $table.additionalMessageData, builder: (column) => column);

  GeneratedColumn<bool> get mediaStored => $composableBuilder(
      column: $table.mediaStored, builder: (column) => column);

  GeneratedColumn<bool> get mediaReopened => $composableBuilder(
      column: $table.mediaReopened, builder: (column) => column);

  GeneratedColumn<Uint8List> get downloadToken => $composableBuilder(
      column: $table.downloadToken, builder: (column) => column);

  GeneratedColumn<String> get quotesMessageId => $composableBuilder(
      column: $table.quotesMessageId, builder: (column) => column);

  GeneratedColumn<bool> get isDeletedFromSender => $composableBuilder(
      column: $table.isDeletedFromSender, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get openedByAll => $composableBuilder(
      column: $table.openedByAll, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get ackByUser =>
      $composableBuilder(column: $table.ackByUser, builder: (column) => column);

  GeneratedColumn<DateTime> get ackByServer => $composableBuilder(
      column: $table.ackByServer, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableAnnotationComposer get senderId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MediaFilesTableAnnotationComposer get mediaId {
    final $$MediaFilesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mediaId,
        referencedTable: $db.mediaFiles,
        getReferencedColumn: (t) => t.mediaId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MediaFilesTableAnnotationComposer(
              $db: $db,
              $table: $db.mediaFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> messageHistoriesRefs<T extends Object>(
      Expression<T> Function($$MessageHistoriesTableAnnotationComposer a) f) {
    final $$MessageHistoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messageHistories,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessageHistoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.messageHistories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> reactionsRefs<T extends Object>(
      Expression<T> Function($$ReactionsTableAnnotationComposer a) f) {
    final $$ReactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.reactions,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.reactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> receiptsRefs<T extends Object>(
      Expression<T> Function($$ReceiptsTableAnnotationComposer a) f) {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.receipts,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReceiptsTableAnnotationComposer(
              $db: $db,
              $table: $db.receipts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> messageActionsRefs<T extends Object>(
      Expression<T> Function($$MessageActionsTableAnnotationComposer a) f) {
    final $$MessageActionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messageActions,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessageActionsTableAnnotationComposer(
              $db: $db,
              $table: $db.messageActions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MessagesTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, $$MessagesTableReferences),
    Message,
    PrefetchHooks Function(
        {bool groupId,
        bool senderId,
        bool mediaId,
        bool messageHistoriesRefs,
        bool reactionsRefs,
        bool receiptsRefs,
        bool messageActionsRefs})> {
  $$MessagesTableTableManager(_$TwonlyDB db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> groupId = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<int?> senderId = const Value.absent(),
            Value<MessageType> type = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> mediaId = const Value.absent(),
            Value<Uint8List?> additionalMessageData = const Value.absent(),
            Value<bool> mediaStored = const Value.absent(),
            Value<bool> mediaReopened = const Value.absent(),
            Value<Uint8List?> downloadToken = const Value.absent(),
            Value<String?> quotesMessageId = const Value.absent(),
            Value<bool> isDeletedFromSender = const Value.absent(),
            Value<DateTime?> openedAt = const Value.absent(),
            Value<DateTime?> openedByAll = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> modifiedAt = const Value.absent(),
            Value<DateTime?> ackByUser = const Value.absent(),
            Value<DateTime?> ackByServer = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion(
            groupId: groupId,
            messageId: messageId,
            senderId: senderId,
            type: type,
            content: content,
            mediaId: mediaId,
            additionalMessageData: additionalMessageData,
            mediaStored: mediaStored,
            mediaReopened: mediaReopened,
            downloadToken: downloadToken,
            quotesMessageId: quotesMessageId,
            isDeletedFromSender: isDeletedFromSender,
            openedAt: openedAt,
            openedByAll: openedByAll,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            ackByUser: ackByUser,
            ackByServer: ackByServer,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String groupId,
            required String messageId,
            Value<int?> senderId = const Value.absent(),
            required MessageType type,
            Value<String?> content = const Value.absent(),
            Value<String?> mediaId = const Value.absent(),
            Value<Uint8List?> additionalMessageData = const Value.absent(),
            Value<bool> mediaStored = const Value.absent(),
            Value<bool> mediaReopened = const Value.absent(),
            Value<Uint8List?> downloadToken = const Value.absent(),
            Value<String?> quotesMessageId = const Value.absent(),
            Value<bool> isDeletedFromSender = const Value.absent(),
            Value<DateTime?> openedAt = const Value.absent(),
            Value<DateTime?> openedByAll = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> modifiedAt = const Value.absent(),
            Value<DateTime?> ackByUser = const Value.absent(),
            Value<DateTime?> ackByServer = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            groupId: groupId,
            messageId: messageId,
            senderId: senderId,
            type: type,
            content: content,
            mediaId: mediaId,
            additionalMessageData: additionalMessageData,
            mediaStored: mediaStored,
            mediaReopened: mediaReopened,
            downloadToken: downloadToken,
            quotesMessageId: quotesMessageId,
            isDeletedFromSender: isDeletedFromSender,
            openedAt: openedAt,
            openedByAll: openedByAll,
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            ackByUser: ackByUser,
            ackByServer: ackByServer,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MessagesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {groupId = false,
              senderId = false,
              mediaId = false,
              messageHistoriesRefs = false,
              reactionsRefs = false,
              receiptsRefs = false,
              messageActionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (messageHistoriesRefs) db.messageHistories,
                if (reactionsRefs) db.reactions,
                if (receiptsRefs) db.receipts,
                if (messageActionsRefs) db.messageActions
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (groupId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.groupId,
                    referencedTable:
                        $$MessagesTableReferences._groupIdTable(db),
                    referencedColumn:
                        $$MessagesTableReferences._groupIdTable(db).groupId,
                  ) as T;
                }
                if (senderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.senderId,
                    referencedTable:
                        $$MessagesTableReferences._senderIdTable(db),
                    referencedColumn:
                        $$MessagesTableReferences._senderIdTable(db).userId,
                  ) as T;
                }
                if (mediaId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.mediaId,
                    referencedTable:
                        $$MessagesTableReferences._mediaIdTable(db),
                    referencedColumn:
                        $$MessagesTableReferences._mediaIdTable(db).mediaId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messageHistoriesRefs)
                    await $_getPrefetchedData<Message, $MessagesTable,
                            MessageHistory>(
                        currentTable: table,
                        referencedTable: $$MessagesTableReferences
                            ._messageHistoriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MessagesTableReferences(db, table, p0)
                                .messageHistoriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.messageId == item.messageId),
                        typedResults: items),
                  if (reactionsRefs)
                    await $_getPrefetchedData<Message, $MessagesTable,
                            Reaction>(
                        currentTable: table,
                        referencedTable:
                            $$MessagesTableReferences._reactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MessagesTableReferences(db, table, p0)
                                .reactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.messageId == item.messageId),
                        typedResults: items),
                  if (receiptsRefs)
                    await $_getPrefetchedData<Message, $MessagesTable, Receipt>(
                        currentTable: table,
                        referencedTable:
                            $$MessagesTableReferences._receiptsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MessagesTableReferences(db, table, p0)
                                .receiptsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.messageId == item.messageId),
                        typedResults: items),
                  if (messageActionsRefs)
                    await $_getPrefetchedData<Message, $MessagesTable,
                            MessageAction>(
                        currentTable: table,
                        referencedTable: $$MessagesTableReferences
                            ._messageActionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MessagesTableReferences(db, table, p0)
                                .messageActionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.messageId == item.messageId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, $$MessagesTableReferences),
    Message,
    PrefetchHooks Function(
        {bool groupId,
        bool senderId,
        bool mediaId,
        bool messageHistoriesRefs,
        bool reactionsRefs,
        bool receiptsRefs,
        bool messageActionsRefs})>;
typedef $$MessageHistoriesTableCreateCompanionBuilder
    = MessageHistoriesCompanion Function({
  Value<int> id,
  required String messageId,
  Value<int?> contactId,
  Value<String?> content,
  Value<DateTime> createdAt,
});
typedef $$MessageHistoriesTableUpdateCompanionBuilder
    = MessageHistoriesCompanion Function({
  Value<int> id,
  Value<String> messageId,
  Value<int?> contactId,
  Value<String?> content,
  Value<DateTime> createdAt,
});

final class $$MessageHistoriesTableReferences
    extends BaseReferences<_$TwonlyDB, $MessageHistoriesTable, MessageHistory> {
  $$MessageHistoriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $MessagesTable _messageIdTable(_$TwonlyDB db) =>
      db.messages.createAlias($_aliasNameGenerator(
          db.messageHistories.messageId, db.messages.messageId));

  $$MessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$MessagesTableTableManager($_db, $_db.messages)
        .filter((f) => f.messageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContactsTable _contactIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias($_aliasNameGenerator(
          db.messageHistories.contactId, db.contacts.userId));

  $$ContactsTableProcessedTableManager? get contactId {
    final $_column = $_itemColumn<int>('contact_id');
    if ($_column == null) return null;
    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MessageHistoriesTableFilterComposer
    extends Composer<_$TwonlyDB, $MessageHistoriesTable> {
  $$MessageHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessageHistoriesTableOrderingComposer
    extends Composer<_$TwonlyDB, $MessageHistoriesTable> {
  $$MessageHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableOrderingComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessageHistoriesTableAnnotationComposer
    extends Composer<_$TwonlyDB, $MessageHistoriesTable> {
  $$MessageHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessageHistoriesTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $MessageHistoriesTable,
    MessageHistory,
    $$MessageHistoriesTableFilterComposer,
    $$MessageHistoriesTableOrderingComposer,
    $$MessageHistoriesTableAnnotationComposer,
    $$MessageHistoriesTableCreateCompanionBuilder,
    $$MessageHistoriesTableUpdateCompanionBuilder,
    (MessageHistory, $$MessageHistoriesTableReferences),
    MessageHistory,
    PrefetchHooks Function({bool messageId, bool contactId})> {
  $$MessageHistoriesTableTableManager(
      _$TwonlyDB db, $MessageHistoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<int?> contactId = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MessageHistoriesCompanion(
            id: id,
            messageId: messageId,
            contactId: contactId,
            content: content,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String messageId,
            Value<int?> contactId = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MessageHistoriesCompanion.insert(
            id: id,
            messageId: messageId,
            contactId: contactId,
            content: content,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MessageHistoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({messageId = false, contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (messageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.messageId,
                    referencedTable:
                        $$MessageHistoriesTableReferences._messageIdTable(db),
                    referencedColumn: $$MessageHistoriesTableReferences
                        ._messageIdTable(db)
                        .messageId,
                  ) as T;
                }
                if (contactId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contactId,
                    referencedTable:
                        $$MessageHistoriesTableReferences._contactIdTable(db),
                    referencedColumn: $$MessageHistoriesTableReferences
                        ._contactIdTable(db)
                        .userId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MessageHistoriesTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $MessageHistoriesTable,
    MessageHistory,
    $$MessageHistoriesTableFilterComposer,
    $$MessageHistoriesTableOrderingComposer,
    $$MessageHistoriesTableAnnotationComposer,
    $$MessageHistoriesTableCreateCompanionBuilder,
    $$MessageHistoriesTableUpdateCompanionBuilder,
    (MessageHistory, $$MessageHistoriesTableReferences),
    MessageHistory,
    PrefetchHooks Function({bool messageId, bool contactId})>;
typedef $$ReactionsTableCreateCompanionBuilder = ReactionsCompanion Function({
  required String messageId,
  required String emoji,
  Value<int?> senderId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ReactionsTableUpdateCompanionBuilder = ReactionsCompanion Function({
  Value<String> messageId,
  Value<String> emoji,
  Value<int?> senderId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ReactionsTableReferences
    extends BaseReferences<_$TwonlyDB, $ReactionsTable, Reaction> {
  $$ReactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MessagesTable _messageIdTable(_$TwonlyDB db) =>
      db.messages.createAlias(
          $_aliasNameGenerator(db.reactions.messageId, db.messages.messageId));

  $$MessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$MessagesTableTableManager($_db, $_db.messages)
        .filter((f) => f.messageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContactsTable _senderIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias(
          $_aliasNameGenerator(db.reactions.senderId, db.contacts.userId));

  $$ContactsTableProcessedTableManager? get senderId {
    final $_column = $_itemColumn<int>('sender_id');
    if ($_column == null) return null;
    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_senderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReactionsTableFilterComposer
    extends Composer<_$TwonlyDB, $ReactionsTable> {
  $$ReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableFilterComposer get senderId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReactionsTableOrderingComposer
    extends Composer<_$TwonlyDB, $ReactionsTable> {
  $$ReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableOrderingComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableOrderingComposer get senderId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReactionsTableAnnotationComposer
    extends Composer<_$TwonlyDB, $ReactionsTable> {
  $$ReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableAnnotationComposer get senderId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.senderId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReactionsTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $ReactionsTable,
    Reaction,
    $$ReactionsTableFilterComposer,
    $$ReactionsTableOrderingComposer,
    $$ReactionsTableAnnotationComposer,
    $$ReactionsTableCreateCompanionBuilder,
    $$ReactionsTableUpdateCompanionBuilder,
    (Reaction, $$ReactionsTableReferences),
    Reaction,
    PrefetchHooks Function({bool messageId, bool senderId})> {
  $$ReactionsTableTableManager(_$TwonlyDB db, $ReactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> messageId = const Value.absent(),
            Value<String> emoji = const Value.absent(),
            Value<int?> senderId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReactionsCompanion(
            messageId: messageId,
            emoji: emoji,
            senderId: senderId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String messageId,
            required String emoji,
            Value<int?> senderId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReactionsCompanion.insert(
            messageId: messageId,
            emoji: emoji,
            senderId: senderId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({messageId = false, senderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (messageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.messageId,
                    referencedTable:
                        $$ReactionsTableReferences._messageIdTable(db),
                    referencedColumn: $$ReactionsTableReferences
                        ._messageIdTable(db)
                        .messageId,
                  ) as T;
                }
                if (senderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.senderId,
                    referencedTable:
                        $$ReactionsTableReferences._senderIdTable(db),
                    referencedColumn:
                        $$ReactionsTableReferences._senderIdTable(db).userId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReactionsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $ReactionsTable,
    Reaction,
    $$ReactionsTableFilterComposer,
    $$ReactionsTableOrderingComposer,
    $$ReactionsTableAnnotationComposer,
    $$ReactionsTableCreateCompanionBuilder,
    $$ReactionsTableUpdateCompanionBuilder,
    (Reaction, $$ReactionsTableReferences),
    Reaction,
    PrefetchHooks Function({bool messageId, bool senderId})>;
typedef $$GroupMembersTableCreateCompanionBuilder = GroupMembersCompanion
    Function({
  required String groupId,
  required int contactId,
  Value<MemberState?> memberState,
  Value<Uint8List?> groupPublicKey,
  Value<DateTime?> lastMessage,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$GroupMembersTableUpdateCompanionBuilder = GroupMembersCompanion
    Function({
  Value<String> groupId,
  Value<int> contactId,
  Value<MemberState?> memberState,
  Value<Uint8List?> groupPublicKey,
  Value<DateTime?> lastMessage,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$GroupMembersTableReferences
    extends BaseReferences<_$TwonlyDB, $GroupMembersTable, GroupMember> {
  $$GroupMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$TwonlyDB db) => db.groups.createAlias(
      $_aliasNameGenerator(db.groupMembers.groupId, db.groups.groupId));

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager($_db, $_db.groups)
        .filter((f) => f.groupId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContactsTable _contactIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias(
          $_aliasNameGenerator(db.groupMembers.contactId, db.contacts.userId));

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<int>('contact_id')!;

    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GroupMembersTableFilterComposer
    extends Composer<_$TwonlyDB, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<MemberState?, MemberState, String>
      get memberState => $composableBuilder(
          column: $table.memberState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<Uint8List> get groupPublicKey => $composableBuilder(
      column: $table.groupPublicKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableFilterComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$TwonlyDB, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memberState => $composableBuilder(
      column: $table.memberState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get groupPublicKey => $composableBuilder(
      column: $table.groupPublicKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableOrderingComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$TwonlyDB, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<MemberState?, String> get memberState =>
      $composableBuilder(
          column: $table.memberState, builder: (column) => column);

  GeneratedColumn<Uint8List> get groupPublicKey => $composableBuilder(
      column: $table.groupPublicKey, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupMembersTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (GroupMember, $$GroupMembersTableReferences),
    GroupMember,
    PrefetchHooks Function({bool groupId, bool contactId})> {
  $$GroupMembersTableTableManager(_$TwonlyDB db, $GroupMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> groupId = const Value.absent(),
            Value<int> contactId = const Value.absent(),
            Value<MemberState?> memberState = const Value.absent(),
            Value<Uint8List?> groupPublicKey = const Value.absent(),
            Value<DateTime?> lastMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion(
            groupId: groupId,
            contactId: contactId,
            memberState: memberState,
            groupPublicKey: groupPublicKey,
            lastMessage: lastMessage,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String groupId,
            required int contactId,
            Value<MemberState?> memberState = const Value.absent(),
            Value<Uint8List?> groupPublicKey = const Value.absent(),
            Value<DateTime?> lastMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion.insert(
            groupId: groupId,
            contactId: contactId,
            memberState: memberState,
            groupPublicKey: groupPublicKey,
            lastMessage: lastMessage,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GroupMembersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({groupId = false, contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (groupId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.groupId,
                    referencedTable:
                        $$GroupMembersTableReferences._groupIdTable(db),
                    referencedColumn:
                        $$GroupMembersTableReferences._groupIdTable(db).groupId,
                  ) as T;
                }
                if (contactId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contactId,
                    referencedTable:
                        $$GroupMembersTableReferences._contactIdTable(db),
                    referencedColumn: $$GroupMembersTableReferences
                        ._contactIdTable(db)
                        .userId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GroupMembersTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (GroupMember, $$GroupMembersTableReferences),
    GroupMember,
    PrefetchHooks Function({bool groupId, bool contactId})>;
typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  required String receiptId,
  required int contactId,
  Value<String?> messageId,
  required Uint8List message,
  Value<bool> contactWillSendsReceipt,
  Value<DateTime?> markForRetry,
  Value<DateTime?> markForRetryAfterAccepted,
  Value<DateTime?> ackByServerAt,
  Value<int> retryCount,
  Value<DateTime?> lastRetry,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<String> receiptId,
  Value<int> contactId,
  Value<String?> messageId,
  Value<Uint8List> message,
  Value<bool> contactWillSendsReceipt,
  Value<DateTime?> markForRetry,
  Value<DateTime?> markForRetryAfterAccepted,
  Value<DateTime?> ackByServerAt,
  Value<int> retryCount,
  Value<DateTime?> lastRetry,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ReceiptsTableReferences
    extends BaseReferences<_$TwonlyDB, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ContactsTable _contactIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias(
          $_aliasNameGenerator(db.receipts.contactId, db.contacts.userId));

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<int>('contact_id')!;

    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $MessagesTable _messageIdTable(_$TwonlyDB db) =>
      db.messages.createAlias(
          $_aliasNameGenerator(db.receipts.messageId, db.messages.messageId));

  $$MessagesTableProcessedTableManager? get messageId {
    final $_column = $_itemColumn<String>('message_id');
    if ($_column == null) return null;
    final manager = $$MessagesTableTableManager($_db, $_db.messages)
        .filter((f) => f.messageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$TwonlyDB, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get receiptId => $composableBuilder(
      column: $table.receiptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get contactWillSendsReceipt => $composableBuilder(
      column: $table.contactWillSendsReceipt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get markForRetry => $composableBuilder(
      column: $table.markForRetry, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get markForRetryAfterAccepted => $composableBuilder(
      column: $table.markForRetryAfterAccepted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ackByServerAt => $composableBuilder(
      column: $table.ackByServerAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastRetry => $composableBuilder(
      column: $table.lastRetry, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$TwonlyDB, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get receiptId => $composableBuilder(
      column: $table.receiptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get message => $composableBuilder(
      column: $table.message, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get contactWillSendsReceipt => $composableBuilder(
      column: $table.contactWillSendsReceipt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get markForRetry => $composableBuilder(
      column: $table.markForRetry,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get markForRetryAfterAccepted => $composableBuilder(
      column: $table.markForRetryAfterAccepted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ackByServerAt => $composableBuilder(
      column: $table.ackByServerAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastRetry => $composableBuilder(
      column: $table.lastRetry, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableOrderingComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$TwonlyDB, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<Uint8List> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<bool> get contactWillSendsReceipt => $composableBuilder(
      column: $table.contactWillSendsReceipt, builder: (column) => column);

  GeneratedColumn<DateTime> get markForRetry => $composableBuilder(
      column: $table.markForRetry, builder: (column) => column);

  GeneratedColumn<DateTime> get markForRetryAfterAccepted => $composableBuilder(
      column: $table.markForRetryAfterAccepted, builder: (column) => column);

  GeneratedColumn<DateTime> get ackByServerAt => $composableBuilder(
      column: $table.ackByServerAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastRetry =>
      $composableBuilder(column: $table.lastRetry, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReceiptsTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $ReceiptsTable,
    Receipt,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (Receipt, $$ReceiptsTableReferences),
    Receipt,
    PrefetchHooks Function({bool contactId, bool messageId})> {
  $$ReceiptsTableTableManager(_$TwonlyDB db, $ReceiptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> receiptId = const Value.absent(),
            Value<int> contactId = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            Value<Uint8List> message = const Value.absent(),
            Value<bool> contactWillSendsReceipt = const Value.absent(),
            Value<DateTime?> markForRetry = const Value.absent(),
            Value<DateTime?> markForRetryAfterAccepted = const Value.absent(),
            Value<DateTime?> ackByServerAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> lastRetry = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptsCompanion(
            receiptId: receiptId,
            contactId: contactId,
            messageId: messageId,
            message: message,
            contactWillSendsReceipt: contactWillSendsReceipt,
            markForRetry: markForRetry,
            markForRetryAfterAccepted: markForRetryAfterAccepted,
            ackByServerAt: ackByServerAt,
            retryCount: retryCount,
            lastRetry: lastRetry,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String receiptId,
            required int contactId,
            Value<String?> messageId = const Value.absent(),
            required Uint8List message,
            Value<bool> contactWillSendsReceipt = const Value.absent(),
            Value<DateTime?> markForRetry = const Value.absent(),
            Value<DateTime?> markForRetryAfterAccepted = const Value.absent(),
            Value<DateTime?> ackByServerAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime?> lastRetry = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceiptsCompanion.insert(
            receiptId: receiptId,
            contactId: contactId,
            messageId: messageId,
            message: message,
            contactWillSendsReceipt: contactWillSendsReceipt,
            markForRetry: markForRetry,
            markForRetryAfterAccepted: markForRetryAfterAccepted,
            ackByServerAt: ackByServerAt,
            retryCount: retryCount,
            lastRetry: lastRetry,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ReceiptsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({contactId = false, messageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (contactId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contactId,
                    referencedTable:
                        $$ReceiptsTableReferences._contactIdTable(db),
                    referencedColumn:
                        $$ReceiptsTableReferences._contactIdTable(db).userId,
                  ) as T;
                }
                if (messageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.messageId,
                    referencedTable:
                        $$ReceiptsTableReferences._messageIdTable(db),
                    referencedColumn:
                        $$ReceiptsTableReferences._messageIdTable(db).messageId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReceiptsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $ReceiptsTable,
    Receipt,
    $$ReceiptsTableFilterComposer,
    $$ReceiptsTableOrderingComposer,
    $$ReceiptsTableAnnotationComposer,
    $$ReceiptsTableCreateCompanionBuilder,
    $$ReceiptsTableUpdateCompanionBuilder,
    (Receipt, $$ReceiptsTableReferences),
    Receipt,
    PrefetchHooks Function({bool contactId, bool messageId})>;
typedef $$ReceivedReceiptsTableCreateCompanionBuilder
    = ReceivedReceiptsCompanion Function({
  required String receiptId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ReceivedReceiptsTableUpdateCompanionBuilder
    = ReceivedReceiptsCompanion Function({
  Value<String> receiptId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ReceivedReceiptsTableFilterComposer
    extends Composer<_$TwonlyDB, $ReceivedReceiptsTable> {
  $$ReceivedReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get receiptId => $composableBuilder(
      column: $table.receiptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ReceivedReceiptsTableOrderingComposer
    extends Composer<_$TwonlyDB, $ReceivedReceiptsTable> {
  $$ReceivedReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get receiptId => $composableBuilder(
      column: $table.receiptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ReceivedReceiptsTableAnnotationComposer
    extends Composer<_$TwonlyDB, $ReceivedReceiptsTable> {
  $$ReceivedReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReceivedReceiptsTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $ReceivedReceiptsTable,
    ReceivedReceipt,
    $$ReceivedReceiptsTableFilterComposer,
    $$ReceivedReceiptsTableOrderingComposer,
    $$ReceivedReceiptsTableAnnotationComposer,
    $$ReceivedReceiptsTableCreateCompanionBuilder,
    $$ReceivedReceiptsTableUpdateCompanionBuilder,
    (
      ReceivedReceipt,
      BaseReferences<_$TwonlyDB, $ReceivedReceiptsTable, ReceivedReceipt>
    ),
    ReceivedReceipt,
    PrefetchHooks Function()> {
  $$ReceivedReceiptsTableTableManager(
      _$TwonlyDB db, $ReceivedReceiptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceivedReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceivedReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceivedReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> receiptId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceivedReceiptsCompanion(
            receiptId: receiptId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String receiptId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceivedReceiptsCompanion.insert(
            receiptId: receiptId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReceivedReceiptsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $ReceivedReceiptsTable,
    ReceivedReceipt,
    $$ReceivedReceiptsTableFilterComposer,
    $$ReceivedReceiptsTableOrderingComposer,
    $$ReceivedReceiptsTableAnnotationComposer,
    $$ReceivedReceiptsTableCreateCompanionBuilder,
    $$ReceivedReceiptsTableUpdateCompanionBuilder,
    (
      ReceivedReceipt,
      BaseReferences<_$TwonlyDB, $ReceivedReceiptsTable, ReceivedReceipt>
    ),
    ReceivedReceipt,
    PrefetchHooks Function()>;
typedef $$SignalIdentityKeyStoresTableCreateCompanionBuilder
    = SignalIdentityKeyStoresCompanion Function({
  required int deviceId,
  required String name,
  required Uint8List identityKey,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SignalIdentityKeyStoresTableUpdateCompanionBuilder
    = SignalIdentityKeyStoresCompanion Function({
  Value<int> deviceId,
  Value<String> name,
  Value<Uint8List> identityKey,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SignalIdentityKeyStoresTableFilterComposer
    extends Composer<_$TwonlyDB, $SignalIdentityKeyStoresTable> {
  $$SignalIdentityKeyStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get identityKey => $composableBuilder(
      column: $table.identityKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SignalIdentityKeyStoresTableOrderingComposer
    extends Composer<_$TwonlyDB, $SignalIdentityKeyStoresTable> {
  $$SignalIdentityKeyStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get identityKey => $composableBuilder(
      column: $table.identityKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SignalIdentityKeyStoresTableAnnotationComposer
    extends Composer<_$TwonlyDB, $SignalIdentityKeyStoresTable> {
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
      column: $table.identityKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignalIdentityKeyStoresTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $SignalIdentityKeyStoresTable,
    SignalIdentityKeyStore,
    $$SignalIdentityKeyStoresTableFilterComposer,
    $$SignalIdentityKeyStoresTableOrderingComposer,
    $$SignalIdentityKeyStoresTableAnnotationComposer,
    $$SignalIdentityKeyStoresTableCreateCompanionBuilder,
    $$SignalIdentityKeyStoresTableUpdateCompanionBuilder,
    (
      SignalIdentityKeyStore,
      BaseReferences<_$TwonlyDB, $SignalIdentityKeyStoresTable,
          SignalIdentityKeyStore>
    ),
    SignalIdentityKeyStore,
    PrefetchHooks Function()> {
  $$SignalIdentityKeyStoresTableTableManager(
      _$TwonlyDB db, $SignalIdentityKeyStoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalIdentityKeyStoresTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalIdentityKeyStoresTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalIdentityKeyStoresTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> deviceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<Uint8List> identityKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignalIdentityKeyStoresCompanion(
            deviceId: deviceId,
            name: name,
            identityKey: identityKey,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int deviceId,
            required String name,
            required Uint8List identityKey,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignalIdentityKeyStoresCompanion.insert(
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
        ));
}

typedef $$SignalIdentityKeyStoresTableProcessedTableManager
    = ProcessedTableManager<
        _$TwonlyDB,
        $SignalIdentityKeyStoresTable,
        SignalIdentityKeyStore,
        $$SignalIdentityKeyStoresTableFilterComposer,
        $$SignalIdentityKeyStoresTableOrderingComposer,
        $$SignalIdentityKeyStoresTableAnnotationComposer,
        $$SignalIdentityKeyStoresTableCreateCompanionBuilder,
        $$SignalIdentityKeyStoresTableUpdateCompanionBuilder,
        (
          SignalIdentityKeyStore,
          BaseReferences<_$TwonlyDB, $SignalIdentityKeyStoresTable,
              SignalIdentityKeyStore>
        ),
        SignalIdentityKeyStore,
        PrefetchHooks Function()>;
typedef $$SignalPreKeyStoresTableCreateCompanionBuilder
    = SignalPreKeyStoresCompanion Function({
  Value<int> preKeyId,
  required Uint8List preKey,
  Value<DateTime> createdAt,
});
typedef $$SignalPreKeyStoresTableUpdateCompanionBuilder
    = SignalPreKeyStoresCompanion Function({
  Value<int> preKeyId,
  Value<Uint8List> preKey,
  Value<DateTime> createdAt,
});

class $$SignalPreKeyStoresTableFilterComposer
    extends Composer<_$TwonlyDB, $SignalPreKeyStoresTable> {
  $$SignalPreKeyStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get preKeyId => $composableBuilder(
      column: $table.preKeyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get preKey => $composableBuilder(
      column: $table.preKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SignalPreKeyStoresTableOrderingComposer
    extends Composer<_$TwonlyDB, $SignalPreKeyStoresTable> {
  $$SignalPreKeyStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get preKeyId => $composableBuilder(
      column: $table.preKeyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get preKey => $composableBuilder(
      column: $table.preKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SignalPreKeyStoresTableAnnotationComposer
    extends Composer<_$TwonlyDB, $SignalPreKeyStoresTable> {
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

class $$SignalPreKeyStoresTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $SignalPreKeyStoresTable,
    SignalPreKeyStore,
    $$SignalPreKeyStoresTableFilterComposer,
    $$SignalPreKeyStoresTableOrderingComposer,
    $$SignalPreKeyStoresTableAnnotationComposer,
    $$SignalPreKeyStoresTableCreateCompanionBuilder,
    $$SignalPreKeyStoresTableUpdateCompanionBuilder,
    (
      SignalPreKeyStore,
      BaseReferences<_$TwonlyDB, $SignalPreKeyStoresTable, SignalPreKeyStore>
    ),
    SignalPreKeyStore,
    PrefetchHooks Function()> {
  $$SignalPreKeyStoresTableTableManager(
      _$TwonlyDB db, $SignalPreKeyStoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalPreKeyStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalPreKeyStoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalPreKeyStoresTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> preKeyId = const Value.absent(),
            Value<Uint8List> preKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SignalPreKeyStoresCompanion(
            preKeyId: preKeyId,
            preKey: preKey,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> preKeyId = const Value.absent(),
            required Uint8List preKey,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SignalPreKeyStoresCompanion.insert(
            preKeyId: preKeyId,
            preKey: preKey,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SignalPreKeyStoresTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $SignalPreKeyStoresTable,
    SignalPreKeyStore,
    $$SignalPreKeyStoresTableFilterComposer,
    $$SignalPreKeyStoresTableOrderingComposer,
    $$SignalPreKeyStoresTableAnnotationComposer,
    $$SignalPreKeyStoresTableCreateCompanionBuilder,
    $$SignalPreKeyStoresTableUpdateCompanionBuilder,
    (
      SignalPreKeyStore,
      BaseReferences<_$TwonlyDB, $SignalPreKeyStoresTable, SignalPreKeyStore>
    ),
    SignalPreKeyStore,
    PrefetchHooks Function()>;
typedef $$SignalSenderKeyStoresTableCreateCompanionBuilder
    = SignalSenderKeyStoresCompanion Function({
  required String senderKeyName,
  required Uint8List senderKey,
  Value<int> rowid,
});
typedef $$SignalSenderKeyStoresTableUpdateCompanionBuilder
    = SignalSenderKeyStoresCompanion Function({
  Value<String> senderKeyName,
  Value<Uint8List> senderKey,
  Value<int> rowid,
});

class $$SignalSenderKeyStoresTableFilterComposer
    extends Composer<_$TwonlyDB, $SignalSenderKeyStoresTable> {
  $$SignalSenderKeyStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get senderKeyName => $composableBuilder(
      column: $table.senderKeyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get senderKey => $composableBuilder(
      column: $table.senderKey, builder: (column) => ColumnFilters(column));
}

class $$SignalSenderKeyStoresTableOrderingComposer
    extends Composer<_$TwonlyDB, $SignalSenderKeyStoresTable> {
  $$SignalSenderKeyStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get senderKeyName => $composableBuilder(
      column: $table.senderKeyName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get senderKey => $composableBuilder(
      column: $table.senderKey, builder: (column) => ColumnOrderings(column));
}

class $$SignalSenderKeyStoresTableAnnotationComposer
    extends Composer<_$TwonlyDB, $SignalSenderKeyStoresTable> {
  $$SignalSenderKeyStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get senderKeyName => $composableBuilder(
      column: $table.senderKeyName, builder: (column) => column);

  GeneratedColumn<Uint8List> get senderKey =>
      $composableBuilder(column: $table.senderKey, builder: (column) => column);
}

class $$SignalSenderKeyStoresTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $SignalSenderKeyStoresTable,
    SignalSenderKeyStore,
    $$SignalSenderKeyStoresTableFilterComposer,
    $$SignalSenderKeyStoresTableOrderingComposer,
    $$SignalSenderKeyStoresTableAnnotationComposer,
    $$SignalSenderKeyStoresTableCreateCompanionBuilder,
    $$SignalSenderKeyStoresTableUpdateCompanionBuilder,
    (
      SignalSenderKeyStore,
      BaseReferences<_$TwonlyDB, $SignalSenderKeyStoresTable,
          SignalSenderKeyStore>
    ),
    SignalSenderKeyStore,
    PrefetchHooks Function()> {
  $$SignalSenderKeyStoresTableTableManager(
      _$TwonlyDB db, $SignalSenderKeyStoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSenderKeyStoresTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalSenderKeyStoresTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalSenderKeyStoresTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> senderKeyName = const Value.absent(),
            Value<Uint8List> senderKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignalSenderKeyStoresCompanion(
            senderKeyName: senderKeyName,
            senderKey: senderKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String senderKeyName,
            required Uint8List senderKey,
            Value<int> rowid = const Value.absent(),
          }) =>
              SignalSenderKeyStoresCompanion.insert(
            senderKeyName: senderKeyName,
            senderKey: senderKey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SignalSenderKeyStoresTableProcessedTableManager
    = ProcessedTableManager<
        _$TwonlyDB,
        $SignalSenderKeyStoresTable,
        SignalSenderKeyStore,
        $$SignalSenderKeyStoresTableFilterComposer,
        $$SignalSenderKeyStoresTableOrderingComposer,
        $$SignalSenderKeyStoresTableAnnotationComposer,
        $$SignalSenderKeyStoresTableCreateCompanionBuilder,
        $$SignalSenderKeyStoresTableUpdateCompanionBuilder,
        (
          SignalSenderKeyStore,
          BaseReferences<_$TwonlyDB, $SignalSenderKeyStoresTable,
              SignalSenderKeyStore>
        ),
        SignalSenderKeyStore,
        PrefetchHooks Function()>;
typedef $$SignalSessionStoresTableCreateCompanionBuilder
    = SignalSessionStoresCompanion Function({
  required int deviceId,
  required String name,
  required Uint8List sessionRecord,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SignalSessionStoresTableUpdateCompanionBuilder
    = SignalSessionStoresCompanion Function({
  Value<int> deviceId,
  Value<String> name,
  Value<Uint8List> sessionRecord,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SignalSessionStoresTableFilterComposer
    extends Composer<_$TwonlyDB, $SignalSessionStoresTable> {
  $$SignalSessionStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get sessionRecord => $composableBuilder(
      column: $table.sessionRecord, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SignalSessionStoresTableOrderingComposer
    extends Composer<_$TwonlyDB, $SignalSessionStoresTable> {
  $$SignalSessionStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get sessionRecord => $composableBuilder(
      column: $table.sessionRecord,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SignalSessionStoresTableAnnotationComposer
    extends Composer<_$TwonlyDB, $SignalSessionStoresTable> {
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
      column: $table.sessionRecord, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignalSessionStoresTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $SignalSessionStoresTable,
    SignalSessionStore,
    $$SignalSessionStoresTableFilterComposer,
    $$SignalSessionStoresTableOrderingComposer,
    $$SignalSessionStoresTableAnnotationComposer,
    $$SignalSessionStoresTableCreateCompanionBuilder,
    $$SignalSessionStoresTableUpdateCompanionBuilder,
    (
      SignalSessionStore,
      BaseReferences<_$TwonlyDB, $SignalSessionStoresTable, SignalSessionStore>
    ),
    SignalSessionStore,
    PrefetchHooks Function()> {
  $$SignalSessionStoresTableTableManager(
      _$TwonlyDB db, $SignalSessionStoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalSessionStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalSessionStoresTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalSessionStoresTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> deviceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<Uint8List> sessionRecord = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignalSessionStoresCompanion(
            deviceId: deviceId,
            name: name,
            sessionRecord: sessionRecord,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int deviceId,
            required String name,
            required Uint8List sessionRecord,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignalSessionStoresCompanion.insert(
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
        ));
}

typedef $$SignalSessionStoresTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $SignalSessionStoresTable,
    SignalSessionStore,
    $$SignalSessionStoresTableFilterComposer,
    $$SignalSessionStoresTableOrderingComposer,
    $$SignalSessionStoresTableAnnotationComposer,
    $$SignalSessionStoresTableCreateCompanionBuilder,
    $$SignalSessionStoresTableUpdateCompanionBuilder,
    (
      SignalSessionStore,
      BaseReferences<_$TwonlyDB, $SignalSessionStoresTable, SignalSessionStore>
    ),
    SignalSessionStore,
    PrefetchHooks Function()>;
typedef $$SignalContactPreKeysTableCreateCompanionBuilder
    = SignalContactPreKeysCompanion Function({
  required int contactId,
  required int preKeyId,
  required Uint8List preKey,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SignalContactPreKeysTableUpdateCompanionBuilder
    = SignalContactPreKeysCompanion Function({
  Value<int> contactId,
  Value<int> preKeyId,
  Value<Uint8List> preKey,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$SignalContactPreKeysTableReferences extends BaseReferences<
    _$TwonlyDB, $SignalContactPreKeysTable, SignalContactPreKey> {
  $$SignalContactPreKeysTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ContactsTable _contactIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias($_aliasNameGenerator(
          db.signalContactPreKeys.contactId, db.contacts.userId));

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<int>('contact_id')!;

    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SignalContactPreKeysTableFilterComposer
    extends Composer<_$TwonlyDB, $SignalContactPreKeysTable> {
  $$SignalContactPreKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get preKeyId => $composableBuilder(
      column: $table.preKeyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get preKey => $composableBuilder(
      column: $table.preKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SignalContactPreKeysTableOrderingComposer
    extends Composer<_$TwonlyDB, $SignalContactPreKeysTable> {
  $$SignalContactPreKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get preKeyId => $composableBuilder(
      column: $table.preKeyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get preKey => $composableBuilder(
      column: $table.preKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SignalContactPreKeysTableAnnotationComposer
    extends Composer<_$TwonlyDB, $SignalContactPreKeysTable> {
  $$SignalContactPreKeysTableAnnotationComposer({
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

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SignalContactPreKeysTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $SignalContactPreKeysTable,
    SignalContactPreKey,
    $$SignalContactPreKeysTableFilterComposer,
    $$SignalContactPreKeysTableOrderingComposer,
    $$SignalContactPreKeysTableAnnotationComposer,
    $$SignalContactPreKeysTableCreateCompanionBuilder,
    $$SignalContactPreKeysTableUpdateCompanionBuilder,
    (SignalContactPreKey, $$SignalContactPreKeysTableReferences),
    SignalContactPreKey,
    PrefetchHooks Function({bool contactId})> {
  $$SignalContactPreKeysTableTableManager(
      _$TwonlyDB db, $SignalContactPreKeysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalContactPreKeysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalContactPreKeysTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalContactPreKeysTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> contactId = const Value.absent(),
            Value<int> preKeyId = const Value.absent(),
            Value<Uint8List> preKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignalContactPreKeysCompanion(
            contactId: contactId,
            preKeyId: preKeyId,
            preKey: preKey,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int contactId,
            required int preKeyId,
            required Uint8List preKey,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignalContactPreKeysCompanion.insert(
            contactId: contactId,
            preKeyId: preKeyId,
            preKey: preKey,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SignalContactPreKeysTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (contactId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contactId,
                    referencedTable: $$SignalContactPreKeysTableReferences
                        ._contactIdTable(db),
                    referencedColumn: $$SignalContactPreKeysTableReferences
                        ._contactIdTable(db)
                        .userId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SignalContactPreKeysTableProcessedTableManager
    = ProcessedTableManager<
        _$TwonlyDB,
        $SignalContactPreKeysTable,
        SignalContactPreKey,
        $$SignalContactPreKeysTableFilterComposer,
        $$SignalContactPreKeysTableOrderingComposer,
        $$SignalContactPreKeysTableAnnotationComposer,
        $$SignalContactPreKeysTableCreateCompanionBuilder,
        $$SignalContactPreKeysTableUpdateCompanionBuilder,
        (SignalContactPreKey, $$SignalContactPreKeysTableReferences),
        SignalContactPreKey,
        PrefetchHooks Function({bool contactId})>;
typedef $$SignalContactSignedPreKeysTableCreateCompanionBuilder
    = SignalContactSignedPreKeysCompanion Function({
  Value<int> contactId,
  required int signedPreKeyId,
  required Uint8List signedPreKey,
  required Uint8List signedPreKeySignature,
  Value<DateTime> createdAt,
});
typedef $$SignalContactSignedPreKeysTableUpdateCompanionBuilder
    = SignalContactSignedPreKeysCompanion Function({
  Value<int> contactId,
  Value<int> signedPreKeyId,
  Value<Uint8List> signedPreKey,
  Value<Uint8List> signedPreKeySignature,
  Value<DateTime> createdAt,
});

final class $$SignalContactSignedPreKeysTableReferences extends BaseReferences<
    _$TwonlyDB, $SignalContactSignedPreKeysTable, SignalContactSignedPreKey> {
  $$SignalContactSignedPreKeysTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ContactsTable _contactIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias($_aliasNameGenerator(
          db.signalContactSignedPreKeys.contactId, db.contacts.userId));

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<int>('contact_id')!;

    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SignalContactSignedPreKeysTableFilterComposer
    extends Composer<_$TwonlyDB, $SignalContactSignedPreKeysTable> {
  $$SignalContactSignedPreKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get signedPreKeyId => $composableBuilder(
      column: $table.signedPreKeyId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get signedPreKey => $composableBuilder(
      column: $table.signedPreKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get signedPreKeySignature => $composableBuilder(
      column: $table.signedPreKeySignature,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SignalContactSignedPreKeysTableOrderingComposer
    extends Composer<_$TwonlyDB, $SignalContactSignedPreKeysTable> {
  $$SignalContactSignedPreKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get signedPreKeyId => $composableBuilder(
      column: $table.signedPreKeyId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get signedPreKey => $composableBuilder(
      column: $table.signedPreKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get signedPreKeySignature => $composableBuilder(
      column: $table.signedPreKeySignature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SignalContactSignedPreKeysTableAnnotationComposer
    extends Composer<_$TwonlyDB, $SignalContactSignedPreKeysTable> {
  $$SignalContactSignedPreKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get signedPreKeyId => $composableBuilder(
      column: $table.signedPreKeyId, builder: (column) => column);

  GeneratedColumn<Uint8List> get signedPreKey => $composableBuilder(
      column: $table.signedPreKey, builder: (column) => column);

  GeneratedColumn<Uint8List> get signedPreKeySignature => $composableBuilder(
      column: $table.signedPreKeySignature, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SignalContactSignedPreKeysTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $SignalContactSignedPreKeysTable,
    SignalContactSignedPreKey,
    $$SignalContactSignedPreKeysTableFilterComposer,
    $$SignalContactSignedPreKeysTableOrderingComposer,
    $$SignalContactSignedPreKeysTableAnnotationComposer,
    $$SignalContactSignedPreKeysTableCreateCompanionBuilder,
    $$SignalContactSignedPreKeysTableUpdateCompanionBuilder,
    (SignalContactSignedPreKey, $$SignalContactSignedPreKeysTableReferences),
    SignalContactSignedPreKey,
    PrefetchHooks Function({bool contactId})> {
  $$SignalContactSignedPreKeysTableTableManager(
      _$TwonlyDB db, $SignalContactSignedPreKeysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalContactSignedPreKeysTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalContactSignedPreKeysTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalContactSignedPreKeysTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> contactId = const Value.absent(),
            Value<int> signedPreKeyId = const Value.absent(),
            Value<Uint8List> signedPreKey = const Value.absent(),
            Value<Uint8List> signedPreKeySignature = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SignalContactSignedPreKeysCompanion(
            contactId: contactId,
            signedPreKeyId: signedPreKeyId,
            signedPreKey: signedPreKey,
            signedPreKeySignature: signedPreKeySignature,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> contactId = const Value.absent(),
            required int signedPreKeyId,
            required Uint8List signedPreKey,
            required Uint8List signedPreKeySignature,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SignalContactSignedPreKeysCompanion.insert(
            contactId: contactId,
            signedPreKeyId: signedPreKeyId,
            signedPreKey: signedPreKey,
            signedPreKeySignature: signedPreKeySignature,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SignalContactSignedPreKeysTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (contactId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contactId,
                    referencedTable: $$SignalContactSignedPreKeysTableReferences
                        ._contactIdTable(db),
                    referencedColumn:
                        $$SignalContactSignedPreKeysTableReferences
                            ._contactIdTable(db)
                            .userId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SignalContactSignedPreKeysTableProcessedTableManager
    = ProcessedTableManager<
        _$TwonlyDB,
        $SignalContactSignedPreKeysTable,
        SignalContactSignedPreKey,
        $$SignalContactSignedPreKeysTableFilterComposer,
        $$SignalContactSignedPreKeysTableOrderingComposer,
        $$SignalContactSignedPreKeysTableAnnotationComposer,
        $$SignalContactSignedPreKeysTableCreateCompanionBuilder,
        $$SignalContactSignedPreKeysTableUpdateCompanionBuilder,
        (
          SignalContactSignedPreKey,
          $$SignalContactSignedPreKeysTableReferences
        ),
        SignalContactSignedPreKey,
        PrefetchHooks Function({bool contactId})>;
typedef $$MessageActionsTableCreateCompanionBuilder = MessageActionsCompanion
    Function({
  required String messageId,
  required int contactId,
  required MessageActionType type,
  Value<DateTime> actionAt,
  Value<int> rowid,
});
typedef $$MessageActionsTableUpdateCompanionBuilder = MessageActionsCompanion
    Function({
  Value<String> messageId,
  Value<int> contactId,
  Value<MessageActionType> type,
  Value<DateTime> actionAt,
  Value<int> rowid,
});

final class $$MessageActionsTableReferences
    extends BaseReferences<_$TwonlyDB, $MessageActionsTable, MessageAction> {
  $$MessageActionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $MessagesTable _messageIdTable(_$TwonlyDB db) =>
      db.messages.createAlias($_aliasNameGenerator(
          db.messageActions.messageId, db.messages.messageId));

  $$MessagesTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$MessagesTableTableManager($_db, $_db.messages)
        .filter((f) => f.messageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContactsTable _contactIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias($_aliasNameGenerator(
          db.messageActions.contactId, db.contacts.userId));

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<int>('contact_id')!;

    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MessageActionsTableFilterComposer
    extends Composer<_$TwonlyDB, $MessageActionsTable> {
  $$MessageActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<MessageActionType, MessageActionType, String>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get actionAt => $composableBuilder(
      column: $table.actionAt, builder: (column) => ColumnFilters(column));

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessageActionsTableOrderingComposer
    extends Composer<_$TwonlyDB, $MessageActionsTable> {
  $$MessageActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get actionAt => $composableBuilder(
      column: $table.actionAt, builder: (column) => ColumnOrderings(column));

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableOrderingComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessageActionsTableAnnotationComposer
    extends Composer<_$TwonlyDB, $MessageActionsTable> {
  $$MessageActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<MessageActionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get actionAt =>
      $composableBuilder(column: $table.actionAt, builder: (column) => column);

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessageActionsTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $MessageActionsTable,
    MessageAction,
    $$MessageActionsTableFilterComposer,
    $$MessageActionsTableOrderingComposer,
    $$MessageActionsTableAnnotationComposer,
    $$MessageActionsTableCreateCompanionBuilder,
    $$MessageActionsTableUpdateCompanionBuilder,
    (MessageAction, $$MessageActionsTableReferences),
    MessageAction,
    PrefetchHooks Function({bool messageId, bool contactId})> {
  $$MessageActionsTableTableManager(_$TwonlyDB db, $MessageActionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> messageId = const Value.absent(),
            Value<int> contactId = const Value.absent(),
            Value<MessageActionType> type = const Value.absent(),
            Value<DateTime> actionAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessageActionsCompanion(
            messageId: messageId,
            contactId: contactId,
            type: type,
            actionAt: actionAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String messageId,
            required int contactId,
            required MessageActionType type,
            Value<DateTime> actionAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessageActionsCompanion.insert(
            messageId: messageId,
            contactId: contactId,
            type: type,
            actionAt: actionAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MessageActionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({messageId = false, contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (messageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.messageId,
                    referencedTable:
                        $$MessageActionsTableReferences._messageIdTable(db),
                    referencedColumn: $$MessageActionsTableReferences
                        ._messageIdTable(db)
                        .messageId,
                  ) as T;
                }
                if (contactId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contactId,
                    referencedTable:
                        $$MessageActionsTableReferences._contactIdTable(db),
                    referencedColumn: $$MessageActionsTableReferences
                        ._contactIdTable(db)
                        .userId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MessageActionsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $MessageActionsTable,
    MessageAction,
    $$MessageActionsTableFilterComposer,
    $$MessageActionsTableOrderingComposer,
    $$MessageActionsTableAnnotationComposer,
    $$MessageActionsTableCreateCompanionBuilder,
    $$MessageActionsTableUpdateCompanionBuilder,
    (MessageAction, $$MessageActionsTableReferences),
    MessageAction,
    PrefetchHooks Function({bool messageId, bool contactId})>;
typedef $$GroupHistoriesTableCreateCompanionBuilder = GroupHistoriesCompanion
    Function({
  required String groupHistoryId,
  required String groupId,
  Value<int?> contactId,
  Value<int?> affectedContactId,
  Value<String?> oldGroupName,
  Value<String?> newGroupName,
  Value<int?> newDeleteMessagesAfterMilliseconds,
  required GroupActionType type,
  Value<DateTime> actionAt,
  Value<int> rowid,
});
typedef $$GroupHistoriesTableUpdateCompanionBuilder = GroupHistoriesCompanion
    Function({
  Value<String> groupHistoryId,
  Value<String> groupId,
  Value<int?> contactId,
  Value<int?> affectedContactId,
  Value<String?> oldGroupName,
  Value<String?> newGroupName,
  Value<int?> newDeleteMessagesAfterMilliseconds,
  Value<GroupActionType> type,
  Value<DateTime> actionAt,
  Value<int> rowid,
});

final class $$GroupHistoriesTableReferences
    extends BaseReferences<_$TwonlyDB, $GroupHistoriesTable, GroupHistory> {
  $$GroupHistoriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$TwonlyDB db) => db.groups.createAlias(
      $_aliasNameGenerator(db.groupHistories.groupId, db.groups.groupId));

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager($_db, $_db.groups)
        .filter((f) => f.groupId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContactsTable _contactIdTable(_$TwonlyDB db) =>
      db.contacts.createAlias($_aliasNameGenerator(
          db.groupHistories.contactId, db.contacts.userId));

  $$ContactsTableProcessedTableManager? get contactId {
    final $_column = $_itemColumn<int>('contact_id');
    if ($_column == null) return null;
    final manager = $$ContactsTableTableManager($_db, $_db.contacts)
        .filter((f) => f.userId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GroupHistoriesTableFilterComposer
    extends Composer<_$TwonlyDB, $GroupHistoriesTable> {
  $$GroupHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupHistoryId => $composableBuilder(
      column: $table.groupHistoryId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get affectedContactId => $composableBuilder(
      column: $table.affectedContactId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oldGroupName => $composableBuilder(
      column: $table.oldGroupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get newGroupName => $composableBuilder(
      column: $table.newGroupName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newDeleteMessagesAfterMilliseconds =>
      $composableBuilder(
          column: $table.newDeleteMessagesAfterMilliseconds,
          builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GroupActionType, GroupActionType, String>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get actionAt => $composableBuilder(
      column: $table.actionAt, builder: (column) => ColumnFilters(column));

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableFilterComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableFilterComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupHistoriesTableOrderingComposer
    extends Composer<_$TwonlyDB, $GroupHistoriesTable> {
  $$GroupHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupHistoryId => $composableBuilder(
      column: $table.groupHistoryId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get affectedContactId => $composableBuilder(
      column: $table.affectedContactId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oldGroupName => $composableBuilder(
      column: $table.oldGroupName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get newGroupName => $composableBuilder(
      column: $table.newGroupName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newDeleteMessagesAfterMilliseconds =>
      $composableBuilder(
          column: $table.newDeleteMessagesAfterMilliseconds,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get actionAt => $composableBuilder(
      column: $table.actionAt, builder: (column) => ColumnOrderings(column));

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableOrderingComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableOrderingComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupHistoriesTableAnnotationComposer
    extends Composer<_$TwonlyDB, $GroupHistoriesTable> {
  $$GroupHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupHistoryId => $composableBuilder(
      column: $table.groupHistoryId, builder: (column) => column);

  GeneratedColumn<int> get affectedContactId => $composableBuilder(
      column: $table.affectedContactId, builder: (column) => column);

  GeneratedColumn<String> get oldGroupName => $composableBuilder(
      column: $table.oldGroupName, builder: (column) => column);

  GeneratedColumn<String> get newGroupName => $composableBuilder(
      column: $table.newGroupName, builder: (column) => column);

  GeneratedColumn<int> get newDeleteMessagesAfterMilliseconds =>
      $composableBuilder(
          column: $table.newDeleteMessagesAfterMilliseconds,
          builder: (column) => column);

  GeneratedColumnWithTypeConverter<GroupActionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get actionAt =>
      $composableBuilder(column: $table.actionAt, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.groups,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupsTableAnnotationComposer(
              $db: $db,
              $table: $db.groups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contactId,
        referencedTable: $db.contacts,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContactsTableAnnotationComposer(
              $db: $db,
              $table: $db.contacts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupHistoriesTableTableManager extends RootTableManager<
    _$TwonlyDB,
    $GroupHistoriesTable,
    GroupHistory,
    $$GroupHistoriesTableFilterComposer,
    $$GroupHistoriesTableOrderingComposer,
    $$GroupHistoriesTableAnnotationComposer,
    $$GroupHistoriesTableCreateCompanionBuilder,
    $$GroupHistoriesTableUpdateCompanionBuilder,
    (GroupHistory, $$GroupHistoriesTableReferences),
    GroupHistory,
    PrefetchHooks Function({bool groupId, bool contactId})> {
  $$GroupHistoriesTableTableManager(_$TwonlyDB db, $GroupHistoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> groupHistoryId = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<int?> contactId = const Value.absent(),
            Value<int?> affectedContactId = const Value.absent(),
            Value<String?> oldGroupName = const Value.absent(),
            Value<String?> newGroupName = const Value.absent(),
            Value<int?> newDeleteMessagesAfterMilliseconds =
                const Value.absent(),
            Value<GroupActionType> type = const Value.absent(),
            Value<DateTime> actionAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupHistoriesCompanion(
            groupHistoryId: groupHistoryId,
            groupId: groupId,
            contactId: contactId,
            affectedContactId: affectedContactId,
            oldGroupName: oldGroupName,
            newGroupName: newGroupName,
            newDeleteMessagesAfterMilliseconds:
                newDeleteMessagesAfterMilliseconds,
            type: type,
            actionAt: actionAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String groupHistoryId,
            required String groupId,
            Value<int?> contactId = const Value.absent(),
            Value<int?> affectedContactId = const Value.absent(),
            Value<String?> oldGroupName = const Value.absent(),
            Value<String?> newGroupName = const Value.absent(),
            Value<int?> newDeleteMessagesAfterMilliseconds =
                const Value.absent(),
            required GroupActionType type,
            Value<DateTime> actionAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupHistoriesCompanion.insert(
            groupHistoryId: groupHistoryId,
            groupId: groupId,
            contactId: contactId,
            affectedContactId: affectedContactId,
            oldGroupName: oldGroupName,
            newGroupName: newGroupName,
            newDeleteMessagesAfterMilliseconds:
                newDeleteMessagesAfterMilliseconds,
            type: type,
            actionAt: actionAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GroupHistoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({groupId = false, contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (groupId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.groupId,
                    referencedTable:
                        $$GroupHistoriesTableReferences._groupIdTable(db),
                    referencedColumn: $$GroupHistoriesTableReferences
                        ._groupIdTable(db)
                        .groupId,
                  ) as T;
                }
                if (contactId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contactId,
                    referencedTable:
                        $$GroupHistoriesTableReferences._contactIdTable(db),
                    referencedColumn: $$GroupHistoriesTableReferences
                        ._contactIdTable(db)
                        .userId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GroupHistoriesTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDB,
    $GroupHistoriesTable,
    GroupHistory,
    $$GroupHistoriesTableFilterComposer,
    $$GroupHistoriesTableOrderingComposer,
    $$GroupHistoriesTableAnnotationComposer,
    $$GroupHistoriesTableCreateCompanionBuilder,
    $$GroupHistoriesTableUpdateCompanionBuilder,
    (GroupHistory, $$GroupHistoriesTableReferences),
    GroupHistory,
    PrefetchHooks Function({bool groupId, bool contactId})>;

class $TwonlyDBManager {
  final _$TwonlyDB _db;
  $TwonlyDBManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db, _db.mediaFiles);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageHistoriesTableTableManager get messageHistories =>
      $$MessageHistoriesTableTableManager(_db, _db.messageHistories);
  $$ReactionsTableTableManager get reactions =>
      $$ReactionsTableTableManager(_db, _db.reactions);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ReceivedReceiptsTableTableManager get receivedReceipts =>
      $$ReceivedReceiptsTableTableManager(_db, _db.receivedReceipts);
  $$SignalIdentityKeyStoresTableTableManager get signalIdentityKeyStores =>
      $$SignalIdentityKeyStoresTableTableManager(
          _db, _db.signalIdentityKeyStores);
  $$SignalPreKeyStoresTableTableManager get signalPreKeyStores =>
      $$SignalPreKeyStoresTableTableManager(_db, _db.signalPreKeyStores);
  $$SignalSenderKeyStoresTableTableManager get signalSenderKeyStores =>
      $$SignalSenderKeyStoresTableTableManager(_db, _db.signalSenderKeyStores);
  $$SignalSessionStoresTableTableManager get signalSessionStores =>
      $$SignalSessionStoresTableTableManager(_db, _db.signalSessionStores);
  $$SignalContactPreKeysTableTableManager get signalContactPreKeys =>
      $$SignalContactPreKeysTableTableManager(_db, _db.signalContactPreKeys);
  $$SignalContactSignedPreKeysTableTableManager
      get signalContactSignedPreKeys =>
          $$SignalContactSignedPreKeysTableTableManager(
              _db, _db.signalContactSignedPreKeys);
  $$MessageActionsTableTableManager get messageActions =>
      $$MessageActionsTableTableManager(_db, _db.messageActions);
  $$GroupHistoriesTableTableManager get groupHistories =>
      $$GroupHistoriesTableTableManager(_db, _db.groupHistories);
}
