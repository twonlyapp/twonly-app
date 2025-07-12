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
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> nickName = GeneratedColumn<String>(
      'nick_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> avatarSvg = GeneratedColumn<String>(
      'avatar_svg', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<int> myAvatarCounter = GeneratedColumn<int>(
      'my_avatar_counter', aliasedName, false,
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
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> deleteMessagesAfterXMinutes =
      GeneratedColumn<int>(
          'delete_messages_after_x_minutes', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const CustomExpression('1440'));
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  late final GeneratedColumn<int> totalMediaCounter = GeneratedColumn<int>(
      'total_media_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<DateTime> lastMessageSend =
      GeneratedColumn<DateTime>('last_message_send', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastMessageReceived =
      GeneratedColumn<DateTime>('last_message_received', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastFlameCounterChange =
      GeneratedColumn<DateTime>('last_flame_counter_change', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> lastMessageExchange =
      GeneratedColumn<DateTime>('last_message_exchange', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: const CustomExpression(
              'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  late final GeneratedColumn<int> flameCounter = GeneratedColumn<int>(
      'flame_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('0'));
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        username,
        displayName,
        nickName,
        avatarSvg,
        myAvatarCounter,
        accepted,
        requested,
        blocked,
        verified,
        archived,
        deleteMessagesAfterXMinutes,
        createdAt,
        totalMediaCounter,
        lastMessageSend,
        lastMessageReceived,
        lastFlameCounterChange,
        lastMessageExchange,
        flameCounter
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
      avatarSvg: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_svg']),
      myAvatarCounter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}my_avatar_counter'])!,
      accepted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}accepted'])!,
      requested: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}requested'])!,
      blocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}blocked'])!,
      verified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}verified'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      deleteMessagesAfterXMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}delete_messages_after_x_minutes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      totalMediaCounter: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_media_counter'])!,
      lastMessageSend: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_message_send']),
      lastMessageReceived: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_message_received']),
      lastFlameCounterChange: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_flame_counter_change']),
      lastMessageExchange: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_message_exchange'])!,
      flameCounter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}flame_counter'])!,
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
  final String? avatarSvg;
  final int myAvatarCounter;
  final bool accepted;
  final bool requested;
  final bool blocked;
  final bool verified;
  final bool archived;
  final int deleteMessagesAfterXMinutes;
  final DateTime createdAt;
  final int totalMediaCounter;
  final DateTime? lastMessageSend;
  final DateTime? lastMessageReceived;
  final DateTime? lastFlameCounterChange;
  final DateTime lastMessageExchange;
  final int flameCounter;
  const ContactsData(
      {required this.userId,
      required this.username,
      this.displayName,
      this.nickName,
      this.avatarSvg,
      required this.myAvatarCounter,
      required this.accepted,
      required this.requested,
      required this.blocked,
      required this.verified,
      required this.archived,
      required this.deleteMessagesAfterXMinutes,
      required this.createdAt,
      required this.totalMediaCounter,
      this.lastMessageSend,
      this.lastMessageReceived,
      this.lastFlameCounterChange,
      required this.lastMessageExchange,
      required this.flameCounter});
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
    if (!nullToAbsent || avatarSvg != null) {
      map['avatar_svg'] = Variable<String>(avatarSvg);
    }
    map['my_avatar_counter'] = Variable<int>(myAvatarCounter);
    map['accepted'] = Variable<bool>(accepted);
    map['requested'] = Variable<bool>(requested);
    map['blocked'] = Variable<bool>(blocked);
    map['verified'] = Variable<bool>(verified);
    map['archived'] = Variable<bool>(archived);
    map['delete_messages_after_x_minutes'] =
        Variable<int>(deleteMessagesAfterXMinutes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['total_media_counter'] = Variable<int>(totalMediaCounter);
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
    map['last_message_exchange'] = Variable<DateTime>(lastMessageExchange);
    map['flame_counter'] = Variable<int>(flameCounter);
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
      avatarSvg: avatarSvg == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarSvg),
      myAvatarCounter: Value(myAvatarCounter),
      accepted: Value(accepted),
      requested: Value(requested),
      blocked: Value(blocked),
      verified: Value(verified),
      archived: Value(archived),
      deleteMessagesAfterXMinutes: Value(deleteMessagesAfterXMinutes),
      createdAt: Value(createdAt),
      totalMediaCounter: Value(totalMediaCounter),
      lastMessageSend: lastMessageSend == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSend),
      lastMessageReceived: lastMessageReceived == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageReceived),
      lastFlameCounterChange: lastFlameCounterChange == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFlameCounterChange),
      lastMessageExchange: Value(lastMessageExchange),
      flameCounter: Value(flameCounter),
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
      avatarSvg: serializer.fromJson<String?>(json['avatarSvg']),
      myAvatarCounter: serializer.fromJson<int>(json['myAvatarCounter']),
      accepted: serializer.fromJson<bool>(json['accepted']),
      requested: serializer.fromJson<bool>(json['requested']),
      blocked: serializer.fromJson<bool>(json['blocked']),
      verified: serializer.fromJson<bool>(json['verified']),
      archived: serializer.fromJson<bool>(json['archived']),
      deleteMessagesAfterXMinutes:
          serializer.fromJson<int>(json['deleteMessagesAfterXMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      totalMediaCounter: serializer.fromJson<int>(json['totalMediaCounter']),
      lastMessageSend: serializer.fromJson<DateTime?>(json['lastMessageSend']),
      lastMessageReceived:
          serializer.fromJson<DateTime?>(json['lastMessageReceived']),
      lastFlameCounterChange:
          serializer.fromJson<DateTime?>(json['lastFlameCounterChange']),
      lastMessageExchange:
          serializer.fromJson<DateTime>(json['lastMessageExchange']),
      flameCounter: serializer.fromJson<int>(json['flameCounter']),
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
      'avatarSvg': serializer.toJson<String?>(avatarSvg),
      'myAvatarCounter': serializer.toJson<int>(myAvatarCounter),
      'accepted': serializer.toJson<bool>(accepted),
      'requested': serializer.toJson<bool>(requested),
      'blocked': serializer.toJson<bool>(blocked),
      'verified': serializer.toJson<bool>(verified),
      'archived': serializer.toJson<bool>(archived),
      'deleteMessagesAfterXMinutes':
          serializer.toJson<int>(deleteMessagesAfterXMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'totalMediaCounter': serializer.toJson<int>(totalMediaCounter),
      'lastMessageSend': serializer.toJson<DateTime?>(lastMessageSend),
      'lastMessageReceived': serializer.toJson<DateTime?>(lastMessageReceived),
      'lastFlameCounterChange':
          serializer.toJson<DateTime?>(lastFlameCounterChange),
      'lastMessageExchange': serializer.toJson<DateTime>(lastMessageExchange),
      'flameCounter': serializer.toJson<int>(flameCounter),
    };
  }

  ContactsData copyWith(
          {int? userId,
          String? username,
          Value<String?> displayName = const Value.absent(),
          Value<String?> nickName = const Value.absent(),
          Value<String?> avatarSvg = const Value.absent(),
          int? myAvatarCounter,
          bool? accepted,
          bool? requested,
          bool? blocked,
          bool? verified,
          bool? archived,
          int? deleteMessagesAfterXMinutes,
          DateTime? createdAt,
          int? totalMediaCounter,
          Value<DateTime?> lastMessageSend = const Value.absent(),
          Value<DateTime?> lastMessageReceived = const Value.absent(),
          Value<DateTime?> lastFlameCounterChange = const Value.absent(),
          DateTime? lastMessageExchange,
          int? flameCounter}) =>
      ContactsData(
        userId: userId ?? this.userId,
        username: username ?? this.username,
        displayName: displayName.present ? displayName.value : this.displayName,
        nickName: nickName.present ? nickName.value : this.nickName,
        avatarSvg: avatarSvg.present ? avatarSvg.value : this.avatarSvg,
        myAvatarCounter: myAvatarCounter ?? this.myAvatarCounter,
        accepted: accepted ?? this.accepted,
        requested: requested ?? this.requested,
        blocked: blocked ?? this.blocked,
        verified: verified ?? this.verified,
        archived: archived ?? this.archived,
        deleteMessagesAfterXMinutes:
            deleteMessagesAfterXMinutes ?? this.deleteMessagesAfterXMinutes,
        createdAt: createdAt ?? this.createdAt,
        totalMediaCounter: totalMediaCounter ?? this.totalMediaCounter,
        lastMessageSend: lastMessageSend.present
            ? lastMessageSend.value
            : this.lastMessageSend,
        lastMessageReceived: lastMessageReceived.present
            ? lastMessageReceived.value
            : this.lastMessageReceived,
        lastFlameCounterChange: lastFlameCounterChange.present
            ? lastFlameCounterChange.value
            : this.lastFlameCounterChange,
        lastMessageExchange: lastMessageExchange ?? this.lastMessageExchange,
        flameCounter: flameCounter ?? this.flameCounter,
      );
  ContactsData copyWithCompanion(ContactsCompanion data) {
    return ContactsData(
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      nickName: data.nickName.present ? data.nickName.value : this.nickName,
      avatarSvg: data.avatarSvg.present ? data.avatarSvg.value : this.avatarSvg,
      myAvatarCounter: data.myAvatarCounter.present
          ? data.myAvatarCounter.value
          : this.myAvatarCounter,
      accepted: data.accepted.present ? data.accepted.value : this.accepted,
      requested: data.requested.present ? data.requested.value : this.requested,
      blocked: data.blocked.present ? data.blocked.value : this.blocked,
      verified: data.verified.present ? data.verified.value : this.verified,
      archived: data.archived.present ? data.archived.value : this.archived,
      deleteMessagesAfterXMinutes: data.deleteMessagesAfterXMinutes.present
          ? data.deleteMessagesAfterXMinutes.value
          : this.deleteMessagesAfterXMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      totalMediaCounter: data.totalMediaCounter.present
          ? data.totalMediaCounter.value
          : this.totalMediaCounter,
      lastMessageSend: data.lastMessageSend.present
          ? data.lastMessageSend.value
          : this.lastMessageSend,
      lastMessageReceived: data.lastMessageReceived.present
          ? data.lastMessageReceived.value
          : this.lastMessageReceived,
      lastFlameCounterChange: data.lastFlameCounterChange.present
          ? data.lastFlameCounterChange.value
          : this.lastFlameCounterChange,
      lastMessageExchange: data.lastMessageExchange.present
          ? data.lastMessageExchange.value
          : this.lastMessageExchange,
      flameCounter: data.flameCounter.present
          ? data.flameCounter.value
          : this.flameCounter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactsData(')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('nickName: $nickName, ')
          ..write('avatarSvg: $avatarSvg, ')
          ..write('myAvatarCounter: $myAvatarCounter, ')
          ..write('accepted: $accepted, ')
          ..write('requested: $requested, ')
          ..write('blocked: $blocked, ')
          ..write('verified: $verified, ')
          ..write('archived: $archived, ')
          ..write('deleteMessagesAfterXMinutes: $deleteMessagesAfterXMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalMediaCounter: $totalMediaCounter, ')
          ..write('lastMessageSend: $lastMessageSend, ')
          ..write('lastMessageReceived: $lastMessageReceived, ')
          ..write('lastFlameCounterChange: $lastFlameCounterChange, ')
          ..write('lastMessageExchange: $lastMessageExchange, ')
          ..write('flameCounter: $flameCounter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId,
      username,
      displayName,
      nickName,
      avatarSvg,
      myAvatarCounter,
      accepted,
      requested,
      blocked,
      verified,
      archived,
      deleteMessagesAfterXMinutes,
      createdAt,
      totalMediaCounter,
      lastMessageSend,
      lastMessageReceived,
      lastFlameCounterChange,
      lastMessageExchange,
      flameCounter);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactsData &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.nickName == this.nickName &&
          other.avatarSvg == this.avatarSvg &&
          other.myAvatarCounter == this.myAvatarCounter &&
          other.accepted == this.accepted &&
          other.requested == this.requested &&
          other.blocked == this.blocked &&
          other.verified == this.verified &&
          other.archived == this.archived &&
          other.deleteMessagesAfterXMinutes ==
              this.deleteMessagesAfterXMinutes &&
          other.createdAt == this.createdAt &&
          other.totalMediaCounter == this.totalMediaCounter &&
          other.lastMessageSend == this.lastMessageSend &&
          other.lastMessageReceived == this.lastMessageReceived &&
          other.lastFlameCounterChange == this.lastFlameCounterChange &&
          other.lastMessageExchange == this.lastMessageExchange &&
          other.flameCounter == this.flameCounter);
}

class ContactsCompanion extends UpdateCompanion<ContactsData> {
  final Value<int> userId;
  final Value<String> username;
  final Value<String?> displayName;
  final Value<String?> nickName;
  final Value<String?> avatarSvg;
  final Value<int> myAvatarCounter;
  final Value<bool> accepted;
  final Value<bool> requested;
  final Value<bool> blocked;
  final Value<bool> verified;
  final Value<bool> archived;
  final Value<int> deleteMessagesAfterXMinutes;
  final Value<DateTime> createdAt;
  final Value<int> totalMediaCounter;
  final Value<DateTime?> lastMessageSend;
  final Value<DateTime?> lastMessageReceived;
  final Value<DateTime?> lastFlameCounterChange;
  final Value<DateTime> lastMessageExchange;
  final Value<int> flameCounter;
  const ContactsCompanion({
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.nickName = const Value.absent(),
    this.avatarSvg = const Value.absent(),
    this.myAvatarCounter = const Value.absent(),
    this.accepted = const Value.absent(),
    this.requested = const Value.absent(),
    this.blocked = const Value.absent(),
    this.verified = const Value.absent(),
    this.archived = const Value.absent(),
    this.deleteMessagesAfterXMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.totalMediaCounter = const Value.absent(),
    this.lastMessageSend = const Value.absent(),
    this.lastMessageReceived = const Value.absent(),
    this.lastFlameCounterChange = const Value.absent(),
    this.lastMessageExchange = const Value.absent(),
    this.flameCounter = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.userId = const Value.absent(),
    required String username,
    this.displayName = const Value.absent(),
    this.nickName = const Value.absent(),
    this.avatarSvg = const Value.absent(),
    this.myAvatarCounter = const Value.absent(),
    this.accepted = const Value.absent(),
    this.requested = const Value.absent(),
    this.blocked = const Value.absent(),
    this.verified = const Value.absent(),
    this.archived = const Value.absent(),
    this.deleteMessagesAfterXMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.totalMediaCounter = const Value.absent(),
    this.lastMessageSend = const Value.absent(),
    this.lastMessageReceived = const Value.absent(),
    this.lastFlameCounterChange = const Value.absent(),
    this.lastMessageExchange = const Value.absent(),
    this.flameCounter = const Value.absent(),
  }) : username = Value(username);
  static Insertable<ContactsData> custom({
    Expression<int>? userId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? nickName,
    Expression<String>? avatarSvg,
    Expression<int>? myAvatarCounter,
    Expression<bool>? accepted,
    Expression<bool>? requested,
    Expression<bool>? blocked,
    Expression<bool>? verified,
    Expression<bool>? archived,
    Expression<int>? deleteMessagesAfterXMinutes,
    Expression<DateTime>? createdAt,
    Expression<int>? totalMediaCounter,
    Expression<DateTime>? lastMessageSend,
    Expression<DateTime>? lastMessageReceived,
    Expression<DateTime>? lastFlameCounterChange,
    Expression<DateTime>? lastMessageExchange,
    Expression<int>? flameCounter,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (nickName != null) 'nick_name': nickName,
      if (avatarSvg != null) 'avatar_svg': avatarSvg,
      if (myAvatarCounter != null) 'my_avatar_counter': myAvatarCounter,
      if (accepted != null) 'accepted': accepted,
      if (requested != null) 'requested': requested,
      if (blocked != null) 'blocked': blocked,
      if (verified != null) 'verified': verified,
      if (archived != null) 'archived': archived,
      if (deleteMessagesAfterXMinutes != null)
        'delete_messages_after_x_minutes': deleteMessagesAfterXMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (totalMediaCounter != null) 'total_media_counter': totalMediaCounter,
      if (lastMessageSend != null) 'last_message_send': lastMessageSend,
      if (lastMessageReceived != null)
        'last_message_received': lastMessageReceived,
      if (lastFlameCounterChange != null)
        'last_flame_counter_change': lastFlameCounterChange,
      if (lastMessageExchange != null)
        'last_message_exchange': lastMessageExchange,
      if (flameCounter != null) 'flame_counter': flameCounter,
    });
  }

  ContactsCompanion copyWith(
      {Value<int>? userId,
      Value<String>? username,
      Value<String?>? displayName,
      Value<String?>? nickName,
      Value<String?>? avatarSvg,
      Value<int>? myAvatarCounter,
      Value<bool>? accepted,
      Value<bool>? requested,
      Value<bool>? blocked,
      Value<bool>? verified,
      Value<bool>? archived,
      Value<int>? deleteMessagesAfterXMinutes,
      Value<DateTime>? createdAt,
      Value<int>? totalMediaCounter,
      Value<DateTime?>? lastMessageSend,
      Value<DateTime?>? lastMessageReceived,
      Value<DateTime?>? lastFlameCounterChange,
      Value<DateTime>? lastMessageExchange,
      Value<int>? flameCounter}) {
    return ContactsCompanion(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      nickName: nickName ?? this.nickName,
      avatarSvg: avatarSvg ?? this.avatarSvg,
      myAvatarCounter: myAvatarCounter ?? this.myAvatarCounter,
      accepted: accepted ?? this.accepted,
      requested: requested ?? this.requested,
      blocked: blocked ?? this.blocked,
      verified: verified ?? this.verified,
      archived: archived ?? this.archived,
      deleteMessagesAfterXMinutes:
          deleteMessagesAfterXMinutes ?? this.deleteMessagesAfterXMinutes,
      createdAt: createdAt ?? this.createdAt,
      totalMediaCounter: totalMediaCounter ?? this.totalMediaCounter,
      lastMessageSend: lastMessageSend ?? this.lastMessageSend,
      lastMessageReceived: lastMessageReceived ?? this.lastMessageReceived,
      lastFlameCounterChange:
          lastFlameCounterChange ?? this.lastFlameCounterChange,
      lastMessageExchange: lastMessageExchange ?? this.lastMessageExchange,
      flameCounter: flameCounter ?? this.flameCounter,
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
    if (avatarSvg.present) {
      map['avatar_svg'] = Variable<String>(avatarSvg.value);
    }
    if (myAvatarCounter.present) {
      map['my_avatar_counter'] = Variable<int>(myAvatarCounter.value);
    }
    if (accepted.present) {
      map['accepted'] = Variable<bool>(accepted.value);
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
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (deleteMessagesAfterXMinutes.present) {
      map['delete_messages_after_x_minutes'] =
          Variable<int>(deleteMessagesAfterXMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (totalMediaCounter.present) {
      map['total_media_counter'] = Variable<int>(totalMediaCounter.value);
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
    if (lastMessageExchange.present) {
      map['last_message_exchange'] =
          Variable<DateTime>(lastMessageExchange.value);
    }
    if (flameCounter.present) {
      map['flame_counter'] = Variable<int>(flameCounter.value);
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
          ..write('avatarSvg: $avatarSvg, ')
          ..write('myAvatarCounter: $myAvatarCounter, ')
          ..write('accepted: $accepted, ')
          ..write('requested: $requested, ')
          ..write('blocked: $blocked, ')
          ..write('verified: $verified, ')
          ..write('archived: $archived, ')
          ..write('deleteMessagesAfterXMinutes: $deleteMessagesAfterXMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalMediaCounter: $totalMediaCounter, ')
          ..write('lastMessageSend: $lastMessageSend, ')
          ..write('lastMessageReceived: $lastMessageReceived, ')
          ..write('lastFlameCounterChange: $lastFlameCounterChange, ')
          ..write('lastMessageExchange: $lastMessageExchange, ')
          ..write('flameCounter: $flameCounter')
          ..write(')'))
        .toString();
  }
}

class Messages extends Table with TableInfo<Messages, MessagesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Messages(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (user_id)'));
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
      'message_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<int> messageOtherId = GeneratedColumn<int>(
      'message_other_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<int> mediaUploadId = GeneratedColumn<int>(
      'media_upload_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<int> mediaDownloadId = GeneratedColumn<int>(
      'media_download_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<int> responseToMessageId = GeneratedColumn<int>(
      'response_to_message_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<int> responseToOtherMessageId =
      GeneratedColumn<int>('response_to_other_message_id', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  late final GeneratedColumn<bool> acknowledgeByUser = GeneratedColumn<bool>(
      'acknowledge_by_user', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("acknowledge_by_user" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> mediaStored = GeneratedColumn<bool>(
      'media_stored', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("media_stored" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<int> downloadState = GeneratedColumn<int>(
      'download_state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('2'));
  late final GeneratedColumn<bool> acknowledgeByServer = GeneratedColumn<bool>(
      'acknowledge_by_server', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("acknowledge_by_server" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<bool> errorWhileSending = GeneratedColumn<bool>(
      'error_while_sending', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("error_while_sending" IN (0, 1))'),
      defaultValue: const CustomExpression('0'));
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  late final GeneratedColumn<DateTime> sendAt = GeneratedColumn<DateTime>(
      'send_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression(
          'CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)'));
  @override
  List<GeneratedColumn> get $columns => [
        contactId,
        messageId,
        messageOtherId,
        mediaUploadId,
        mediaDownloadId,
        responseToMessageId,
        responseToOtherMessageId,
        acknowledgeByUser,
        mediaStored,
        downloadState,
        acknowledgeByServer,
        errorWhileSending,
        kind,
        contentJson,
        openedAt,
        sendAt,
        updatedAt
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
      contactId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}contact_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}message_id'])!,
      messageOtherId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}message_other_id']),
      mediaUploadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_upload_id']),
      mediaDownloadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_download_id']),
      responseToMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}response_to_message_id']),
      responseToOtherMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}response_to_other_message_id']),
      acknowledgeByUser: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}acknowledge_by_user'])!,
      mediaStored: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}media_stored'])!,
      downloadState: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}download_state'])!,
      acknowledgeByServer: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}acknowledge_by_server'])!,
      errorWhileSending: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}error_while_sending'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      contentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_json']),
      openedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}opened_at']),
      sendAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}send_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  Messages createAlias(String alias) {
    return Messages(attachedDatabase, alias);
  }
}

