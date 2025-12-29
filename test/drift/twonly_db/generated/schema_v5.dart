// dart format width=80
import 'dart:typed_data' as i2;
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Contacts extends Table with TableInfo<Contacts, ContactsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Contacts(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> nickName = GeneratedColumn<String>(
      'nick_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<i2.Uint8List> avatarSvgCompressed =
      GeneratedColumn<i2.Uint8List>('avatar_svg_compressed', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<int> senderProfileCounter = GeneratedColumn<int>(
      'sender_profile_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> accepted = GeneratedColumn<bool>(
      'accepted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("accepted" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> deletedByUser = GeneratedColumn<bool>(
      'deleted_by_user', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("deleted_by_user" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> requested = GeneratedColumn<bool>(
      'requested', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("requested" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> blocked = GeneratedColumn<bool>(
      'blocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("blocked" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
      'verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("verified" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> accountDeleted = GeneratedColumn<bool>(
      'account_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("account_deleted" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
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
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  ContactsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactsData(
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
  Contacts createAlias(String alias) {
    return Contacts(attachedDatabase, alias);
  }
}

class ContactsData extends DataClass implements Insertable<ContactsData> {
  final int userId;
  final String username;
  final String? displayName;
  final String? nickName;
  final i2.Uint8List? avatarSvgCompressed;
  final int senderProfileCounter;
  final bool accepted;
  final bool deletedByUser;
  final bool requested;
  final bool blocked;
  final bool verified;
  final bool accountDeleted;
  final DateTime createdAt;
  const ContactsData(
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
      map['avatar_svg_compressed'] =
          Variable<i2.Uint8List>(avatarSvgCompressed);
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

  factory ContactsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactsData(
      userId: serializer.fromJson<int>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      nickName: serializer.fromJson<String?>(json['nickName']),
      avatarSvgCompressed:
          serializer.fromJson<i2.Uint8List?>(json['avatarSvgCompressed']),
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
      'avatarSvgCompressed':
          serializer.toJson<i2.Uint8List?>(avatarSvgCompressed),
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

  ContactsData copyWith(
          {int? userId,
          String? username,
          Value<String?> displayName = const Value.absent(),
          Value<String?> nickName = const Value.absent(),
          Value<i2.Uint8List?> avatarSvgCompressed = const Value.absent(),
          int? senderProfileCounter,
          bool? accepted,
          bool? deletedByUser,
          bool? requested,
          bool? blocked,
          bool? verified,
          bool? accountDeleted,
          DateTime? createdAt}) =>
      ContactsData(
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
  ContactsData copyWithCompanion(ContactsCompanion data) {
    return ContactsData(
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
    return (StringBuffer('ContactsData(')
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
      (other is ContactsData &&
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

class ContactsCompanion extends UpdateCompanion<ContactsData> {
  final Value<int> userId;
  final Value<String> username;
  final Value<String?> displayName;
  final Value<String?> nickName;
  final Value<i2.Uint8List?> avatarSvgCompressed;
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
  static Insertable<ContactsData> custom({
    Expression<int>? userId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? nickName,
    Expression<i2.Uint8List>? avatarSvgCompressed,
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
      Value<i2.Uint8List?>? avatarSvgCompressed,
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
          Variable<i2.Uint8List>(avatarSvgCompressed.value);
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

class Groups extends Table with TableInfo<Groups, GroupsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Groups(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<bool> isGroupAdmin = GeneratedColumn<bool>(
      'is_group_admin', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_group_admin" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> isDirectChat = GeneratedColumn<bool>(
      'is_direct_chat', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_direct_chat" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> joinedGroup = GeneratedColumn<bool>(
      'joined_group', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("joined_group" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> leftGroup = GeneratedColumn<bool>(
      'left_group', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("left_group" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> deletedContent = GeneratedColumn<bool>(
      'deleted_content', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("deleted_content" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> stateVersionId = GeneratedColumn<int>(
      'state_version_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<i2.Uint8List> stateEncryptionKey =
      GeneratedColumn<i2.Uint8List>('state_encryption_key', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<i2.Uint8List> myGroupPrivateKey =
      GeneratedColumn<i2.Uint8List>('my_group_private_key', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
      'group_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> draftMessage = GeneratedColumn<String>(
      'draft_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<int> totalMediaCounter = GeneratedColumn<int>(
      'total_media_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> alsoBestFriend = GeneratedColumn<bool>(
      'also_best_friend', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("also_best_friend" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> deleteMessagesAfterMilliseconds =
      GeneratedColumn<int>(
          'delete_messages_after_milliseconds', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const CustomExpression('86400000'));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  late final GeneratedColumn<DateTime> lastMessageSend =
      GeneratedColumn<DateTime>('last_message_send', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastMessageReceived =
      GeneratedColumn<DateTime>('last_message_received', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastFlameCounterChange =
      GeneratedColumn<DateTime>('last_flame_counter_change', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastFlameSync =
      GeneratedColumn<DateTime>('last_flame_sync', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<int> flameCounter = GeneratedColumn<int>(
      'flame_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> maxFlameCounter = GeneratedColumn<int>(
      'max_flame_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<DateTime> maxFlameCounterFrom =
      GeneratedColumn<DateTime>('max_flame_counter_from', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastMessageExchange =
      GeneratedColumn<DateTime>('last_message_exchange', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: const CustomExpression(
              'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
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
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  GroupsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupsData(
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
  Groups createAlias(String alias) {
    return Groups(attachedDatabase, alias);
  }
}

class GroupsData extends DataClass implements Insertable<GroupsData> {
  final String groupId;
  final bool isGroupAdmin;
  final bool isDirectChat;
  final bool pinned;
  final bool archived;
  final bool joinedGroup;
  final bool leftGroup;
  final bool deletedContent;
  final int stateVersionId;
  final i2.Uint8List? stateEncryptionKey;
  final i2.Uint8List? myGroupPrivateKey;
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
  const GroupsData(
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
      map['state_encryption_key'] = Variable<i2.Uint8List>(stateEncryptionKey);
    }
    if (!nullToAbsent || myGroupPrivateKey != null) {
      map['my_group_private_key'] = Variable<i2.Uint8List>(myGroupPrivateKey);
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

  factory GroupsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupsData(
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
          serializer.fromJson<i2.Uint8List?>(json['stateEncryptionKey']),
      myGroupPrivateKey:
          serializer.fromJson<i2.Uint8List?>(json['myGroupPrivateKey']),
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
      'stateEncryptionKey':
          serializer.toJson<i2.Uint8List?>(stateEncryptionKey),
      'myGroupPrivateKey': serializer.toJson<i2.Uint8List?>(myGroupPrivateKey),
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

  GroupsData copyWith(
          {String? groupId,
          bool? isGroupAdmin,
          bool? isDirectChat,
          bool? pinned,
          bool? archived,
          bool? joinedGroup,
          bool? leftGroup,
          bool? deletedContent,
          int? stateVersionId,
          Value<i2.Uint8List?> stateEncryptionKey = const Value.absent(),
          Value<i2.Uint8List?> myGroupPrivateKey = const Value.absent(),
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
      GroupsData(
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
  GroupsData copyWithCompanion(GroupsCompanion data) {
    return GroupsData(
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
    return (StringBuffer('GroupsData(')
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
      (other is GroupsData &&
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

class GroupsCompanion extends UpdateCompanion<GroupsData> {
  final Value<String> groupId;
  final Value<bool> isGroupAdmin;
  final Value<bool> isDirectChat;
  final Value<bool> pinned;
  final Value<bool> archived;
  final Value<bool> joinedGroup;
  final Value<bool> leftGroup;
  final Value<bool> deletedContent;
  final Value<int> stateVersionId;
  final Value<i2.Uint8List?> stateEncryptionKey;
  final Value<i2.Uint8List?> myGroupPrivateKey;
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
  static Insertable<GroupsData> custom({
    Expression<String>? groupId,
    Expression<bool>? isGroupAdmin,
    Expression<bool>? isDirectChat,
    Expression<bool>? pinned,
    Expression<bool>? archived,
    Expression<bool>? joinedGroup,
    Expression<bool>? leftGroup,
    Expression<bool>? deletedContent,
    Expression<int>? stateVersionId,
    Expression<i2.Uint8List>? stateEncryptionKey,
    Expression<i2.Uint8List>? myGroupPrivateKey,
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
      Value<i2.Uint8List?>? stateEncryptionKey,
      Value<i2.Uint8List?>? myGroupPrivateKey,
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
          Variable<i2.Uint8List>(stateEncryptionKey.value);
    }
    if (myGroupPrivateKey.present) {
      map['my_group_private_key'] =
          Variable<i2.Uint8List>(myGroupPrivateKey.value);
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

class MediaFiles extends Table with TableInfo<MediaFiles, MediaFilesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MediaFiles(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> uploadState = GeneratedColumn<String>(
      'upload_state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> downloadState = GeneratedColumn<String>(
      'download_state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<bool> requiresAuthentication =
      GeneratedColumn<bool>('requires_authentication', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("requires_authentication" IN (0, 1))'),
          defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> stored = GeneratedColumn<bool>(
      'stored', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("stored" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> isDraftMedia = GeneratedColumn<bool>(
      'is_draft_media', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_draft_media" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> reuploadRequestedBy =
      GeneratedColumn<String>('reupload_requested_by', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<int> displayLimitInMilliseconds =
      GeneratedColumn<int>('display_limit_in_milliseconds', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<bool> removeAudio = GeneratedColumn<bool>(
      'remove_audio', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("remove_audio" IN (0, 1))'));
  late final GeneratedColumn<i2.Uint8List> downloadToken =
      GeneratedColumn<i2.Uint8List>('download_token', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<i2.Uint8List> encryptionKey =
      GeneratedColumn<i2.Uint8List>('encryption_key', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<i2.Uint8List> encryptionMac =
      GeneratedColumn<i2.Uint8List>('encryption_mac', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<i2.Uint8List> encryptionNonce =
      GeneratedColumn<i2.Uint8List>('encryption_nonce', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<i2.Uint8List> storedFileHash =
      GeneratedColumn<i2.Uint8List>('stored_file_hash', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
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
  Set<GeneratedColumn> get $primaryKey => {mediaId};
  @override
  MediaFilesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaFilesData(
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      uploadState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}upload_state']),
      downloadState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}download_state']),
      requiresAuthentication: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}requires_authentication'])!,
      stored: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}stored'])!,
      isDraftMedia: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_draft_media'])!,
      reuploadRequestedBy: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reupload_requested_by']),
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
  MediaFiles createAlias(String alias) {
    return MediaFiles(attachedDatabase, alias);
  }
}

class MediaFilesData extends DataClass implements Insertable<MediaFilesData> {
  final String mediaId;
  final String type;
  final String? uploadState;
  final String? downloadState;
  final bool requiresAuthentication;
  final bool stored;
  final bool isDraftMedia;
  final String? reuploadRequestedBy;
  final int? displayLimitInMilliseconds;
  final bool? removeAudio;
  final i2.Uint8List? downloadToken;
  final i2.Uint8List? encryptionKey;
  final i2.Uint8List? encryptionMac;
  final i2.Uint8List? encryptionNonce;
  final i2.Uint8List? storedFileHash;
  final DateTime createdAt;
  const MediaFilesData(
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
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || uploadState != null) {
      map['upload_state'] = Variable<String>(uploadState);
    }
    if (!nullToAbsent || downloadState != null) {
      map['download_state'] = Variable<String>(downloadState);
    }
    map['requires_authentication'] = Variable<bool>(requiresAuthentication);
    map['stored'] = Variable<bool>(stored);
    map['is_draft_media'] = Variable<bool>(isDraftMedia);
    if (!nullToAbsent || reuploadRequestedBy != null) {
      map['reupload_requested_by'] = Variable<String>(reuploadRequestedBy);
    }
    if (!nullToAbsent || displayLimitInMilliseconds != null) {
      map['display_limit_in_milliseconds'] =
          Variable<int>(displayLimitInMilliseconds);
    }
    if (!nullToAbsent || removeAudio != null) {
      map['remove_audio'] = Variable<bool>(removeAudio);
    }
    if (!nullToAbsent || downloadToken != null) {
      map['download_token'] = Variable<i2.Uint8List>(downloadToken);
    }
    if (!nullToAbsent || encryptionKey != null) {
      map['encryption_key'] = Variable<i2.Uint8List>(encryptionKey);
    }
    if (!nullToAbsent || encryptionMac != null) {
      map['encryption_mac'] = Variable<i2.Uint8List>(encryptionMac);
    }
    if (!nullToAbsent || encryptionNonce != null) {
      map['encryption_nonce'] = Variable<i2.Uint8List>(encryptionNonce);
    }
    if (!nullToAbsent || storedFileHash != null) {
      map['stored_file_hash'] = Variable<i2.Uint8List>(storedFileHash);
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

  factory MediaFilesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaFilesData(
      mediaId: serializer.fromJson<String>(json['mediaId']),
      type: serializer.fromJson<String>(json['type']),
      uploadState: serializer.fromJson<String?>(json['uploadState']),
      downloadState: serializer.fromJson<String?>(json['downloadState']),
      requiresAuthentication:
          serializer.fromJson<bool>(json['requiresAuthentication']),
      stored: serializer.fromJson<bool>(json['stored']),
      isDraftMedia: serializer.fromJson<bool>(json['isDraftMedia']),
      reuploadRequestedBy:
          serializer.fromJson<String?>(json['reuploadRequestedBy']),
      displayLimitInMilliseconds:
          serializer.fromJson<int?>(json['displayLimitInMilliseconds']),
      removeAudio: serializer.fromJson<bool?>(json['removeAudio']),
      downloadToken: serializer.fromJson<i2.Uint8List?>(json['downloadToken']),
      encryptionKey: serializer.fromJson<i2.Uint8List?>(json['encryptionKey']),
      encryptionMac: serializer.fromJson<i2.Uint8List?>(json['encryptionMac']),
      encryptionNonce:
          serializer.fromJson<i2.Uint8List?>(json['encryptionNonce']),
      storedFileHash:
          serializer.fromJson<i2.Uint8List?>(json['storedFileHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<String>(mediaId),
      'type': serializer.toJson<String>(type),
      'uploadState': serializer.toJson<String?>(uploadState),
      'downloadState': serializer.toJson<String?>(downloadState),
      'requiresAuthentication': serializer.toJson<bool>(requiresAuthentication),
      'stored': serializer.toJson<bool>(stored),
      'isDraftMedia': serializer.toJson<bool>(isDraftMedia),
      'reuploadRequestedBy': serializer.toJson<String?>(reuploadRequestedBy),
      'displayLimitInMilliseconds':
          serializer.toJson<int?>(displayLimitInMilliseconds),
      'removeAudio': serializer.toJson<bool?>(removeAudio),
      'downloadToken': serializer.toJson<i2.Uint8List?>(downloadToken),
      'encryptionKey': serializer.toJson<i2.Uint8List?>(encryptionKey),
      'encryptionMac': serializer.toJson<i2.Uint8List?>(encryptionMac),
      'encryptionNonce': serializer.toJson<i2.Uint8List?>(encryptionNonce),
      'storedFileHash': serializer.toJson<i2.Uint8List?>(storedFileHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MediaFilesData copyWith(
          {String? mediaId,
          String? type,
          Value<String?> uploadState = const Value.absent(),
          Value<String?> downloadState = const Value.absent(),
          bool? requiresAuthentication,
          bool? stored,
          bool? isDraftMedia,
          Value<String?> reuploadRequestedBy = const Value.absent(),
          Value<int?> displayLimitInMilliseconds = const Value.absent(),
          Value<bool?> removeAudio = const Value.absent(),
          Value<i2.Uint8List?> downloadToken = const Value.absent(),
          Value<i2.Uint8List?> encryptionKey = const Value.absent(),
          Value<i2.Uint8List?> encryptionMac = const Value.absent(),
          Value<i2.Uint8List?> encryptionNonce = const Value.absent(),
          Value<i2.Uint8List?> storedFileHash = const Value.absent(),
          DateTime? createdAt}) =>
      MediaFilesData(
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
  MediaFilesData copyWithCompanion(MediaFilesCompanion data) {
    return MediaFilesData(
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
    return (StringBuffer('MediaFilesData(')
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
      (other is MediaFilesData &&
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

class MediaFilesCompanion extends UpdateCompanion<MediaFilesData> {
  final Value<String> mediaId;
  final Value<String> type;
  final Value<String?> uploadState;
  final Value<String?> downloadState;
  final Value<bool> requiresAuthentication;
  final Value<bool> stored;
  final Value<bool> isDraftMedia;
  final Value<String?> reuploadRequestedBy;
  final Value<int?> displayLimitInMilliseconds;
  final Value<bool?> removeAudio;
  final Value<i2.Uint8List?> downloadToken;
  final Value<i2.Uint8List?> encryptionKey;
  final Value<i2.Uint8List?> encryptionMac;
  final Value<i2.Uint8List?> encryptionNonce;
  final Value<i2.Uint8List?> storedFileHash;
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
    required String type,
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
  static Insertable<MediaFilesData> custom({
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
    Expression<i2.Uint8List>? downloadToken,
    Expression<i2.Uint8List>? encryptionKey,
    Expression<i2.Uint8List>? encryptionMac,
    Expression<i2.Uint8List>? encryptionNonce,
    Expression<i2.Uint8List>? storedFileHash,
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
      Value<String>? type,
      Value<String?>? uploadState,
      Value<String?>? downloadState,
      Value<bool>? requiresAuthentication,
      Value<bool>? stored,
      Value<bool>? isDraftMedia,
      Value<String?>? reuploadRequestedBy,
      Value<int?>? displayLimitInMilliseconds,
      Value<bool?>? removeAudio,
      Value<i2.Uint8List?>? downloadToken,
      Value<i2.Uint8List?>? encryptionKey,
      Value<i2.Uint8List?>? encryptionMac,
      Value<i2.Uint8List?>? encryptionNonce,
      Value<i2.Uint8List?>? storedFileHash,
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
      map['type'] = Variable<String>(type.value);
    }
    if (uploadState.present) {
      map['upload_state'] = Variable<String>(uploadState.value);
    }
    if (downloadState.present) {
      map['download_state'] = Variable<String>(downloadState.value);
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
      map['reupload_requested_by'] =
          Variable<String>(reuploadRequestedBy.value);
    }
    if (displayLimitInMilliseconds.present) {
      map['display_limit_in_milliseconds'] =
          Variable<int>(displayLimitInMilliseconds.value);
    }
    if (removeAudio.present) {
      map['remove_audio'] = Variable<bool>(removeAudio.value);
    }
    if (downloadToken.present) {
      map['download_token'] = Variable<i2.Uint8List>(downloadToken.value);
    }
    if (encryptionKey.present) {
      map['encryption_key'] = Variable<i2.Uint8List>(encryptionKey.value);
    }
    if (encryptionMac.present) {
      map['encryption_mac'] = Variable<i2.Uint8List>(encryptionMac.value);
    }
    if (encryptionNonce.present) {
      map['encryption_nonce'] = Variable<i2.Uint8List>(encryptionNonce.value);
    }
    if (storedFileHash.present) {
      map['stored_file_hash'] = Variable<i2.Uint8List>(storedFileHash.value);
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

class Messages extends Table with TableInfo<Messages, MessagesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Messages(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES "groups" (group_id) ON DELETE CASCADE'));
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
      'sender_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (user_id)'));
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
      'media_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES media_files (media_id) ON DELETE SET NULL'));
  late final GeneratedColumn<bool> mediaStored = GeneratedColumn<bool>(
      'media_stored', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("media_stored" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> mediaReopened = GeneratedColumn<bool>(
      'media_reopened', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("media_reopened" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<i2.Uint8List> downloadToken =
      GeneratedColumn<i2.Uint8List>('download_token', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<String> quotesMessageId = GeneratedColumn<String>(
      'quotes_message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<bool> isDeletedFromSender = GeneratedColumn<bool>(
      'is_deleted_from_sender', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_deleted_from_sender" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> openedByAll = GeneratedColumn<DateTime>(
      'opened_by_all', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
      'modified_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> ackByUser = GeneratedColumn<DateTime>(
      'ack_by_user', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MessagesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesData(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      senderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sender_id']),
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      mediaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_id']),
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
  Messages createAlias(String alias) {
    return Messages(attachedDatabase, alias);
  }
}

class MessagesData extends DataClass implements Insertable<MessagesData> {
  final String groupId;
  final String messageId;
  final int? senderId;
  final String type;
  final String? content;
  final String? mediaId;
  final bool mediaStored;
  final bool mediaReopened;
  final i2.Uint8List? downloadToken;
  final String? quotesMessageId;
  final bool isDeletedFromSender;
  final DateTime? openedAt;
  final DateTime? openedByAll;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final DateTime? ackByUser;
  final DateTime? ackByServer;
  const MessagesData(
      {required this.groupId,
      required this.messageId,
      this.senderId,
      required this.type,
      this.content,
      this.mediaId,
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
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || mediaId != null) {
      map['media_id'] = Variable<String>(mediaId);
    }
    map['media_stored'] = Variable<bool>(mediaStored);
    map['media_reopened'] = Variable<bool>(mediaReopened);
    if (!nullToAbsent || downloadToken != null) {
      map['download_token'] = Variable<i2.Uint8List>(downloadToken);
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

  factory MessagesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesData(
      groupId: serializer.fromJson<String>(json['groupId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      senderId: serializer.fromJson<int?>(json['senderId']),
      type: serializer.fromJson<String>(json['type']),
      content: serializer.fromJson<String?>(json['content']),
      mediaId: serializer.fromJson<String?>(json['mediaId']),
      mediaStored: serializer.fromJson<bool>(json['mediaStored']),
      mediaReopened: serializer.fromJson<bool>(json['mediaReopened']),
      downloadToken: serializer.fromJson<i2.Uint8List?>(json['downloadToken']),
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
      'type': serializer.toJson<String>(type),
      'content': serializer.toJson<String?>(content),
      'mediaId': serializer.toJson<String?>(mediaId),
      'mediaStored': serializer.toJson<bool>(mediaStored),
      'mediaReopened': serializer.toJson<bool>(mediaReopened),
      'downloadToken': serializer.toJson<i2.Uint8List?>(downloadToken),
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

  MessagesData copyWith(
          {String? groupId,
          String? messageId,
          Value<int?> senderId = const Value.absent(),
          String? type,
          Value<String?> content = const Value.absent(),
          Value<String?> mediaId = const Value.absent(),
          bool? mediaStored,
          bool? mediaReopened,
          Value<i2.Uint8List?> downloadToken = const Value.absent(),
          Value<String?> quotesMessageId = const Value.absent(),
          bool? isDeletedFromSender,
          Value<DateTime?> openedAt = const Value.absent(),
          Value<DateTime?> openedByAll = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> modifiedAt = const Value.absent(),
          Value<DateTime?> ackByUser = const Value.absent(),
          Value<DateTime?> ackByServer = const Value.absent()}) =>
      MessagesData(
        groupId: groupId ?? this.groupId,
        messageId: messageId ?? this.messageId,
        senderId: senderId.present ? senderId.value : this.senderId,
        type: type ?? this.type,
        content: content.present ? content.value : this.content,
        mediaId: mediaId.present ? mediaId.value : this.mediaId,
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
  MessagesData copyWithCompanion(MessagesCompanion data) {
    return MessagesData(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
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
    return (StringBuffer('MessagesData(')
          ..write('groupId: $groupId, ')
          ..write('messageId: $messageId, ')
          ..write('senderId: $senderId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('mediaId: $mediaId, ')
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
      (other is MessagesData &&
          other.groupId == this.groupId &&
          other.messageId == this.messageId &&
          other.senderId == this.senderId &&
          other.type == this.type &&
          other.content == this.content &&
          other.mediaId == this.mediaId &&
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

class MessagesCompanion extends UpdateCompanion<MessagesData> {
  final Value<String> groupId;
  final Value<String> messageId;
  final Value<int?> senderId;
  final Value<String> type;
  final Value<String?> content;
  final Value<String?> mediaId;
  final Value<bool> mediaStored;
  final Value<bool> mediaReopened;
  final Value<i2.Uint8List?> downloadToken;
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
    required String type,
    this.content = const Value.absent(),
    this.mediaId = const Value.absent(),
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
  static Insertable<MessagesData> custom({
    Expression<String>? groupId,
    Expression<String>? messageId,
    Expression<int>? senderId,
    Expression<String>? type,
    Expression<String>? content,
    Expression<String>? mediaId,
    Expression<bool>? mediaStored,
    Expression<bool>? mediaReopened,
    Expression<i2.Uint8List>? downloadToken,
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
      Value<String>? type,
      Value<String?>? content,
      Value<String?>? mediaId,
      Value<bool>? mediaStored,
      Value<bool>? mediaReopened,
      Value<i2.Uint8List?>? downloadToken,
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
      map['type'] = Variable<String>(type.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (mediaStored.present) {
      map['media_stored'] = Variable<bool>(mediaStored.value);
    }
    if (mediaReopened.present) {
      map['media_reopened'] = Variable<bool>(mediaReopened.value);
    }
    if (downloadToken.present) {
      map['download_token'] = Variable<i2.Uint8List>(downloadToken.value);
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

class MessageHistories extends Table
    with TableInfo<MessageHistories, MessageHistoriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MessageHistories(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES messages (message_id) ON DELETE CASCADE'));
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, messageId, contactId, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_histories';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageHistoriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageHistoriesData(
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
  MessageHistories createAlias(String alias) {
    return MessageHistories(attachedDatabase, alias);
  }
}

class MessageHistoriesData extends DataClass
    implements Insertable<MessageHistoriesData> {
  final int id;
  final String messageId;
  final int? contactId;
  final String? content;
  final DateTime createdAt;
  const MessageHistoriesData(
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

  factory MessageHistoriesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageHistoriesData(
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

  MessageHistoriesData copyWith(
          {int? id,
          String? messageId,
          Value<int?> contactId = const Value.absent(),
          Value<String?> content = const Value.absent(),
          DateTime? createdAt}) =>
      MessageHistoriesData(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        contactId: contactId.present ? contactId.value : this.contactId,
        content: content.present ? content.value : this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  MessageHistoriesData copyWithCompanion(MessageHistoriesCompanion data) {
    return MessageHistoriesData(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageHistoriesData(')
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
      (other is MessageHistoriesData &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.contactId == this.contactId &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class MessageHistoriesCompanion extends UpdateCompanion<MessageHistoriesData> {
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
  static Insertable<MessageHistoriesData> custom({
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

class Reactions extends Table with TableInfo<Reactions, ReactionsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Reactions(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES messages (message_id) ON DELETE CASCADE'));
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
      'sender_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns => [messageId, emoji, senderId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, senderId, emoji};
  @override
  ReactionsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReactionsData(
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
  Reactions createAlias(String alias) {
    return Reactions(attachedDatabase, alias);
  }
}

class ReactionsData extends DataClass implements Insertable<ReactionsData> {
  final String messageId;
  final String emoji;
  final int? senderId;
  final DateTime createdAt;
  const ReactionsData(
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

  factory ReactionsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReactionsData(
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

  ReactionsData copyWith(
          {String? messageId,
          String? emoji,
          Value<int?> senderId = const Value.absent(),
          DateTime? createdAt}) =>
      ReactionsData(
        messageId: messageId ?? this.messageId,
        emoji: emoji ?? this.emoji,
        senderId: senderId.present ? senderId.value : this.senderId,
        createdAt: createdAt ?? this.createdAt,
      );
  ReactionsData copyWithCompanion(ReactionsCompanion data) {
    return ReactionsData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReactionsData(')
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
      (other is ReactionsData &&
          other.messageId == this.messageId &&
          other.emoji == this.emoji &&
          other.senderId == this.senderId &&
          other.createdAt == this.createdAt);
}

class ReactionsCompanion extends UpdateCompanion<ReactionsData> {
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
  static Insertable<ReactionsData> custom({
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

class GroupMembers extends Table
    with TableInfo<GroupMembers, GroupMembersData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GroupMembers(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES "groups" (group_id) ON DELETE CASCADE'));
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (user_id)'));
  late final GeneratedColumn<String> memberState = GeneratedColumn<String>(
      'member_state', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<i2.Uint8List> groupPublicKey =
      GeneratedColumn<i2.Uint8List>('group_public_key', aliasedName, true,
          type: DriftSqlType.blob, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastMessage = GeneratedColumn<DateTime>(
      'last_message', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns =>
      [groupId, contactId, memberState, groupPublicKey, lastMessage, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, contactId};
  @override
  GroupMembersData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMembersData(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id'])!,
      memberState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_state']),
      groupPublicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}group_public_key']),
      lastMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  GroupMembers createAlias(String alias) {
    return GroupMembers(attachedDatabase, alias);
  }
}

class GroupMembersData extends DataClass
    implements Insertable<GroupMembersData> {
  final String groupId;
  final int contactId;
  final String? memberState;
  final i2.Uint8List? groupPublicKey;
  final DateTime? lastMessage;
  final DateTime createdAt;
  const GroupMembersData(
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
      map['member_state'] = Variable<String>(memberState);
    }
    if (!nullToAbsent || groupPublicKey != null) {
      map['group_public_key'] = Variable<i2.Uint8List>(groupPublicKey);
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

  factory GroupMembersData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMembersData(
      groupId: serializer.fromJson<String>(json['groupId']),
      contactId: serializer.fromJson<int>(json['contactId']),
      memberState: serializer.fromJson<String?>(json['memberState']),
      groupPublicKey:
          serializer.fromJson<i2.Uint8List?>(json['groupPublicKey']),
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
      'memberState': serializer.toJson<String?>(memberState),
      'groupPublicKey': serializer.toJson<i2.Uint8List?>(groupPublicKey),
      'lastMessage': serializer.toJson<DateTime?>(lastMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GroupMembersData copyWith(
          {String? groupId,
          int? contactId,
          Value<String?> memberState = const Value.absent(),
          Value<i2.Uint8List?> groupPublicKey = const Value.absent(),
          Value<DateTime?> lastMessage = const Value.absent(),
          DateTime? createdAt}) =>
      GroupMembersData(
        groupId: groupId ?? this.groupId,
        contactId: contactId ?? this.contactId,
        memberState: memberState.present ? memberState.value : this.memberState,
        groupPublicKey:
            groupPublicKey.present ? groupPublicKey.value : this.groupPublicKey,
        lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
        createdAt: createdAt ?? this.createdAt,
      );
  GroupMembersData copyWithCompanion(GroupMembersCompanion data) {
    return GroupMembersData(
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
    return (StringBuffer('GroupMembersData(')
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
      (other is GroupMembersData &&
          other.groupId == this.groupId &&
          other.contactId == this.contactId &&
          other.memberState == this.memberState &&
          $driftBlobEquality.equals(
              other.groupPublicKey, this.groupPublicKey) &&
          other.lastMessage == this.lastMessage &&
          other.createdAt == this.createdAt);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMembersData> {
  final Value<String> groupId;
  final Value<int> contactId;
  final Value<String?> memberState;
  final Value<i2.Uint8List?> groupPublicKey;
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
  static Insertable<GroupMembersData> custom({
    Expression<String>? groupId,
    Expression<int>? contactId,
    Expression<String>? memberState,
    Expression<i2.Uint8List>? groupPublicKey,
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
      Value<String?>? memberState,
      Value<i2.Uint8List?>? groupPublicKey,
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
      map['member_state'] = Variable<String>(memberState.value);
    }
    if (groupPublicKey.present) {
      map['group_public_key'] = Variable<i2.Uint8List>(groupPublicKey.value);
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

class Receipts extends Table with TableInfo<Receipts, ReceiptsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Receipts(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
      'receipt_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES messages (message_id) ON DELETE CASCADE'));
  late final GeneratedColumn<i2.Uint8List> message =
      GeneratedColumn<i2.Uint8List>('message', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  late final GeneratedColumn<bool> contactWillSendsReceipt =
      GeneratedColumn<bool>('contact_will_sends_receipt', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("contact_will_sends_receipt" IN (0, 1))'),
          defaultValue: const CustomExpression('1'));
  late final GeneratedColumn<DateTime> markForRetry = GeneratedColumn<DateTime>(
      'mark_for_retry', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> ackByServerAt =
      GeneratedColumn<DateTime>('ack_by_server_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<DateTime> lastRetry = GeneratedColumn<DateTime>(
      'last_retry', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns => [
        receiptId,
        contactId,
        messageId,
        message,
        contactWillSendsReceipt,
        markForRetry,
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
  Set<GeneratedColumn> get $primaryKey => {receiptId};
  @override
  ReceiptsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptsData(
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
  Receipts createAlias(String alias) {
    return Receipts(attachedDatabase, alias);
  }
}

class ReceiptsData extends DataClass implements Insertable<ReceiptsData> {
  final String receiptId;
  final int contactId;
  final String? messageId;
  final i2.Uint8List message;
  final bool contactWillSendsReceipt;
  final DateTime? markForRetry;
  final DateTime? ackByServerAt;
  final int retryCount;
  final DateTime? lastRetry;
  final DateTime createdAt;
  const ReceiptsData(
      {required this.receiptId,
      required this.contactId,
      this.messageId,
      required this.message,
      required this.contactWillSendsReceipt,
      this.markForRetry,
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
    map['message'] = Variable<i2.Uint8List>(message);
    map['contact_will_sends_receipt'] = Variable<bool>(contactWillSendsReceipt);
    if (!nullToAbsent || markForRetry != null) {
      map['mark_for_retry'] = Variable<DateTime>(markForRetry);
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

  factory ReceiptsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptsData(
      receiptId: serializer.fromJson<String>(json['receiptId']),
      contactId: serializer.fromJson<int>(json['contactId']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      message: serializer.fromJson<i2.Uint8List>(json['message']),
      contactWillSendsReceipt:
          serializer.fromJson<bool>(json['contactWillSendsReceipt']),
      markForRetry: serializer.fromJson<DateTime?>(json['markForRetry']),
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
      'message': serializer.toJson<i2.Uint8List>(message),
      'contactWillSendsReceipt':
          serializer.toJson<bool>(contactWillSendsReceipt),
      'markForRetry': serializer.toJson<DateTime?>(markForRetry),
      'ackByServerAt': serializer.toJson<DateTime?>(ackByServerAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastRetry': serializer.toJson<DateTime?>(lastRetry),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReceiptsData copyWith(
          {String? receiptId,
          int? contactId,
          Value<String?> messageId = const Value.absent(),
          i2.Uint8List? message,
          bool? contactWillSendsReceipt,
          Value<DateTime?> markForRetry = const Value.absent(),
          Value<DateTime?> ackByServerAt = const Value.absent(),
          int? retryCount,
          Value<DateTime?> lastRetry = const Value.absent(),
          DateTime? createdAt}) =>
      ReceiptsData(
        receiptId: receiptId ?? this.receiptId,
        contactId: contactId ?? this.contactId,
        messageId: messageId.present ? messageId.value : this.messageId,
        message: message ?? this.message,
        contactWillSendsReceipt:
            contactWillSendsReceipt ?? this.contactWillSendsReceipt,
        markForRetry:
            markForRetry.present ? markForRetry.value : this.markForRetry,
        ackByServerAt:
            ackByServerAt.present ? ackByServerAt.value : this.ackByServerAt,
        retryCount: retryCount ?? this.retryCount,
        lastRetry: lastRetry.present ? lastRetry.value : this.lastRetry,
        createdAt: createdAt ?? this.createdAt,
      );
  ReceiptsData copyWithCompanion(ReceiptsCompanion data) {
    return ReceiptsData(
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
    return (StringBuffer('ReceiptsData(')
          ..write('receiptId: $receiptId, ')
          ..write('contactId: $contactId, ')
          ..write('messageId: $messageId, ')
          ..write('message: $message, ')
          ..write('contactWillSendsReceipt: $contactWillSendsReceipt, ')
          ..write('markForRetry: $markForRetry, ')
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
      ackByServerAt,
      retryCount,
      lastRetry,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptsData &&
          other.receiptId == this.receiptId &&
          other.contactId == this.contactId &&
          other.messageId == this.messageId &&
          $driftBlobEquality.equals(other.message, this.message) &&
          other.contactWillSendsReceipt == this.contactWillSendsReceipt &&
          other.markForRetry == this.markForRetry &&
          other.ackByServerAt == this.ackByServerAt &&
          other.retryCount == this.retryCount &&
          other.lastRetry == this.lastRetry &&
          other.createdAt == this.createdAt);
}

class ReceiptsCompanion extends UpdateCompanion<ReceiptsData> {
  final Value<String> receiptId;
  final Value<int> contactId;
  final Value<String?> messageId;
  final Value<i2.Uint8List> message;
  final Value<bool> contactWillSendsReceipt;
  final Value<DateTime?> markForRetry;
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
    required i2.Uint8List message,
    this.contactWillSendsReceipt = const Value.absent(),
    this.markForRetry = const Value.absent(),
    this.ackByServerAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastRetry = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : receiptId = Value(receiptId),
        contactId = Value(contactId),
        message = Value(message);
  static Insertable<ReceiptsData> custom({
    Expression<String>? receiptId,
    Expression<int>? contactId,
    Expression<String>? messageId,
    Expression<i2.Uint8List>? message,
    Expression<bool>? contactWillSendsReceipt,
    Expression<DateTime>? markForRetry,
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
      Value<i2.Uint8List>? message,
      Value<bool>? contactWillSendsReceipt,
      Value<DateTime?>? markForRetry,
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
      map['message'] = Variable<i2.Uint8List>(message.value);
    }
    if (contactWillSendsReceipt.present) {
      map['contact_will_sends_receipt'] =
          Variable<bool>(contactWillSendsReceipt.value);
    }
    if (markForRetry.present) {
      map['mark_for_retry'] = Variable<DateTime>(markForRetry.value);
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
          ..write('ackByServerAt: $ackByServerAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastRetry: $lastRetry, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ReceivedReceipts extends Table
    with TableInfo<ReceivedReceipts, ReceivedReceiptsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ReceivedReceipts(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
      'receipt_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns => [receiptId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'received_receipts';
  @override
  Set<GeneratedColumn> get $primaryKey => {receiptId};
  @override
  ReceivedReceiptsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceivedReceiptsData(
      receiptId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  ReceivedReceipts createAlias(String alias) {
    return ReceivedReceipts(attachedDatabase, alias);
  }
}

class ReceivedReceiptsData extends DataClass
    implements Insertable<ReceivedReceiptsData> {
  final String receiptId;
  final DateTime createdAt;
  const ReceivedReceiptsData(
      {required this.receiptId, required this.createdAt});
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

  factory ReceivedReceiptsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceivedReceiptsData(
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

  ReceivedReceiptsData copyWith({String? receiptId, DateTime? createdAt}) =>
      ReceivedReceiptsData(
        receiptId: receiptId ?? this.receiptId,
        createdAt: createdAt ?? this.createdAt,
      );
  ReceivedReceiptsData copyWithCompanion(ReceivedReceiptsCompanion data) {
    return ReceivedReceiptsData(
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceivedReceiptsData(')
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
      (other is ReceivedReceiptsData &&
          other.receiptId == this.receiptId &&
          other.createdAt == this.createdAt);
}

class ReceivedReceiptsCompanion extends UpdateCompanion<ReceivedReceiptsData> {
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
  static Insertable<ReceivedReceiptsData> custom({
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

class SignalIdentityKeyStores extends Table
    with TableInfo<SignalIdentityKeyStores, SignalIdentityKeyStoresData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SignalIdentityKeyStores(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
      'device_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<i2.Uint8List> identityKey =
      GeneratedColumn<i2.Uint8List>('identity_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns =>
      [deviceId, name, identityKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_identity_key_stores';
  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, name};
  @override
  SignalIdentityKeyStoresData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalIdentityKeyStoresData(
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
  SignalIdentityKeyStores createAlias(String alias) {
    return SignalIdentityKeyStores(attachedDatabase, alias);
  }
}

class SignalIdentityKeyStoresData extends DataClass
    implements Insertable<SignalIdentityKeyStoresData> {
  final int deviceId;
  final String name;
  final i2.Uint8List identityKey;
  final DateTime createdAt;
  const SignalIdentityKeyStoresData(
      {required this.deviceId,
      required this.name,
      required this.identityKey,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<int>(deviceId);
    map['name'] = Variable<String>(name);
    map['identity_key'] = Variable<i2.Uint8List>(identityKey);
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

  factory SignalIdentityKeyStoresData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalIdentityKeyStoresData(
      deviceId: serializer.fromJson<int>(json['deviceId']),
      name: serializer.fromJson<String>(json['name']),
      identityKey: serializer.fromJson<i2.Uint8List>(json['identityKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<int>(deviceId),
      'name': serializer.toJson<String>(name),
      'identityKey': serializer.toJson<i2.Uint8List>(identityKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalIdentityKeyStoresData copyWith(
          {int? deviceId,
          String? name,
          i2.Uint8List? identityKey,
          DateTime? createdAt}) =>
      SignalIdentityKeyStoresData(
        deviceId: deviceId ?? this.deviceId,
        name: name ?? this.name,
        identityKey: identityKey ?? this.identityKey,
        createdAt: createdAt ?? this.createdAt,
      );
  SignalIdentityKeyStoresData copyWithCompanion(
      SignalIdentityKeyStoresCompanion data) {
    return SignalIdentityKeyStoresData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      identityKey:
          data.identityKey.present ? data.identityKey.value : this.identityKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalIdentityKeyStoresData(')
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
      (other is SignalIdentityKeyStoresData &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          $driftBlobEquality.equals(other.identityKey, this.identityKey) &&
          other.createdAt == this.createdAt);
}

class SignalIdentityKeyStoresCompanion
    extends UpdateCompanion<SignalIdentityKeyStoresData> {
  final Value<int> deviceId;
  final Value<String> name;
  final Value<i2.Uint8List> identityKey;
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
    required i2.Uint8List identityKey,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        name = Value(name),
        identityKey = Value(identityKey);
  static Insertable<SignalIdentityKeyStoresData> custom({
    Expression<int>? deviceId,
    Expression<String>? name,
    Expression<i2.Uint8List>? identityKey,
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
      Value<i2.Uint8List>? identityKey,
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
      map['identity_key'] = Variable<i2.Uint8List>(identityKey.value);
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

class SignalPreKeyStores extends Table
    with TableInfo<SignalPreKeyStores, SignalPreKeyStoresData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SignalPreKeyStores(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> preKeyId = GeneratedColumn<int>(
      'pre_key_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<i2.Uint8List> preKey =
      GeneratedColumn<i2.Uint8List>('pre_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns => [preKeyId, preKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_pre_key_stores';
  @override
  Set<GeneratedColumn> get $primaryKey => {preKeyId};
  @override
  SignalPreKeyStoresData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalPreKeyStoresData(
      preKeyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pre_key_id'])!,
      preKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}pre_key'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  SignalPreKeyStores createAlias(String alias) {
    return SignalPreKeyStores(attachedDatabase, alias);
  }
}

class SignalPreKeyStoresData extends DataClass
    implements Insertable<SignalPreKeyStoresData> {
  final int preKeyId;
  final i2.Uint8List preKey;
  final DateTime createdAt;
  const SignalPreKeyStoresData(
      {required this.preKeyId, required this.preKey, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pre_key_id'] = Variable<int>(preKeyId);
    map['pre_key'] = Variable<i2.Uint8List>(preKey);
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

  factory SignalPreKeyStoresData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalPreKeyStoresData(
      preKeyId: serializer.fromJson<int>(json['preKeyId']),
      preKey: serializer.fromJson<i2.Uint8List>(json['preKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'preKeyId': serializer.toJson<int>(preKeyId),
      'preKey': serializer.toJson<i2.Uint8List>(preKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalPreKeyStoresData copyWith(
          {int? preKeyId, i2.Uint8List? preKey, DateTime? createdAt}) =>
      SignalPreKeyStoresData(
        preKeyId: preKeyId ?? this.preKeyId,
        preKey: preKey ?? this.preKey,
        createdAt: createdAt ?? this.createdAt,
      );
  SignalPreKeyStoresData copyWithCompanion(SignalPreKeyStoresCompanion data) {
    return SignalPreKeyStoresData(
      preKeyId: data.preKeyId.present ? data.preKeyId.value : this.preKeyId,
      preKey: data.preKey.present ? data.preKey.value : this.preKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalPreKeyStoresData(')
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
      (other is SignalPreKeyStoresData &&
          other.preKeyId == this.preKeyId &&
          $driftBlobEquality.equals(other.preKey, this.preKey) &&
          other.createdAt == this.createdAt);
}

class SignalPreKeyStoresCompanion
    extends UpdateCompanion<SignalPreKeyStoresData> {
  final Value<int> preKeyId;
  final Value<i2.Uint8List> preKey;
  final Value<DateTime> createdAt;
  const SignalPreKeyStoresCompanion({
    this.preKeyId = const Value.absent(),
    this.preKey = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SignalPreKeyStoresCompanion.insert({
    this.preKeyId = const Value.absent(),
    required i2.Uint8List preKey,
    this.createdAt = const Value.absent(),
  }) : preKey = Value(preKey);
  static Insertable<SignalPreKeyStoresData> custom({
    Expression<int>? preKeyId,
    Expression<i2.Uint8List>? preKey,
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
      Value<i2.Uint8List>? preKey,
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
      map['pre_key'] = Variable<i2.Uint8List>(preKey.value);
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

class SignalSenderKeyStores extends Table
    with TableInfo<SignalSenderKeyStores, SignalSenderKeyStoresData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SignalSenderKeyStores(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> senderKeyName = GeneratedColumn<String>(
      'sender_key_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<i2.Uint8List> senderKey =
      GeneratedColumn<i2.Uint8List>('sender_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [senderKeyName, senderKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_sender_key_stores';
  @override
  Set<GeneratedColumn> get $primaryKey => {senderKeyName};
  @override
  SignalSenderKeyStoresData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSenderKeyStoresData(
      senderKeyName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sender_key_name'])!,
      senderKey: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}sender_key'])!,
    );
  }

  @override
  SignalSenderKeyStores createAlias(String alias) {
    return SignalSenderKeyStores(attachedDatabase, alias);
  }
}

class SignalSenderKeyStoresData extends DataClass
    implements Insertable<SignalSenderKeyStoresData> {
  final String senderKeyName;
  final i2.Uint8List senderKey;
  const SignalSenderKeyStoresData(
      {required this.senderKeyName, required this.senderKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sender_key_name'] = Variable<String>(senderKeyName);
    map['sender_key'] = Variable<i2.Uint8List>(senderKey);
    return map;
  }

  SignalSenderKeyStoresCompanion toCompanion(bool nullToAbsent) {
    return SignalSenderKeyStoresCompanion(
      senderKeyName: Value(senderKeyName),
      senderKey: Value(senderKey),
    );
  }

  factory SignalSenderKeyStoresData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSenderKeyStoresData(
      senderKeyName: serializer.fromJson<String>(json['senderKeyName']),
      senderKey: serializer.fromJson<i2.Uint8List>(json['senderKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'senderKeyName': serializer.toJson<String>(senderKeyName),
      'senderKey': serializer.toJson<i2.Uint8List>(senderKey),
    };
  }

  SignalSenderKeyStoresData copyWith(
          {String? senderKeyName, i2.Uint8List? senderKey}) =>
      SignalSenderKeyStoresData(
        senderKeyName: senderKeyName ?? this.senderKeyName,
        senderKey: senderKey ?? this.senderKey,
      );
  SignalSenderKeyStoresData copyWithCompanion(
      SignalSenderKeyStoresCompanion data) {
    return SignalSenderKeyStoresData(
      senderKeyName: data.senderKeyName.present
          ? data.senderKeyName.value
          : this.senderKeyName,
      senderKey: data.senderKey.present ? data.senderKey.value : this.senderKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalSenderKeyStoresData(')
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
      (other is SignalSenderKeyStoresData &&
          other.senderKeyName == this.senderKeyName &&
          $driftBlobEquality.equals(other.senderKey, this.senderKey));
}

class SignalSenderKeyStoresCompanion
    extends UpdateCompanion<SignalSenderKeyStoresData> {
  final Value<String> senderKeyName;
  final Value<i2.Uint8List> senderKey;
  final Value<int> rowid;
  const SignalSenderKeyStoresCompanion({
    this.senderKeyName = const Value.absent(),
    this.senderKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignalSenderKeyStoresCompanion.insert({
    required String senderKeyName,
    required i2.Uint8List senderKey,
    this.rowid = const Value.absent(),
  })  : senderKeyName = Value(senderKeyName),
        senderKey = Value(senderKey);
  static Insertable<SignalSenderKeyStoresData> custom({
    Expression<String>? senderKeyName,
    Expression<i2.Uint8List>? senderKey,
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
      Value<i2.Uint8List>? senderKey,
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
      map['sender_key'] = Variable<i2.Uint8List>(senderKey.value);
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

class SignalSessionStores extends Table
    with TableInfo<SignalSessionStores, SignalSessionStoresData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SignalSessionStores(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> deviceId = GeneratedColumn<int>(
      'device_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<i2.Uint8List> sessionRecord =
      GeneratedColumn<i2.Uint8List>('session_record', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns =>
      [deviceId, name, sessionRecord, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_session_stores';
  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId, name};
  @override
  SignalSessionStoresData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalSessionStoresData(
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
  SignalSessionStores createAlias(String alias) {
    return SignalSessionStores(attachedDatabase, alias);
  }
}

class SignalSessionStoresData extends DataClass
    implements Insertable<SignalSessionStoresData> {
  final int deviceId;
  final String name;
  final i2.Uint8List sessionRecord;
  final DateTime createdAt;
  const SignalSessionStoresData(
      {required this.deviceId,
      required this.name,
      required this.sessionRecord,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<int>(deviceId);
    map['name'] = Variable<String>(name);
    map['session_record'] = Variable<i2.Uint8List>(sessionRecord);
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

  factory SignalSessionStoresData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalSessionStoresData(
      deviceId: serializer.fromJson<int>(json['deviceId']),
      name: serializer.fromJson<String>(json['name']),
      sessionRecord: serializer.fromJson<i2.Uint8List>(json['sessionRecord']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<int>(deviceId),
      'name': serializer.toJson<String>(name),
      'sessionRecord': serializer.toJson<i2.Uint8List>(sessionRecord),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalSessionStoresData copyWith(
          {int? deviceId,
          String? name,
          i2.Uint8List? sessionRecord,
          DateTime? createdAt}) =>
      SignalSessionStoresData(
        deviceId: deviceId ?? this.deviceId,
        name: name ?? this.name,
        sessionRecord: sessionRecord ?? this.sessionRecord,
        createdAt: createdAt ?? this.createdAt,
      );
  SignalSessionStoresData copyWithCompanion(SignalSessionStoresCompanion data) {
    return SignalSessionStoresData(
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
    return (StringBuffer('SignalSessionStoresData(')
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
      (other is SignalSessionStoresData &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          $driftBlobEquality.equals(other.sessionRecord, this.sessionRecord) &&
          other.createdAt == this.createdAt);
}

class SignalSessionStoresCompanion
    extends UpdateCompanion<SignalSessionStoresData> {
  final Value<int> deviceId;
  final Value<String> name;
  final Value<i2.Uint8List> sessionRecord;
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
    required i2.Uint8List sessionRecord,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        name = Value(name),
        sessionRecord = Value(sessionRecord);
  static Insertable<SignalSessionStoresData> custom({
    Expression<int>? deviceId,
    Expression<String>? name,
    Expression<i2.Uint8List>? sessionRecord,
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
      Value<i2.Uint8List>? sessionRecord,
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
      map['session_record'] = Variable<i2.Uint8List>(sessionRecord.value);
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

class SignalContactPreKeys extends Table
    with TableInfo<SignalContactPreKeys, SignalContactPreKeysData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SignalContactPreKeys(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  late final GeneratedColumn<int> preKeyId = GeneratedColumn<int>(
      'pre_key_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<i2.Uint8List> preKey =
      GeneratedColumn<i2.Uint8List>('pre_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns =>
      [contactId, preKeyId, preKey, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signal_contact_pre_keys';
  @override
  Set<GeneratedColumn> get $primaryKey => {contactId, preKeyId};
  @override
  SignalContactPreKeysData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalContactPreKeysData(
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
  SignalContactPreKeys createAlias(String alias) {
    return SignalContactPreKeys(attachedDatabase, alias);
  }
}

class SignalContactPreKeysData extends DataClass
    implements Insertable<SignalContactPreKeysData> {
  final int contactId;
  final int preKeyId;
  final i2.Uint8List preKey;
  final DateTime createdAt;
  const SignalContactPreKeysData(
      {required this.contactId,
      required this.preKeyId,
      required this.preKey,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_id'] = Variable<int>(contactId);
    map['pre_key_id'] = Variable<int>(preKeyId);
    map['pre_key'] = Variable<i2.Uint8List>(preKey);
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

  factory SignalContactPreKeysData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalContactPreKeysData(
      contactId: serializer.fromJson<int>(json['contactId']),
      preKeyId: serializer.fromJson<int>(json['preKeyId']),
      preKey: serializer.fromJson<i2.Uint8List>(json['preKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<int>(contactId),
      'preKeyId': serializer.toJson<int>(preKeyId),
      'preKey': serializer.toJson<i2.Uint8List>(preKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalContactPreKeysData copyWith(
          {int? contactId,
          int? preKeyId,
          i2.Uint8List? preKey,
          DateTime? createdAt}) =>
      SignalContactPreKeysData(
        contactId: contactId ?? this.contactId,
        preKeyId: preKeyId ?? this.preKeyId,
        preKey: preKey ?? this.preKey,
        createdAt: createdAt ?? this.createdAt,
      );
  SignalContactPreKeysData copyWithCompanion(
      SignalContactPreKeysCompanion data) {
    return SignalContactPreKeysData(
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      preKeyId: data.preKeyId.present ? data.preKeyId.value : this.preKeyId,
      preKey: data.preKey.present ? data.preKey.value : this.preKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignalContactPreKeysData(')
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
      (other is SignalContactPreKeysData &&
          other.contactId == this.contactId &&
          other.preKeyId == this.preKeyId &&
          $driftBlobEquality.equals(other.preKey, this.preKey) &&
          other.createdAt == this.createdAt);
}

class SignalContactPreKeysCompanion
    extends UpdateCompanion<SignalContactPreKeysData> {
  final Value<int> contactId;
  final Value<int> preKeyId;
  final Value<i2.Uint8List> preKey;
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
    required i2.Uint8List preKey,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : contactId = Value(contactId),
        preKeyId = Value(preKeyId),
        preKey = Value(preKey);
  static Insertable<SignalContactPreKeysData> custom({
    Expression<int>? contactId,
    Expression<int>? preKeyId,
    Expression<i2.Uint8List>? preKey,
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
      Value<i2.Uint8List>? preKey,
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
      map['pre_key'] = Variable<i2.Uint8List>(preKey.value);
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

class SignalContactSignedPreKeys extends Table
    with TableInfo<SignalContactSignedPreKeys, SignalContactSignedPreKeysData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SignalContactSignedPreKeys(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contacts (user_id) ON DELETE CASCADE'));
  late final GeneratedColumn<int> signedPreKeyId = GeneratedColumn<int>(
      'signed_pre_key_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<i2.Uint8List> signedPreKey =
      GeneratedColumn<i2.Uint8List>('signed_pre_key', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  late final GeneratedColumn<i2.Uint8List> signedPreKeySignature =
      GeneratedColumn<i2.Uint8List>(
          'signed_pre_key_signature', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
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
  Set<GeneratedColumn> get $primaryKey => {contactId};
  @override
  SignalContactSignedPreKeysData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignalContactSignedPreKeysData(
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
  SignalContactSignedPreKeys createAlias(String alias) {
    return SignalContactSignedPreKeys(attachedDatabase, alias);
  }
}

class SignalContactSignedPreKeysData extends DataClass
    implements Insertable<SignalContactSignedPreKeysData> {
  final int contactId;
  final int signedPreKeyId;
  final i2.Uint8List signedPreKey;
  final i2.Uint8List signedPreKeySignature;
  final DateTime createdAt;
  const SignalContactSignedPreKeysData(
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
    map['signed_pre_key'] = Variable<i2.Uint8List>(signedPreKey);
    map['signed_pre_key_signature'] =
        Variable<i2.Uint8List>(signedPreKeySignature);
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

  factory SignalContactSignedPreKeysData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignalContactSignedPreKeysData(
      contactId: serializer.fromJson<int>(json['contactId']),
      signedPreKeyId: serializer.fromJson<int>(json['signedPreKeyId']),
      signedPreKey: serializer.fromJson<i2.Uint8List>(json['signedPreKey']),
      signedPreKeySignature:
          serializer.fromJson<i2.Uint8List>(json['signedPreKeySignature']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<int>(contactId),
      'signedPreKeyId': serializer.toJson<int>(signedPreKeyId),
      'signedPreKey': serializer.toJson<i2.Uint8List>(signedPreKey),
      'signedPreKeySignature':
          serializer.toJson<i2.Uint8List>(signedPreKeySignature),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SignalContactSignedPreKeysData copyWith(
          {int? contactId,
          int? signedPreKeyId,
          i2.Uint8List? signedPreKey,
          i2.Uint8List? signedPreKeySignature,
          DateTime? createdAt}) =>
      SignalContactSignedPreKeysData(
        contactId: contactId ?? this.contactId,
        signedPreKeyId: signedPreKeyId ?? this.signedPreKeyId,
        signedPreKey: signedPreKey ?? this.signedPreKey,
        signedPreKeySignature:
            signedPreKeySignature ?? this.signedPreKeySignature,
        createdAt: createdAt ?? this.createdAt,
      );
  SignalContactSignedPreKeysData copyWithCompanion(
      SignalContactSignedPreKeysCompanion data) {
    return SignalContactSignedPreKeysData(
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
    return (StringBuffer('SignalContactSignedPreKeysData(')
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
      (other is SignalContactSignedPreKeysData &&
          other.contactId == this.contactId &&
          other.signedPreKeyId == this.signedPreKeyId &&
          $driftBlobEquality.equals(other.signedPreKey, this.signedPreKey) &&
          $driftBlobEquality.equals(
              other.signedPreKeySignature, this.signedPreKeySignature) &&
          other.createdAt == this.createdAt);
}

class SignalContactSignedPreKeysCompanion
    extends UpdateCompanion<SignalContactSignedPreKeysData> {
  final Value<int> contactId;
  final Value<int> signedPreKeyId;
  final Value<i2.Uint8List> signedPreKey;
  final Value<i2.Uint8List> signedPreKeySignature;
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
    required i2.Uint8List signedPreKey,
    required i2.Uint8List signedPreKeySignature,
    this.createdAt = const Value.absent(),
  })  : signedPreKeyId = Value(signedPreKeyId),
        signedPreKey = Value(signedPreKey),
        signedPreKeySignature = Value(signedPreKeySignature);
  static Insertable<SignalContactSignedPreKeysData> custom({
    Expression<int>? contactId,
    Expression<int>? signedPreKeyId,
    Expression<i2.Uint8List>? signedPreKey,
    Expression<i2.Uint8List>? signedPreKeySignature,
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
      Value<i2.Uint8List>? signedPreKey,
      Value<i2.Uint8List>? signedPreKeySignature,
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
      map['signed_pre_key'] = Variable<i2.Uint8List>(signedPreKey.value);
    }
    if (signedPreKeySignature.present) {
      map['signed_pre_key_signature'] =
          Variable<i2.Uint8List>(signedPreKeySignature.value);
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

class MessageActions extends Table
    with TableInfo<MessageActions, MessageActionsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MessageActions(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES messages (message_id) ON DELETE CASCADE'));
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> actionAt = GeneratedColumn<DateTime>(
      'action_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns => [messageId, contactId, type, actionAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_actions';
  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, contactId, type};
  @override
  MessageActionsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageActionsData(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      actionAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}action_at'])!,
    );
  }

  @override
  MessageActions createAlias(String alias) {
    return MessageActions(attachedDatabase, alias);
  }
}

class MessageActionsData extends DataClass
    implements Insertable<MessageActionsData> {
  final String messageId;
  final int contactId;
  final String type;
  final DateTime actionAt;
  const MessageActionsData(
      {required this.messageId,
      required this.contactId,
      required this.type,
      required this.actionAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['contact_id'] = Variable<int>(contactId);
    map['type'] = Variable<String>(type);
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

  factory MessageActionsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageActionsData(
      messageId: serializer.fromJson<String>(json['messageId']),
      contactId: serializer.fromJson<int>(json['contactId']),
      type: serializer.fromJson<String>(json['type']),
      actionAt: serializer.fromJson<DateTime>(json['actionAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'contactId': serializer.toJson<int>(contactId),
      'type': serializer.toJson<String>(type),
      'actionAt': serializer.toJson<DateTime>(actionAt),
    };
  }

  MessageActionsData copyWith(
          {String? messageId,
          int? contactId,
          String? type,
          DateTime? actionAt}) =>
      MessageActionsData(
        messageId: messageId ?? this.messageId,
        contactId: contactId ?? this.contactId,
        type: type ?? this.type,
        actionAt: actionAt ?? this.actionAt,
      );
  MessageActionsData copyWithCompanion(MessageActionsCompanion data) {
    return MessageActionsData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      type: data.type.present ? data.type.value : this.type,
      actionAt: data.actionAt.present ? data.actionAt.value : this.actionAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageActionsData(')
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
      (other is MessageActionsData &&
          other.messageId == this.messageId &&
          other.contactId == this.contactId &&
          other.type == this.type &&
          other.actionAt == this.actionAt);
}

class MessageActionsCompanion extends UpdateCompanion<MessageActionsData> {
  final Value<String> messageId;
  final Value<int> contactId;
  final Value<String> type;
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
    required String type,
    this.actionAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        contactId = Value(contactId),
        type = Value(type);
  static Insertable<MessageActionsData> custom({
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
      Value<String>? type,
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
      map['type'] = Variable<String>(type.value);
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

class GroupHistories extends Table
    with TableInfo<GroupHistories, GroupHistoriesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GroupHistories(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> groupHistoryId = GeneratedColumn<String>(
      'group_history_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES "groups" (group_id) ON DELETE CASCADE'));
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (user_id)'));
  late final GeneratedColumn<int> affectedContactId = GeneratedColumn<int>(
      'affected_contact_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<String> oldGroupName = GeneratedColumn<String>(
      'old_group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> newGroupName = GeneratedColumn<String>(
      'new_group_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<int> newDeleteMessagesAfterMilliseconds =
      GeneratedColumn<int>(
          'new_delete_messages_after_milliseconds', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<DateTime> actionAt = GeneratedColumn<DateTime>(
      'action_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
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
  Set<GeneratedColumn> get $primaryKey => {groupHistoryId};
  @override
  GroupHistoriesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupHistoriesData(
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
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      actionAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}action_at'])!,
    );
  }

  @override
  GroupHistories createAlias(String alias) {
    return GroupHistories(attachedDatabase, alias);
  }
}

class GroupHistoriesData extends DataClass
    implements Insertable<GroupHistoriesData> {
  final String groupHistoryId;
  final String groupId;
  final int? contactId;
  final int? affectedContactId;
  final String? oldGroupName;
  final String? newGroupName;
  final int? newDeleteMessagesAfterMilliseconds;
  final String type;
  final DateTime actionAt;
  const GroupHistoriesData(
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
    map['type'] = Variable<String>(type);
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

  factory GroupHistoriesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupHistoriesData(
      groupHistoryId: serializer.fromJson<String>(json['groupHistoryId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      contactId: serializer.fromJson<int?>(json['contactId']),
      affectedContactId: serializer.fromJson<int?>(json['affectedContactId']),
      oldGroupName: serializer.fromJson<String?>(json['oldGroupName']),
      newGroupName: serializer.fromJson<String?>(json['newGroupName']),
      newDeleteMessagesAfterMilliseconds:
          serializer.fromJson<int?>(json['newDeleteMessagesAfterMilliseconds']),
      type: serializer.fromJson<String>(json['type']),
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
      'type': serializer.toJson<String>(type),
      'actionAt': serializer.toJson<DateTime>(actionAt),
    };
  }

  GroupHistoriesData copyWith(
          {String? groupHistoryId,
          String? groupId,
          Value<int?> contactId = const Value.absent(),
          Value<int?> affectedContactId = const Value.absent(),
          Value<String?> oldGroupName = const Value.absent(),
          Value<String?> newGroupName = const Value.absent(),
          Value<int?> newDeleteMessagesAfterMilliseconds = const Value.absent(),
          String? type,
          DateTime? actionAt}) =>
      GroupHistoriesData(
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
  GroupHistoriesData copyWithCompanion(GroupHistoriesCompanion data) {
    return GroupHistoriesData(
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
    return (StringBuffer('GroupHistoriesData(')
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
      (other is GroupHistoriesData &&
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

class GroupHistoriesCompanion extends UpdateCompanion<GroupHistoriesData> {
  final Value<String> groupHistoryId;
  final Value<String> groupId;
  final Value<int?> contactId;
  final Value<int?> affectedContactId;
  final Value<String?> oldGroupName;
  final Value<String?> newGroupName;
  final Value<int?> newDeleteMessagesAfterMilliseconds;
  final Value<String> type;
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
    required String type,
    this.actionAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : groupHistoryId = Value(groupHistoryId),
        groupId = Value(groupId),
        type = Value(type);
  static Insertable<GroupHistoriesData> custom({
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
      Value<String>? type,
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
      map['type'] = Variable<String>(type.value);
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

class DatabaseAtV5 extends GeneratedDatabase {
  DatabaseAtV5(QueryExecutor e) : super(e);
  late final Contacts contacts = Contacts(this);
  late final Groups groups = Groups(this);
  late final MediaFiles mediaFiles = MediaFiles(this);
  late final Messages messages = Messages(this);
  late final MessageHistories messageHistories = MessageHistories(this);
  late final Reactions reactions = Reactions(this);
  late final GroupMembers groupMembers = GroupMembers(this);
  late final Receipts receipts = Receipts(this);
  late final ReceivedReceipts receivedReceipts = ReceivedReceipts(this);
  late final SignalIdentityKeyStores signalIdentityKeyStores =
      SignalIdentityKeyStores(this);
  late final SignalPreKeyStores signalPreKeyStores = SignalPreKeyStores(this);
  late final SignalSenderKeyStores signalSenderKeyStores =
      SignalSenderKeyStores(this);
  late final SignalSessionStores signalSessionStores =
      SignalSessionStores(this);
  late final SignalContactPreKeys signalContactPreKeys =
      SignalContactPreKeys(this);
  late final SignalContactSignedPreKeys signalContactSignedPreKeys =
      SignalContactSignedPreKeys(this);
  late final MessageActions messageActions = MessageActions(this);
  late final GroupHistories groupHistories = GroupHistories(this);
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
  int get schemaVersion => 5;
}