class MessagesData extends DataClass implements Insertable<MessagesData> {
  final int contactId;
  final int messageId;
  final int? messageOtherId;
  final int? mediaUploadId;
  final int? mediaDownloadId;
  final int? responseToMessageId;
  final int? responseToOtherMessageId;
  final bool acknowledgeByUser;
  final bool mediaStored;
  final int downloadState;
  final bool acknowledgeByServer;
  final bool errorWhileSending;
  final String kind;
  final String? contentJson;
  final DateTime? openedAt;
  final DateTime sendAt;
  final DateTime updatedAt;
  const MessagesData(
      {required this.contactId,
      required this.messageId,
      this.messageOtherId,
      this.mediaUploadId,
      this.mediaDownloadId,
      this.responseToMessageId,
      this.responseToOtherMessageId,
      required this.acknowledgeByUser,
      required this.mediaStored,
      required this.downloadState,
      required this.acknowledgeByServer,
      required this.errorWhileSending,
      required this.kind,
      this.contentJson,
      this.openedAt,
      required this.sendAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_id'] = Variable<int>(contactId);
    map['message_id'] = Variable<int>(messageId);
    if (!nullToAbsent || messageOtherId != null) {
      map['message_other_id'] = Variable<int>(messageOtherId);
    }
    if (!nullToAbsent || mediaUploadId != null) {
      map['media_upload_id'] = Variable<int>(mediaUploadId);
    }
    if (!nullToAbsent || mediaDownloadId != null) {
      map['media_download_id'] = Variable<int>(mediaDownloadId);
    }
    if (!nullToAbsent || responseToMessageId != null) {
      map['response_to_message_id'] = Variable<int>(responseToMessageId);
    }
    if (!nullToAbsent || responseToOtherMessageId != null) {
      map['response_to_other_message_id'] =
          Variable<int>(responseToOtherMessageId);
    }
    map['acknowledge_by_user'] = Variable<bool>(acknowledgeByUser);
    map['media_stored'] = Variable<bool>(mediaStored);
    map['download_state'] = Variable<int>(downloadState);
    map['acknowledge_by_server'] = Variable<bool>(acknowledgeByServer);
    map['error_while_sending'] = Variable<bool>(errorWhileSending);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || contentJson != null) {
      map['content_json'] = Variable<String>(contentJson);
    }
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    map['send_at'] = Variable<DateTime>(sendAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      contactId: Value(contactId),
      messageId: Value(messageId),
      messageOtherId: messageOtherId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageOtherId),
      mediaUploadId: mediaUploadId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUploadId),
      mediaDownloadId: mediaDownloadId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaDownloadId),
      responseToMessageId: responseToMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(responseToMessageId),
      responseToOtherMessageId: responseToOtherMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(responseToOtherMessageId),
      acknowledgeByUser: Value(acknowledgeByUser),
      mediaStored: Value(mediaStored),
      downloadState: Value(downloadState),
      acknowledgeByServer: Value(acknowledgeByServer),
      errorWhileSending: Value(errorWhileSending),
      kind: Value(kind),
      contentJson: contentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contentJson),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      sendAt: Value(sendAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MessagesData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesData(
      contactId: serializer.fromJson<int>(json['contactId']),
      messageId: serializer.fromJson<int>(json['messageId']),
      messageOtherId: serializer.fromJson<int?>(json['messageOtherId']),
      mediaUploadId: serializer.fromJson<int?>(json['mediaUploadId']),
      mediaDownloadId: serializer.fromJson<int?>(json['mediaDownloadId']),
      responseToMessageId:
          serializer.fromJson<int?>(json['responseToMessageId']),
      responseToOtherMessageId:
          serializer.fromJson<int?>(json['responseToOtherMessageId']),
      acknowledgeByUser: serializer.fromJson<bool>(json['acknowledgeByUser']),
      mediaStored: serializer.fromJson<bool>(json['mediaStored']),
      downloadState: serializer.fromJson<int>(json['downloadState']),
      acknowledgeByServer:
          serializer.fromJson<bool>(json['acknowledgeByServer']),
      errorWhileSending: serializer.fromJson<bool>(json['errorWhileSending']),
      kind: serializer.fromJson<String>(json['kind']),
      contentJson: serializer.fromJson<String?>(json['contentJson']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      sendAt: serializer.fromJson<DateTime>(json['sendAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<int>(contactId),
      'messageId': serializer.toJson<int>(messageId),
      'messageOtherId': serializer.toJson<int?>(messageOtherId),
      'mediaUploadId': serializer.toJson<int?>(mediaUploadId),
      'mediaDownloadId': serializer.toJson<int?>(mediaDownloadId),
      'responseToMessageId': serializer.toJson<int?>(responseToMessageId),
      'responseToOtherMessageId':
          serializer.toJson<int?>(responseToOtherMessageId),
      'acknowledgeByUser': serializer.toJson<bool>(acknowledgeByUser),
      'mediaStored': serializer.toJson<bool>(mediaStored),
      'downloadState': serializer.toJson<int>(downloadState),
      'acknowledgeByServer': serializer.toJson<bool>(acknowledgeByServer),
      'errorWhileSending': serializer.toJson<bool>(errorWhileSending),
      'kind': serializer.toJson<String>(kind),
      'contentJson': serializer.toJson<String?>(contentJson),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'sendAt': serializer.toJson<DateTime>(sendAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MessagesData copyWith(
          {int? contactId,
          int? messageId,
          Value<int?> messageOtherId = const Value.absent(),
          Value<int?> mediaUploadId = const Value.absent(),
          Value<int?> mediaDownloadId = const Value.absent(),
          Value<int?> responseToMessageId = const Value.absent(),
          Value<int?> responseToOtherMessageId = const Value.absent(),
          bool? acknowledgeByUser,
          bool? mediaStored,
          int? downloadState,
          bool? acknowledgeByServer,
          bool? errorWhileSending,
          String? kind,
          Value<String?> contentJson = const Value.absent(),
          Value<DateTime?> openedAt = const Value.absent(),
          DateTime? sendAt,
          DateTime? updatedAt}) =>
      MessagesData(
        contactId: contactId ?? this.contactId,
        messageId: messageId ?? this.messageId,
        messageOtherId:
            messageOtherId.present ? messageOtherId.value : this.messageOtherId,
        mediaUploadId:
            mediaUploadId.present ? mediaUploadId.value : this.mediaUploadId,
        mediaDownloadId: mediaDownloadId.present
            ? mediaDownloadId.value
            : this.mediaDownloadId,
        responseToMessageId: responseToMessageId.present
            ? responseToMessageId.value
            : this.responseToMessageId,
        responseToOtherMessageId: responseToOtherMessageId.present
            ? responseToOtherMessageId.value
            : this.responseToOtherMessageId,
        acknowledgeByUser: acknowledgeByUser ?? this.acknowledgeByUser,
        mediaStored: mediaStored ?? this.mediaStored,
        downloadState: downloadState ?? this.downloadState,
        acknowledgeByServer: acknowledgeByServer ?? this.acknowledgeByServer,
        errorWhileSending: errorWhileSending ?? this.errorWhileSending,
        kind: kind ?? this.kind,
        contentJson: contentJson.present ? contentJson.value : this.contentJson,
        openedAt: openedAt.present ? openedAt.value : this.openedAt,
        sendAt: sendAt ?? this.sendAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MessagesData copyWithCompanion(MessagesCompanion data) {
    return MessagesData(
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      messageOtherId: data.messageOtherId.present
          ? data.messageOtherId.value
          : this.messageOtherId,
      mediaUploadId: data.mediaUploadId.present
          ? data.mediaUploadId.value
          : this.mediaUploadId,
      mediaDownloadId: data.mediaDownloadId.present
          ? data.mediaDownloadId.value
          : this.mediaDownloadId,
      responseToMessageId: data.responseToMessageId.present
          ? data.responseToMessageId.value
          : this.responseToMessageId,
      responseToOtherMessageId: data.responseToOtherMessageId.present
          ? data.responseToOtherMessageId.value
          : this.responseToOtherMessageId,
      acknowledgeByUser: data.acknowledgeByUser.present
          ? data.acknowledgeByUser.value
          : this.acknowledgeByUser,
      mediaStored:
          data.mediaStored.present ? data.mediaStored.value : this.mediaStored,
      downloadState: data.downloadState.present
          ? data.downloadState.value
          : this.downloadState,
      acknowledgeByServer: data.acknowledgeByServer.present
          ? data.acknowledgeByServer.value
          : this.acknowledgeByServer,
      errorWhileSending: data.errorWhileSending.present
          ? data.errorWhileSending.value
          : this.errorWhileSending,
      kind: data.kind.present ? data.kind.value : this.kind,
      contentJson:
          data.contentJson.present ? data.contentJson.value : this.contentJson,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      sendAt: data.sendAt.present ? data.sendAt.value : this.sendAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagesData(')
          ..write('contactId: $contactId, ')
          ..write('messageId: $messageId, ')
          ..write('messageOtherId: $messageOtherId, ')
          ..write('mediaUploadId: $mediaUploadId, ')
          ..write('mediaDownloadId: $mediaDownloadId, ')
          ..write('responseToMessageId: $responseToMessageId, ')
          ..write('responseToOtherMessageId: $responseToOtherMessageId, ')
          ..write('acknowledgeByUser: $acknowledgeByUser, ')
          ..write('mediaStored: $mediaStored, ')
          ..write('downloadState: $downloadState, ')
          ..write('acknowledgeByServer: $acknowledgeByServer, ')
          ..write('errorWhileSending: $errorWhileSending, ')
          ..write('kind: $kind, ')
          ..write('contentJson: $contentJson, ')
          ..write('openedAt: $openedAt, ')
          ..write('sendAt: $sendAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      contactId,
      messageId,
      messageOtherId,
      mediaUploadId,
      mediaDownloadId,
      responseToMessageId,
      responseToOtherMessageId,
      acknowledgeByUser,
      mediaStored,
      downloadState,
      acknowledgeByServer,
      errorWhileSending,
      kind,
      contentJson,
      openedAt,
      sendAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesData &&
          other.contactId == this.contactId &&
          other.messageId == this.messageId &&
          other.messageOtherId == this.messageOtherId &&
          other.mediaUploadId == this.mediaUploadId &&
          other.mediaDownloadId == this.mediaDownloadId &&
          other.responseToMessageId == this.responseToMessageId &&
          other.responseToOtherMessageId == this.responseToOtherMessageId &&
          other.acknowledgeByUser == this.acknowledgeByUser &&
          other.mediaStored == this.mediaStored &&
          other.downloadState == this.downloadState &&
          other.acknowledgeByServer == this.acknowledgeByServer &&
          other.errorWhileSending == this.errorWhileSending &&
          other.kind == this.kind &&
          other.contentJson == this.contentJson &&
          other.openedAt == this.openedAt &&
          other.sendAt == this.sendAt &&
          other.updatedAt == this.updatedAt);
}

class MessagesCompanion extends UpdateCompanion<MessagesData> {
  final Value<int> contactId;
  final Value<int> messageId;
  final Value<int?> messageOtherId;
  final Value<int?> mediaUploadId;
  final Value<int?> mediaDownloadId;
  final Value<int?> responseToMessageId;
  final Value<int?> responseToOtherMessageId;
  final Value<bool> acknowledgeByUser;
  final Value<bool> mediaStored;
  final Value<int> downloadState;
  final Value<bool> acknowledgeByServer;
  final Value<bool> errorWhileSending;
  final Value<String> kind;
  final Value<String?> contentJson;
  final Value<DateTime?> openedAt;
  final Value<DateTime> sendAt;
  final Value<DateTime> updatedAt;
  const MessagesCompanion({
    this.contactId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.messageOtherId = const Value.absent(),
    this.mediaUploadId = const Value.absent(),
    this.mediaDownloadId = const Value.absent(),
    this.responseToMessageId = const Value.absent(),
    this.responseToOtherMessageId = const Value.absent(),
    this.acknowledgeByUser = const Value.absent(),
    this.mediaStored = const Value.absent(),
    this.downloadState = const Value.absent(),
    this.acknowledgeByServer = const Value.absent(),
    this.errorWhileSending = const Value.absent(),
    this.kind = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.sendAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MessagesCompanion.insert({
    required int contactId,
    this.messageId = const Value.absent(),
    this.messageOtherId = const Value.absent(),
    this.mediaUploadId = const Value.absent(),
    this.mediaDownloadId = const Value.absent(),
    this.responseToMessageId = const Value.absent(),
    this.responseToOtherMessageId = const Value.absent(),
    this.acknowledgeByUser = const Value.absent(),
    this.mediaStored = const Value.absent(),
    this.downloadState = const Value.absent(),
    this.acknowledgeByServer = const Value.absent(),
    this.errorWhileSending = const Value.absent(),
    required String kind,
    this.contentJson = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.sendAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : contactId = Value(contactId),
        kind = Value(kind);
  static Insertable<MessagesData> custom({
    Expression<int>? contactId,
    Expression<int>? messageId,
    Expression<int>? messageOtherId,
    Expression<int>? mediaUploadId,
    Expression<int>? mediaDownloadId,
    Expression<int>? responseToMessageId,
    Expression<int>? responseToOtherMessageId,
    Expression<bool>? acknowledgeByUser,
    Expression<bool>? mediaStored,
    Expression<int>? downloadState,
    Expression<bool>? acknowledgeByServer,
    Expression<bool>? errorWhileSending,
    Expression<String>? kind,
    Expression<String>? contentJson,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? sendAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (contactId != null) 'contact_id': contactId,
      if (messageId != null) 'message_id': messageId,
      if (messageOtherId != null) 'message_other_id': messageOtherId,
      if (mediaUploadId != null) 'media_upload_id': mediaUploadId,
      if (mediaDownloadId != null) 'media_download_id': mediaDownloadId,
      if (responseToMessageId != null)
        'response_to_message_id': responseToMessageId,
      if (responseToOtherMessageId != null)
        'response_to_other_message_id': responseToOtherMessageId,
      if (acknowledgeByUser != null) 'acknowledge_by_user': acknowledgeByUser,
      if (mediaStored != null) 'media_stored': mediaStored,
      if (downloadState != null) 'download_state': downloadState,
      if (acknowledgeByServer != null)
        'acknowledge_by_server': acknowledgeByServer,
      if (errorWhileSending != null) 'error_while_sending': errorWhileSending,
      if (kind != null) 'kind': kind,
      if (contentJson != null) 'content_json': contentJson,
      if (openedAt != null) 'opened_at': openedAt,
      if (sendAt != null) 'send_at': sendAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MessagesCompanion copyWith(
      {Value<int>? contactId,
      Value<int>? messageId,
      Value<int?>? messageOtherId,
      Value<int?>? mediaUploadId,
      Value<int?>? mediaDownloadId,
      Value<int?>? responseToMessageId,
      Value<int?>? responseToOtherMessageId,
      Value<bool>? acknowledgeByUser,
      Value<bool>? mediaStored,
      Value<int>? downloadState,
      Value<bool>? acknowledgeByServer,
      Value<bool>? errorWhileSending,
      Value<String>? kind,
      Value<String?>? contentJson,
      Value<DateTime?>? openedAt,
      Value<DateTime>? sendAt,
      Value<DateTime>? updatedAt}) {
    return MessagesCompanion(
      contactId: contactId ?? this.contactId,
      messageId: messageId ?? this.messageId,
      messageOtherId: messageOtherId ?? this.messageOtherId,
      mediaUploadId: mediaUploadId ?? this.mediaUploadId,
      mediaDownloadId: mediaDownloadId ?? this.mediaDownloadId,
      responseToMessageId: responseToMessageId ?? this.responseToMessageId,
      responseToOtherMessageId:
          responseToOtherMessageId ?? this.responseToOtherMessageId,
      acknowledgeByUser: acknowledgeByUser ?? this.acknowledgeByUser,
      mediaStored: mediaStored ?? this.mediaStored,
      downloadState: downloadState ?? this.downloadState,
      acknowledgeByServer: acknowledgeByServer ?? this.acknowledgeByServer,
      errorWhileSending: errorWhileSending ?? this.errorWhileSending,
      kind: kind ?? this.kind,
      contentJson: contentJson ?? this.contentJson,
      openedAt: openedAt ?? this.openedAt,
      sendAt: sendAt ?? this.sendAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (messageOtherId.present) {
      map['message_other_id'] = Variable<int>(messageOtherId.value);
    }
    if (mediaUploadId.present) {
      map['media_upload_id'] = Variable<int>(mediaUploadId.value);
    }
    if (mediaDownloadId.present) {
      map['media_download_id'] = Variable<int>(mediaDownloadId.value);
    }
    if (responseToMessageId.present) {
      map['response_to_message_id'] = Variable<int>(responseToMessageId.value);
    }
    if (responseToOtherMessageId.present) {
      map['response_to_other_message_id'] =
          Variable<int>(responseToOtherMessageId.value);
    }
    if (acknowledgeByUser.present) {
      map['acknowledge_by_user'] = Variable<bool>(acknowledgeByUser.value);
    }
    if (mediaStored.present) {
      map['media_stored'] = Variable<bool>(mediaStored.value);
    }
    if (downloadState.present) {
      map['download_state'] = Variable<int>(downloadState.value);
    }
    if (acknowledgeByServer.present) {
      map['acknowledge_by_server'] = Variable<bool>(acknowledgeByServer.value);
    }
    if (errorWhileSending.present) {
      map['error_while_sending'] = Variable<bool>(errorWhileSending.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (sendAt.present) {
      map['send_at'] = Variable<DateTime>(sendAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('contactId: $contactId, ')
          ..write('messageId: $messageId, ')
          ..write('messageOtherId: $messageOtherId, ')
          ..write('mediaUploadId: $mediaUploadId, ')
          ..write('mediaDownloadId: $mediaDownloadId, ')
          ..write('responseToMessageId: $responseToMessageId, ')
          ..write('responseToOtherMessageId: $responseToOtherMessageId, ')
          ..write('acknowledgeByUser: $acknowledgeByUser, ')
          ..write('mediaStored: $mediaStored, ')
          ..write('downloadState: $downloadState, ')
          ..write('acknowledgeByServer: $acknowledgeByServer, ')
          ..write('errorWhileSending: $errorWhileSending, ')
          ..write('kind: $kind, ')
          ..write('contentJson: $contentJson, ')
          ..write('openedAt: $openedAt, ')
          ..write('sendAt: $sendAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class MediaUploads extends Table
    with TableInfo<MediaUploads, MediaUploadsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MediaUploads(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> mediaUploadId = GeneratedColumn<int>(
      'media_upload_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('\'pending\''));
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  late final GeneratedColumn<String> messageIds = GeneratedColumn<String>(
      'message_ids', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> encryptionData = GeneratedColumn<String>(
      'encryption_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> uploadTokens = GeneratedColumn<String>(
      'upload_tokens', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  late final GeneratedColumn<String> alreadyNotified = GeneratedColumn<String>(
      'already_notified', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const CustomExpression('\'[]\''));
  @override
  List<GeneratedColumn> get $columns => [
        mediaUploadId,
        state,
        metadata,
        messageIds,
        encryptionData,
        uploadTokens,
        alreadyNotified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_uploads';
  @override
  Set<GeneratedColumn> get $primaryKey => {mediaUploadId};
  @override
  MediaUploadsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaUploadsData(
      mediaUploadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_upload_id'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])!,
      messageIds: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_ids']),
      encryptionData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}encryption_data']),
      uploadTokens: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}upload_tokens']),
      alreadyNotified: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}already_notified'])!,
    );
  }

  @override
  MediaUploads createAlias(String alias) {
    return MediaUploads(attachedDatabase, alias);
  }
}

class MediaUploadsData extends DataClass
    implements Insertable<MediaUploadsData> {
  final int mediaUploadId;
  final String state;
  final String metadata;
  final String? messageIds;
  final String? encryptionData;
  final String? uploadTokens;
  final String alreadyNotified;
  const MediaUploadsData(
      {required this.mediaUploadId,
      required this.state,
      required this.metadata,
      this.messageIds,
      this.encryptionData,
      this.uploadTokens,
      required this.alreadyNotified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_upload_id'] = Variable<int>(mediaUploadId);
    map['state'] = Variable<String>(state);
    map['metadata'] = Variable<String>(metadata);
    if (!nullToAbsent || messageIds != null) {
      map['message_ids'] = Variable<String>(messageIds);
    }
    if (!nullToAbsent || encryptionData != null) {
      map['encryption_data'] = Variable<String>(encryptionData);
    }
    if (!nullToAbsent || uploadTokens != null) {
      map['upload_tokens'] = Variable<String>(uploadTokens);
    }
    map['already_notified'] = Variable<String>(alreadyNotified);
    return map;
  }

  MediaUploadsCompanion toCompanion(bool nullToAbsent) {
    return MediaUploadsCompanion(
      mediaUploadId: Value(mediaUploadId),
      state: Value(state),
      metadata: Value(metadata),
      messageIds: messageIds == null && nullToAbsent
          ? const Value.absent()
          : Value(messageIds),
      encryptionData: encryptionData == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptionData),
      uploadTokens: uploadTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadTokens),
      alreadyNotified: Value(alreadyNotified),
    );
  }

  factory MediaUploadsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaUploadsData(
      mediaUploadId: serializer.fromJson<int>(json['mediaUploadId']),
      state: serializer.fromJson<String>(json['state']),
      metadata: serializer.fromJson<String>(json['metadata']),
      messageIds: serializer.fromJson<String?>(json['messageIds']),
      encryptionData: serializer.fromJson<String?>(json['encryptionData']),
      uploadTokens: serializer.fromJson<String?>(json['uploadTokens']),
      alreadyNotified: serializer.fromJson<String>(json['alreadyNotified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaUploadId': serializer.toJson<int>(mediaUploadId),
      'state': serializer.toJson<String>(state),
      'metadata': serializer.toJson<String>(metadata),
      'messageIds': serializer.toJson<String?>(messageIds),
      'encryptionData': serializer.toJson<String?>(encryptionData),
      'uploadTokens': serializer.toJson<String?>(uploadTokens),
      'alreadyNotified': serializer.toJson<String>(alreadyNotified),
    };
  }

  MediaUploadsData copyWith(
          {int? mediaUploadId,
          String? state,
          String? metadata,
          Value<String?> messageIds = const Value.absent(),
          Value<String?> encryptionData = const Value.absent(),
          Value<String?> uploadTokens = const Value.absent(),
          String? alreadyNotified}) =>
      MediaUploadsData(
        mediaUploadId: mediaUploadId ?? this.mediaUploadId,
        state: state ?? this.state,
        metadata: metadata ?? this.metadata,
        messageIds: messageIds.present ? messageIds.value : this.messageIds,
        encryptionData:
            encryptionData.present ? encryptionData.value : this.encryptionData,
        uploadTokens:
            uploadTokens.present ? uploadTokens.value : this.uploadTokens,
        alreadyNotified: alreadyNotified ?? this.alreadyNotified,
      );
  MediaUploadsData copyWithCompanion(MediaUploadsCompanion data) {
    return MediaUploadsData(
      mediaUploadId: data.mediaUploadId.present
          ? data.mediaUploadId.value
          : this.mediaUploadId,
      state: data.state.present ? data.state.value : this.state,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      messageIds:
          data.messageIds.present ? data.messageIds.value : this.messageIds,
      encryptionData: data.encryptionData.present
          ? data.encryptionData.value
          : this.encryptionData,
      uploadTokens: data.uploadTokens.present
          ? data.uploadTokens.value
          : this.uploadTokens,
      alreadyNotified: data.alreadyNotified.present
          ? data.alreadyNotified.value
          : this.alreadyNotified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaUploadsData(')
          ..write('mediaUploadId: $mediaUploadId, ')
          ..write('state: $state, ')
          ..write('metadata: $metadata, ')
          ..write('messageIds: $messageIds, ')
          ..write('encryptionData: $encryptionData, ')
          ..write('uploadTokens: $uploadTokens, ')
          ..write('alreadyNotified: $alreadyNotified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(mediaUploadId, state, metadata, messageIds,
      encryptionData, uploadTokens, alreadyNotified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaUploadsData &&
          other.mediaUploadId == this.mediaUploadId &&
          other.state == this.state &&
          other.metadata == this.metadata &&
          other.messageIds == this.messageIds &&
          other.encryptionData == this.encryptionData &&
          other.uploadTokens == this.uploadTokens &&
          other.alreadyNotified == this.alreadyNotified);
}

class MediaUploadsCompanion extends UpdateCompanion<MediaUploadsData> {
  final Value<int> mediaUploadId;
  final Value<String> state;
  final Value<String> metadata;
  final Value<String?> messageIds;
  final Value<String?> encryptionData;
  final Value<String?> uploadTokens;
  final Value<String> alreadyNotified;
  const MediaUploadsCompanion({
    this.mediaUploadId = const Value.absent(),
    this.state = const Value.absent(),
    this.metadata = const Value.absent(),
    this.messageIds = const Value.absent(),
    this.encryptionData = const Value.absent(),
    this.uploadTokens = const Value.absent(),
    this.alreadyNotified = const Value.absent(),
  });
  MediaUploadsCompanion.insert({
    this.mediaUploadId = const Value.absent(),
    this.state = const Value.absent(),
    required String metadata,
    this.messageIds = const Value.absent(),
    this.encryptionData = const Value.absent(),
    this.uploadTokens = const Value.absent(),
    this.alreadyNotified = const Value.absent(),
  }) : metadata = Value(metadata);
  static Insertable<MediaUploadsData> custom({
    Expression<int>? mediaUploadId,
    Expression<String>? state,
    Expression<String>? metadata,
    Expression<String>? messageIds,
    Expression<String>? encryptionData,
    Expression<String>? uploadTokens,
    Expression<String>? alreadyNotified,
  }) {
    return RawValuesInsertable({
      if (mediaUploadId != null) 'media_upload_id': mediaUploadId,
      if (state != null) 'state': state,
      if (metadata != null) 'metadata': metadata,
      if (messageIds != null) 'message_ids': messageIds,
      if (encryptionData != null) 'encryption_data': encryptionData,
      if (uploadTokens != null) 'upload_tokens': uploadTokens,
      if (alreadyNotified != null) 'already_notified': alreadyNotified,
    });
  }

  MediaUploadsCompanion copyWith(
      {Value<int>? mediaUploadId,
      Value<String>? state,
      Value<String>? metadata,
      Value<String?>? messageIds,
      Value<String?>? encryptionData,
      Value<String?>? uploadTokens,
      Value<String>? alreadyNotified}) {
    return MediaUploadsCompanion(
      mediaUploadId: mediaUploadId ?? this.mediaUploadId,
      state: state ?? this.state,
      metadata: metadata ?? this.metadata,
      messageIds: messageIds ?? this.messageIds,
      encryptionData: encryptionData ?? this.encryptionData,
      uploadTokens: uploadTokens ?? this.uploadTokens,
      alreadyNotified: alreadyNotified ?? this.alreadyNotified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaUploadId.present) {
      map['media_upload_id'] = Variable<int>(mediaUploadId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (messageIds.present) {
      map['message_ids'] = Variable<String>(messageIds.value);
    }
    if (encryptionData.present) {
      map['encryption_data'] = Variable<String>(encryptionData.value);
    }
    if (uploadTokens.present) {
      map['upload_tokens'] = Variable<String>(uploadTokens.value);
    }
    if (alreadyNotified.present) {
      map['already_notified'] = Variable<String>(alreadyNotified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaUploadsCompanion(')
          ..write('mediaUploadId: $mediaUploadId, ')
          ..write('state: $state, ')
          ..write('metadata: $metadata, ')
          ..write('messageIds: $messageIds, ')
          ..write('encryptionData: $encryptionData, ')
          ..write('uploadTokens: $uploadTokens, ')
          ..write('alreadyNotified: $alreadyNotified')
          ..write(')'))
        .toString();
  }
}

class MediaDownloads extends Table
    with TableInfo<MediaDownloads, MediaDownloadsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MediaDownloads(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
      'message_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  late final GeneratedColumn<String> downloadToken = GeneratedColumn<String>(
      'download_token', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [messageId, downloadToken];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_downloads';
  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  MediaDownloadsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaDownloadsData(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}message_id'])!,
      downloadToken: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}download_token'])!,
    );
  }

  @override
  MediaDownloads createAlias(String alias) {
    return MediaDownloads(attachedDatabase, alias);
  }
}

class MediaDownloadsData extends DataClass
    implements Insertable<MediaDownloadsData> {
  final int messageId;
  final String downloadToken;
  const MediaDownloadsData(
      {required this.messageId, required this.downloadToken});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<int>(messageId);
    map['download_token'] = Variable<String>(downloadToken);
    return map;
  }

  MediaDownloadsCompanion toCompanion(bool nullToAbsent) {
    return MediaDownloadsCompanion(
      messageId: Value(messageId),
      downloadToken: Value(downloadToken),
    );
  }

  factory MediaDownloadsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaDownloadsData(
      messageId: serializer.fromJson<int>(json['messageId']),
      downloadToken: serializer.fromJson<String>(json['downloadToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<int>(messageId),
      'downloadToken': serializer.toJson<String>(downloadToken),
    };
  }

  MediaDownloadsData copyWith({int? messageId, String? downloadToken}) =>
      MediaDownloadsData(
        messageId: messageId ?? this.messageId,
        downloadToken: downloadToken ?? this.downloadToken,
      );
  MediaDownloadsData copyWithCompanion(MediaDownloadsCompanion data) {
    return MediaDownloadsData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      downloadToken: data.downloadToken.present
          ? data.downloadToken.value
          : this.downloadToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaDownloadsData(')
          ..write('messageId: $messageId, ')
          ..write('downloadToken: $downloadToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, downloadToken);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaDownloadsData &&
          other.messageId == this.messageId &&
          other.downloadToken == this.downloadToken);
}

class MediaDownloadsCompanion extends UpdateCompanion<MediaDownloadsData> {
  final Value<int> messageId;
  final Value<String> downloadToken;
  final Value<int> rowid;
  const MediaDownloadsCompanion({
    this.messageId = const Value.absent(),
    this.downloadToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaDownloadsCompanion.insert({
    required int messageId,
    required String downloadToken,
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        downloadToken = Value(downloadToken);
  static Insertable<MediaDownloadsData> custom({
    Expression<int>? messageId,
    Expression<String>? downloadToken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (downloadToken != null) 'download_token': downloadToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaDownloadsCompanion copyWith(
      {Value<int>? messageId,
      Value<String>? downloadToken,
      Value<int>? rowid}) {
    return MediaDownloadsCompanion(
      messageId: messageId ?? this.messageId,
      downloadToken: downloadToken ?? this.downloadToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (downloadToken.present) {
      map['download_token'] = Variable<String>(downloadToken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaDownloadsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('downloadToken: $downloadToken, ')
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

class DatabaseAtV6 extends GeneratedDatabase {
  DatabaseAtV6(QueryExecutor e) : super(e);
  late final Contacts contacts = Contacts(this);
  late final Messages messages = Messages(this);
  late final MediaUploads mediaUploads = MediaUploads(this);
  late final MediaDownloads mediaDownloads = MediaDownloads(this);
  late final SignalIdentityKeyStores signalIdentityKeyStores =
      SignalIdentityKeyStores(this);
  late final SignalPreKeyStores signalPreKeyStores = SignalPreKeyStores(this);
  late final SignalSenderKeyStores signalSenderKeyStores =
      SignalSenderKeyStores(this);
  late final SignalSessionStores signalSessionStores =
      SignalSessionStores(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        contacts,
        messages,
        mediaUploads,
        mediaDownloads,
        signalIdentityKeyStores,
        signalPreKeyStores,
        signalSenderKeyStores,
        signalSessionStores
      ];
  @override
  int get schemaVersion => 6;
}
