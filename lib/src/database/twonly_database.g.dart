// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twonly_database.dart';

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
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
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
  static const VerificationMeta _avatarSvgMeta =
      const VerificationMeta('avatarSvg');
  @override
  late final GeneratedColumn<String> avatarSvg = GeneratedColumn<String>(
      'avatar_svg', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _myAvatarCounterMeta =
      const VerificationMeta('myAvatarCounter');
  @override
  late final GeneratedColumn<int> myAvatarCounter = GeneratedColumn<int>(
      'my_avatar_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
  static const VerificationMeta _acceptedMeta =
      const VerificationMeta('accepted');
  @override
  late final GeneratedColumn<bool> accepted = GeneratedColumn<bool>(
      'accepted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("accepted" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _requestedMeta =
      const VerificationMeta('requested');
  @override
  late final GeneratedColumn<bool> requested = GeneratedColumn<bool>(
      'requested', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("requested" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _blockedMeta =
      const VerificationMeta('blocked');
  @override
  late final GeneratedColumn<bool> blocked = GeneratedColumn<bool>(
      'blocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("blocked" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _verifiedMeta =
      const VerificationMeta('verified');
  @override
  late final GeneratedColumn<bool> verified = GeneratedColumn<bool>(
      'verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("verified" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _alsoBestFriendMeta =
      const VerificationMeta('alsoBestFriend');
  @override
  late final GeneratedColumn<bool> alsoBestFriend = GeneratedColumn<bool>(
      'also_best_friend', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("also_best_friend" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _deleteMessagesAfterXMinutesMeta =
      const VerificationMeta('deleteMessagesAfterXMinutes');
  @override
  late final GeneratedColumn<int> deleteMessagesAfterXMinutes =
      GeneratedColumn<int>(
          'delete_messages_after_x_minutes', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: Constant(60 * 24));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _totalMediaCounterMeta =
      const VerificationMeta('totalMediaCounter');
  @override
  late final GeneratedColumn<int> totalMediaCounter = GeneratedColumn<int>(
      'total_media_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
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
  static const VerificationMeta _lastMessageExchangeMeta =
      const VerificationMeta('lastMessageExchange');
  @override
  late final GeneratedColumn<DateTime> lastMessageExchange =
      GeneratedColumn<DateTime>('last_message_exchange', aliasedName, false,
          type: DriftSqlType.dateTime,
          requiredDuringInsert: false,
          defaultValue: currentDateAndTime);
  static const VerificationMeta _flameCounterMeta =
      const VerificationMeta('flameCounter');
  @override
  late final GeneratedColumn<int> flameCounter = GeneratedColumn<int>(
      'flame_counter', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
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
        pinned,
        alsoBestFriend,
        deleteMessagesAfterXMinutes,
        createdAt,
        totalMediaCounter,
        lastMessageSend,
        lastMessageReceived,
        lastFlameCounterChange,
        lastFlameSync,
        lastMessageExchange,
        flameCounter
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
    if (data.containsKey('avatar_svg')) {
      context.handle(_avatarSvgMeta,
          avatarSvg.isAcceptableOrUnknown(data['avatar_svg']!, _avatarSvgMeta));
    }
    if (data.containsKey('my_avatar_counter')) {
      context.handle(
          _myAvatarCounterMeta,
          myAvatarCounter.isAcceptableOrUnknown(
              data['my_avatar_counter']!, _myAvatarCounterMeta));
    }
    if (data.containsKey('accepted')) {
      context.handle(_acceptedMeta,
          accepted.isAcceptableOrUnknown(data['accepted']!, _acceptedMeta));
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
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('also_best_friend')) {
      context.handle(
          _alsoBestFriendMeta,
          alsoBestFriend.isAcceptableOrUnknown(
              data['also_best_friend']!, _alsoBestFriendMeta));
    }
    if (data.containsKey('delete_messages_after_x_minutes')) {
      context.handle(
          _deleteMessagesAfterXMinutesMeta,
          deleteMessagesAfterXMinutes.isAcceptableOrUnknown(
              data['delete_messages_after_x_minutes']!,
              _deleteMessagesAfterXMinutesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('total_media_counter')) {
      context.handle(
          _totalMediaCounterMeta,
          totalMediaCounter.isAcceptableOrUnknown(
              data['total_media_counter']!, _totalMediaCounterMeta));
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
    if (data.containsKey('last_message_exchange')) {
      context.handle(
          _lastMessageExchangeMeta,
          lastMessageExchange.isAcceptableOrUnknown(
              data['last_message_exchange']!, _lastMessageExchangeMeta));
    }
    if (data.containsKey('flame_counter')) {
      context.handle(
          _flameCounterMeta,
          flameCounter.isAcceptableOrUnknown(
              data['flame_counter']!, _flameCounterMeta));
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
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      alsoBestFriend: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}also_best_friend'])!,
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
      lastFlameSync: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_flame_sync']),
      lastMessageExchange: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_message_exchange'])!,
      flameCounter: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}flame_counter'])!,
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
  final String? avatarSvg;
  final int myAvatarCounter;
  final bool accepted;
  final bool requested;
  final bool blocked;
  final bool verified;
  final bool archived;
  final bool pinned;
  final bool alsoBestFriend;
  final int deleteMessagesAfterXMinutes;
  final DateTime createdAt;
  final int totalMediaCounter;
  final DateTime? lastMessageSend;
  final DateTime? lastMessageReceived;
  final DateTime? lastFlameCounterChange;
  final DateTime? lastFlameSync;
  final DateTime lastMessageExchange;
  final int flameCounter;
  const Contact(
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
      required this.pinned,
      required this.alsoBestFriend,
      required this.deleteMessagesAfterXMinutes,
      required this.createdAt,
      required this.totalMediaCounter,
      this.lastMessageSend,
      this.lastMessageReceived,
      this.lastFlameCounterChange,
      this.lastFlameSync,
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
    map['pinned'] = Variable<bool>(pinned);
    map['also_best_friend'] = Variable<bool>(alsoBestFriend);
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
    if (!nullToAbsent || lastFlameSync != null) {
      map['last_flame_sync'] = Variable<DateTime>(lastFlameSync);
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
      pinned: Value(pinned),
      alsoBestFriend: Value(alsoBestFriend),
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
      lastFlameSync: lastFlameSync == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFlameSync),
      lastMessageExchange: Value(lastMessageExchange),
      flameCounter: Value(flameCounter),
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
      avatarSvg: serializer.fromJson<String?>(json['avatarSvg']),
      myAvatarCounter: serializer.fromJson<int>(json['myAvatarCounter']),
      accepted: serializer.fromJson<bool>(json['accepted']),
      requested: serializer.fromJson<bool>(json['requested']),
      blocked: serializer.fromJson<bool>(json['blocked']),
      verified: serializer.fromJson<bool>(json['verified']),
      archived: serializer.fromJson<bool>(json['archived']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      alsoBestFriend: serializer.fromJson<bool>(json['alsoBestFriend']),
      deleteMessagesAfterXMinutes:
          serializer.fromJson<int>(json['deleteMessagesAfterXMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      totalMediaCounter: serializer.fromJson<int>(json['totalMediaCounter']),
      lastMessageSend: serializer.fromJson<DateTime?>(json['lastMessageSend']),
      lastMessageReceived:
          serializer.fromJson<DateTime?>(json['lastMessageReceived']),
      lastFlameCounterChange:
          serializer.fromJson<DateTime?>(json['lastFlameCounterChange']),
      lastFlameSync: serializer.fromJson<DateTime?>(json['lastFlameSync']),
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
      'pinned': serializer.toJson<bool>(pinned),
      'alsoBestFriend': serializer.toJson<bool>(alsoBestFriend),
      'deleteMessagesAfterXMinutes':
          serializer.toJson<int>(deleteMessagesAfterXMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'totalMediaCounter': serializer.toJson<int>(totalMediaCounter),
      'lastMessageSend': serializer.toJson<DateTime?>(lastMessageSend),
      'lastMessageReceived': serializer.toJson<DateTime?>(lastMessageReceived),
      'lastFlameCounterChange':
          serializer.toJson<DateTime?>(lastFlameCounterChange),
      'lastFlameSync': serializer.toJson<DateTime?>(lastFlameSync),
      'lastMessageExchange': serializer.toJson<DateTime>(lastMessageExchange),
      'flameCounter': serializer.toJson<int>(flameCounter),
    };
  }

  Contact copyWith(
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
          bool? pinned,
          bool? alsoBestFriend,
          int? deleteMessagesAfterXMinutes,
          DateTime? createdAt,
          int? totalMediaCounter,
          Value<DateTime?> lastMessageSend = const Value.absent(),
          Value<DateTime?> lastMessageReceived = const Value.absent(),
          Value<DateTime?> lastFlameCounterChange = const Value.absent(),
          Value<DateTime?> lastFlameSync = const Value.absent(),
          DateTime? lastMessageExchange,
          int? flameCounter}) =>
      Contact(
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
        pinned: pinned ?? this.pinned,
        alsoBestFriend: alsoBestFriend ?? this.alsoBestFriend,
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
        lastFlameSync:
            lastFlameSync.present ? lastFlameSync.value : this.lastFlameSync,
        lastMessageExchange: lastMessageExchange ?? this.lastMessageExchange,
        flameCounter: flameCounter ?? this.flameCounter,
      );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
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
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      alsoBestFriend: data.alsoBestFriend.present
          ? data.alsoBestFriend.value
          : this.alsoBestFriend,
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
      lastFlameSync: data.lastFlameSync.present
          ? data.lastFlameSync.value
          : this.lastFlameSync,
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
    return (StringBuffer('Contact(')
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
          ..write('pinned: $pinned, ')
          ..write('alsoBestFriend: $alsoBestFriend, ')
          ..write('deleteMessagesAfterXMinutes: $deleteMessagesAfterXMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalMediaCounter: $totalMediaCounter, ')
          ..write('lastMessageSend: $lastMessageSend, ')
          ..write('lastMessageReceived: $lastMessageReceived, ')
          ..write('lastFlameCounterChange: $lastFlameCounterChange, ')
          ..write('lastFlameSync: $lastFlameSync, ')
          ..write('lastMessageExchange: $lastMessageExchange, ')
          ..write('flameCounter: $flameCounter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
        pinned,
        alsoBestFriend,
        deleteMessagesAfterXMinutes,
        createdAt,
        totalMediaCounter,
        lastMessageSend,
        lastMessageReceived,
        lastFlameCounterChange,
        lastFlameSync,
        lastMessageExchange,
        flameCounter
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
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
          other.pinned == this.pinned &&
          other.alsoBestFriend == this.alsoBestFriend &&
          other.deleteMessagesAfterXMinutes ==
              this.deleteMessagesAfterXMinutes &&
          other.createdAt == this.createdAt &&
          other.totalMediaCounter == this.totalMediaCounter &&
          other.lastMessageSend == this.lastMessageSend &&
          other.lastMessageReceived == this.lastMessageReceived &&
          other.lastFlameCounterChange == this.lastFlameCounterChange &&
          other.lastFlameSync == this.lastFlameSync &&
          other.lastMessageExchange == this.lastMessageExchange &&
          other.flameCounter == this.flameCounter);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
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
  final Value<bool> pinned;
  final Value<bool> alsoBestFriend;
  final Value<int> deleteMessagesAfterXMinutes;
  final Value<DateTime> createdAt;
  final Value<int> totalMediaCounter;
  final Value<DateTime?> lastMessageSend;
  final Value<DateTime?> lastMessageReceived;
  final Value<DateTime?> lastFlameCounterChange;
  final Value<DateTime?> lastFlameSync;
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
    this.pinned = const Value.absent(),
    this.alsoBestFriend = const Value.absent(),
    this.deleteMessagesAfterXMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.totalMediaCounter = const Value.absent(),
    this.lastMessageSend = const Value.absent(),
    this.lastMessageReceived = const Value.absent(),
    this.lastFlameCounterChange = const Value.absent(),
    this.lastFlameSync = const Value.absent(),
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
    this.pinned = const Value.absent(),
    this.alsoBestFriend = const Value.absent(),
    this.deleteMessagesAfterXMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.totalMediaCounter = const Value.absent(),
    this.lastMessageSend = const Value.absent(),
    this.lastMessageReceived = const Value.absent(),
    this.lastFlameCounterChange = const Value.absent(),
    this.lastFlameSync = const Value.absent(),
    this.lastMessageExchange = const Value.absent(),
    this.flameCounter = const Value.absent(),
  }) : username = Value(username);
  static Insertable<Contact> custom({
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
    Expression<bool>? pinned,
    Expression<bool>? alsoBestFriend,
    Expression<int>? deleteMessagesAfterXMinutes,
    Expression<DateTime>? createdAt,
    Expression<int>? totalMediaCounter,
    Expression<DateTime>? lastMessageSend,
    Expression<DateTime>? lastMessageReceived,
    Expression<DateTime>? lastFlameCounterChange,
    Expression<DateTime>? lastFlameSync,
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
      if (pinned != null) 'pinned': pinned,
      if (alsoBestFriend != null) 'also_best_friend': alsoBestFriend,
      if (deleteMessagesAfterXMinutes != null)
        'delete_messages_after_x_minutes': deleteMessagesAfterXMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (totalMediaCounter != null) 'total_media_counter': totalMediaCounter,
      if (lastMessageSend != null) 'last_message_send': lastMessageSend,
      if (lastMessageReceived != null)
        'last_message_received': lastMessageReceived,
      if (lastFlameCounterChange != null)
        'last_flame_counter_change': lastFlameCounterChange,
      if (lastFlameSync != null) 'last_flame_sync': lastFlameSync,
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
      Value<bool>? pinned,
      Value<bool>? alsoBestFriend,
      Value<int>? deleteMessagesAfterXMinutes,
      Value<DateTime>? createdAt,
      Value<int>? totalMediaCounter,
      Value<DateTime?>? lastMessageSend,
      Value<DateTime?>? lastMessageReceived,
      Value<DateTime?>? lastFlameCounterChange,
      Value<DateTime?>? lastFlameSync,
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
      pinned: pinned ?? this.pinned,
      alsoBestFriend: alsoBestFriend ?? this.alsoBestFriend,
      deleteMessagesAfterXMinutes:
          deleteMessagesAfterXMinutes ?? this.deleteMessagesAfterXMinutes,
      createdAt: createdAt ?? this.createdAt,
      totalMediaCounter: totalMediaCounter ?? this.totalMediaCounter,
      lastMessageSend: lastMessageSend ?? this.lastMessageSend,
      lastMessageReceived: lastMessageReceived ?? this.lastMessageReceived,
      lastFlameCounterChange:
          lastFlameCounterChange ?? this.lastFlameCounterChange,
      lastFlameSync: lastFlameSync ?? this.lastFlameSync,
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
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (alsoBestFriend.present) {
      map['also_best_friend'] = Variable<bool>(alsoBestFriend.value);
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
    if (lastFlameSync.present) {
      map['last_flame_sync'] = Variable<DateTime>(lastFlameSync.value);
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
          ..write('pinned: $pinned, ')
          ..write('alsoBestFriend: $alsoBestFriend, ')
          ..write('deleteMessagesAfterXMinutes: $deleteMessagesAfterXMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalMediaCounter: $totalMediaCounter, ')
          ..write('lastMessageSend: $lastMessageSend, ')
          ..write('lastMessageReceived: $lastMessageReceived, ')
          ..write('lastFlameCounterChange: $lastFlameCounterChange, ')
          ..write('lastFlameSync: $lastFlameSync, ')
          ..write('lastMessageExchange: $lastMessageExchange, ')
          ..write('flameCounter: $flameCounter')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactIdMeta =
      const VerificationMeta('contactId');
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
      'contact_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES contacts (user_id)'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
      'message_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageOtherIdMeta =
      const VerificationMeta('messageOtherId');
  @override
  late final GeneratedColumn<int> messageOtherId = GeneratedColumn<int>(
      'message_other_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _mediaUploadIdMeta =
      const VerificationMeta('mediaUploadId');
  @override
  late final GeneratedColumn<int> mediaUploadId = GeneratedColumn<int>(
      'media_upload_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _mediaDownloadIdMeta =
      const VerificationMeta('mediaDownloadId');
  @override
  late final GeneratedColumn<int> mediaDownloadId = GeneratedColumn<int>(
      'media_download_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _responseToMessageIdMeta =
      const VerificationMeta('responseToMessageId');
  @override
  late final GeneratedColumn<int> responseToMessageId = GeneratedColumn<int>(
      'response_to_message_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _responseToOtherMessageIdMeta =
      const VerificationMeta('responseToOtherMessageId');
  @override
  late final GeneratedColumn<int> responseToOtherMessageId =
      GeneratedColumn<int>('response_to_other_message_id', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acknowledgeByUserMeta =
      const VerificationMeta('acknowledgeByUser');
  @override
  late final GeneratedColumn<bool> acknowledgeByUser = GeneratedColumn<bool>(
      'acknowledge_by_user', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("acknowledge_by_user" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _mediaStoredMeta =
      const VerificationMeta('mediaStored');
  @override
  late final GeneratedColumn<bool> mediaStored = GeneratedColumn<bool>(
      'media_stored', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("media_stored" IN (0, 1))'),
      defaultValue: Constant(false));
  @override
  late final GeneratedColumnWithTypeConverter<DownloadState, int>
      downloadState = GeneratedColumn<int>('download_state', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: Constant(DownloadState.downloaded.index))
          .withConverter<DownloadState>($MessagesTable.$converterdownloadState);
  static const VerificationMeta _acknowledgeByServerMeta =
      const VerificationMeta('acknowledgeByServer');
  @override
  late final GeneratedColumn<bool> acknowledgeByServer = GeneratedColumn<bool>(
      'acknowledge_by_server', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("acknowledge_by_server" IN (0, 1))'),
      defaultValue: Constant(false));
  static const VerificationMeta _errorWhileSendingMeta =
      const VerificationMeta('errorWhileSending');
  @override
  late final GeneratedColumn<bool> errorWhileSending = GeneratedColumn<bool>(
      'error_while_sending', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("error_while_sending" IN (0, 1))'),
      defaultValue: Constant(false));
  @override
  late final GeneratedColumnWithTypeConverter<MessageKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MessageKind>($MessagesTable.$converterkind);
  static const VerificationMeta _contentJsonMeta =
      const VerificationMeta('contentJson');
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _openedAtMeta =
      const VerificationMeta('openedAt');
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
      'opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sendAtMeta = const VerificationMeta('sendAt');
  @override
  late final GeneratedColumn<DateTime> sendAt = GeneratedColumn<DateTime>(
      'send_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
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
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('message_other_id')) {
      context.handle(
          _messageOtherIdMeta,
          messageOtherId.isAcceptableOrUnknown(
              data['message_other_id']!, _messageOtherIdMeta));
    }
    if (data.containsKey('media_upload_id')) {
      context.handle(
          _mediaUploadIdMeta,
          mediaUploadId.isAcceptableOrUnknown(
              data['media_upload_id']!, _mediaUploadIdMeta));
    }
    if (data.containsKey('media_download_id')) {
      context.handle(
          _mediaDownloadIdMeta,
          mediaDownloadId.isAcceptableOrUnknown(
              data['media_download_id']!, _mediaDownloadIdMeta));
    }
    if (data.containsKey('response_to_message_id')) {
      context.handle(
          _responseToMessageIdMeta,
          responseToMessageId.isAcceptableOrUnknown(
              data['response_to_message_id']!, _responseToMessageIdMeta));
    }
    if (data.containsKey('response_to_other_message_id')) {
      context.handle(
          _responseToOtherMessageIdMeta,
          responseToOtherMessageId.isAcceptableOrUnknown(
              data['response_to_other_message_id']!,
              _responseToOtherMessageIdMeta));
    }
    if (data.containsKey('acknowledge_by_user')) {
      context.handle(
          _acknowledgeByUserMeta,
          acknowledgeByUser.isAcceptableOrUnknown(
              data['acknowledge_by_user']!, _acknowledgeByUserMeta));
    }
    if (data.containsKey('media_stored')) {
      context.handle(
          _mediaStoredMeta,
          mediaStored.isAcceptableOrUnknown(
              data['media_stored']!, _mediaStoredMeta));
    }
    if (data.containsKey('acknowledge_by_server')) {
      context.handle(
          _acknowledgeByServerMeta,
          acknowledgeByServer.isAcceptableOrUnknown(
              data['acknowledge_by_server']!, _acknowledgeByServerMeta));
    }
    if (data.containsKey('error_while_sending')) {
      context.handle(
          _errorWhileSendingMeta,
          errorWhileSending.isAcceptableOrUnknown(
              data['error_while_sending']!, _errorWhileSendingMeta));
    }
    if (data.containsKey('content_json')) {
      context.handle(
          _contentJsonMeta,
          contentJson.isAcceptableOrUnknown(
              data['content_json']!, _contentJsonMeta));
    }
    if (data.containsKey('opened_at')) {
      context.handle(_openedAtMeta,
          openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta));
    }
    if (data.containsKey('send_at')) {
      context.handle(_sendAtMeta,
          sendAt.isAcceptableOrUnknown(data['send_at']!, _sendAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
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
      downloadState: $MessagesTable.$converterdownloadState.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}download_state'])!),
      acknowledgeByServer: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}acknowledge_by_server'])!,
      errorWhileSending: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}error_while_sending'])!,
      kind: $MessagesTable.$converterkind.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
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
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DownloadState, int, int> $converterdownloadState =
      const EnumIndexConverter<DownloadState>(DownloadState.values);
  static JsonTypeConverter2<MessageKind, String, String> $converterkind =
      const EnumNameConverter<MessageKind>(MessageKind.values);
}

class Message extends DataClass implements Insertable<Message> {
  final int contactId;
  final int messageId;
  final int? messageOtherId;
  final int? mediaUploadId;
  final int? mediaDownloadId;
  final int? responseToMessageId;
  final int? responseToOtherMessageId;
  final bool acknowledgeByUser;
  final bool mediaStored;
  final DownloadState downloadState;
  final bool acknowledgeByServer;
  final bool errorWhileSending;
  final MessageKind kind;
  final String? contentJson;
  final DateTime? openedAt;
  final DateTime sendAt;
  final DateTime updatedAt;
  const Message(
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
    {
      map['download_state'] = Variable<int>(
          $MessagesTable.$converterdownloadState.toSql(downloadState));
    }
    map['acknowledge_by_server'] = Variable<bool>(acknowledgeByServer);
    map['error_while_sending'] = Variable<bool>(errorWhileSending);
    {
      map['kind'] = Variable<String>($MessagesTable.$converterkind.toSql(kind));
    }
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

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
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
      downloadState: $MessagesTable.$converterdownloadState
          .fromJson(serializer.fromJson<int>(json['downloadState'])),
      acknowledgeByServer:
          serializer.fromJson<bool>(json['acknowledgeByServer']),
      errorWhileSending: serializer.fromJson<bool>(json['errorWhileSending']),
      kind: $MessagesTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
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
      'downloadState': serializer.toJson<int>(
          $MessagesTable.$converterdownloadState.toJson(downloadState)),
      'acknowledgeByServer': serializer.toJson<bool>(acknowledgeByServer),
      'errorWhileSending': serializer.toJson<bool>(errorWhileSending),
      'kind':
          serializer.toJson<String>($MessagesTable.$converterkind.toJson(kind)),
      'contentJson': serializer.toJson<String?>(contentJson),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'sendAt': serializer.toJson<DateTime>(sendAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Message copyWith(
          {int? contactId,
          int? messageId,
          Value<int?> messageOtherId = const Value.absent(),
          Value<int?> mediaUploadId = const Value.absent(),
          Value<int?> mediaDownloadId = const Value.absent(),
          Value<int?> responseToMessageId = const Value.absent(),
          Value<int?> responseToOtherMessageId = const Value.absent(),
          bool? acknowledgeByUser,
          bool? mediaStored,
          DownloadState? downloadState,
          bool? acknowledgeByServer,
          bool? errorWhileSending,
          MessageKind? kind,
          Value<String?> contentJson = const Value.absent(),
          Value<DateTime?> openedAt = const Value.absent(),
          DateTime? sendAt,
          DateTime? updatedAt}) =>
      Message(
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
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
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
    return (StringBuffer('Message(')
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
      (other is Message &&
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

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> contactId;
  final Value<int> messageId;
  final Value<int?> messageOtherId;
  final Value<int?> mediaUploadId;
  final Value<int?> mediaDownloadId;
  final Value<int?> responseToMessageId;
  final Value<int?> responseToOtherMessageId;
  final Value<bool> acknowledgeByUser;
  final Value<bool> mediaStored;
  final Value<DownloadState> downloadState;
  final Value<bool> acknowledgeByServer;
  final Value<bool> errorWhileSending;
  final Value<MessageKind> kind;
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
    required MessageKind kind,
    this.contentJson = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.sendAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : contactId = Value(contactId),
        kind = Value(kind);
  static Insertable<Message> custom({
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
      Value<DownloadState>? downloadState,
      Value<bool>? acknowledgeByServer,
      Value<bool>? errorWhileSending,
      Value<MessageKind>? kind,
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
      map['download_state'] = Variable<int>(
          $MessagesTable.$converterdownloadState.toSql(downloadState.value));
    }
    if (acknowledgeByServer.present) {
      map['acknowledge_by_server'] = Variable<bool>(acknowledgeByServer.value);
    }
    if (errorWhileSending.present) {
      map['error_while_sending'] = Variable<bool>(errorWhileSending.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($MessagesTable.$converterkind.toSql(kind.value));
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

class $MediaUploadsTable extends MediaUploads
    with TableInfo<$MediaUploadsTable, MediaUpload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaUploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaUploadIdMeta =
      const VerificationMeta('mediaUploadId');
  @override
  late final GeneratedColumn<int> mediaUploadId = GeneratedColumn<int>(
      'media_upload_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  @override
  late final GeneratedColumnWithTypeConverter<UploadState, String> state =
      GeneratedColumn<String>('state', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant(UploadState.pending.name))
          .withConverter<UploadState>($MediaUploadsTable.$converterstate);
  @override
  late final GeneratedColumnWithTypeConverter<MediaUploadMetadata?, String>
      metadata = GeneratedColumn<String>('metadata', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<MediaUploadMetadata?>(
              $MediaUploadsTable.$convertermetadatan);
  @override
  late final GeneratedColumnWithTypeConverter<List<int>?, String> messageIds =
      GeneratedColumn<String>('message_ids', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<int>?>($MediaUploadsTable.$convertermessageIdsn);
  @override
  late final GeneratedColumnWithTypeConverter<MediaEncryptionData?, String>
      encryptionData = GeneratedColumn<String>(
              'encryption_data', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<MediaEncryptionData?>(
              $MediaUploadsTable.$converterencryptionDatan);
  @override
  late final GeneratedColumnWithTypeConverter<MediaUploadTokens?, String>
      uploadTokens = GeneratedColumn<String>('upload_tokens', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<MediaUploadTokens?>(
              $MediaUploadsTable.$converteruploadTokensn);
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String>
      alreadyNotified = GeneratedColumn<String>(
              'already_notified', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant("[]"))
          .withConverter<List<int>>(
              $MediaUploadsTable.$converteralreadyNotified);
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
  VerificationContext validateIntegrity(Insertable<MediaUpload> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_upload_id')) {
      context.handle(
          _mediaUploadIdMeta,
          mediaUploadId.isAcceptableOrUnknown(
              data['media_upload_id']!, _mediaUploadIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaUploadId};
  @override
  MediaUpload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaUpload(
      mediaUploadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_upload_id'])!,
      state: $MediaUploadsTable.$converterstate.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!),
      metadata: $MediaUploadsTable.$convertermetadatan.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])),
      messageIds: $MediaUploadsTable.$convertermessageIdsn.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}message_ids'])),
      encryptionData: $MediaUploadsTable.$converterencryptionDatan.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}encryption_data'])),
      uploadTokens: $MediaUploadsTable.$converteruploadTokensn.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}upload_tokens'])),
      alreadyNotified: $MediaUploadsTable.$converteralreadyNotified.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}already_notified'])!),
    );
  }

  @override
  $MediaUploadsTable createAlias(String alias) {
    return $MediaUploadsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<UploadState, String, String> $converterstate =
      const EnumNameConverter<UploadState>(UploadState.values);
  static JsonTypeConverter2<MediaUploadMetadata, String, Map<String, Object?>>
      $convertermetadata = MediaUploadMetadataConverter();
  static JsonTypeConverter2<MediaUploadMetadata?, String?,
          Map<String, Object?>?> $convertermetadatan =
      JsonTypeConverter2.asNullable($convertermetadata);
  static TypeConverter<List<int>, String> $convertermessageIds =
      IntListTypeConverter();
  static TypeConverter<List<int>?, String?> $convertermessageIdsn =
      NullAwareTypeConverter.wrap($convertermessageIds);
  static JsonTypeConverter2<MediaEncryptionData, String, Map<String, Object?>>
      $converterencryptionData = MediaEncryptionDataConverter();
  static JsonTypeConverter2<MediaEncryptionData?, String?,
          Map<String, Object?>?> $converterencryptionDatan =
      JsonTypeConverter2.asNullable($converterencryptionData);
  static JsonTypeConverter2<MediaUploadTokens, String, Map<String, Object?>>
      $converteruploadTokens = MediaUploadTokensConverter();
  static JsonTypeConverter2<MediaUploadTokens?, String?, Map<String, Object?>?>
      $converteruploadTokensn =
      JsonTypeConverter2.asNullable($converteruploadTokens);
  static TypeConverter<List<int>, String> $converteralreadyNotified =
      IntListTypeConverter();
}

class MediaUpload extends DataClass implements Insertable<MediaUpload> {
  final int mediaUploadId;
  final UploadState state;
  final MediaUploadMetadata? metadata;

  /// exists in UploadState.addedToMessagesDb
  final List<int>? messageIds;

  /// exsists in UploadState.isEncrypted
  final MediaEncryptionData? encryptionData;

  /// exsists in UploadState.hasUploadToken
  final MediaUploadTokens? uploadTokens;

  /// exists in UploadState.addedToMessagesDb
  final List<int> alreadyNotified;
  const MediaUpload(
      {required this.mediaUploadId,
      required this.state,
      this.metadata,
      this.messageIds,
      this.encryptionData,
      this.uploadTokens,
      required this.alreadyNotified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_upload_id'] = Variable<int>(mediaUploadId);
    {
      map['state'] =
          Variable<String>($MediaUploadsTable.$converterstate.toSql(state));
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(
          $MediaUploadsTable.$convertermetadatan.toSql(metadata));
    }
    if (!nullToAbsent || messageIds != null) {
      map['message_ids'] = Variable<String>(
          $MediaUploadsTable.$convertermessageIdsn.toSql(messageIds));
    }
    if (!nullToAbsent || encryptionData != null) {
      map['encryption_data'] = Variable<String>(
          $MediaUploadsTable.$converterencryptionDatan.toSql(encryptionData));
    }
    if (!nullToAbsent || uploadTokens != null) {
      map['upload_tokens'] = Variable<String>(
          $MediaUploadsTable.$converteruploadTokensn.toSql(uploadTokens));
    }
    {
      map['already_notified'] = Variable<String>(
          $MediaUploadsTable.$converteralreadyNotified.toSql(alreadyNotified));
    }
    return map;
  }

  MediaUploadsCompanion toCompanion(bool nullToAbsent) {
    return MediaUploadsCompanion(
      mediaUploadId: Value(mediaUploadId),
      state: Value(state),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
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

  factory MediaUpload.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaUpload(
      mediaUploadId: serializer.fromJson<int>(json['mediaUploadId']),
      state: $MediaUploadsTable.$converterstate
          .fromJson(serializer.fromJson<String>(json['state'])),
      metadata: $MediaUploadsTable.$convertermetadatan.fromJson(
          serializer.fromJson<Map<String, Object?>?>(json['metadata'])),
      messageIds: serializer.fromJson<List<int>?>(json['messageIds']),
      encryptionData: $MediaUploadsTable.$converterencryptionDatan.fromJson(
          serializer.fromJson<Map<String, Object?>?>(json['encryptionData'])),
      uploadTokens: $MediaUploadsTable.$converteruploadTokensn.fromJson(
          serializer.fromJson<Map<String, Object?>?>(json['uploadTokens'])),
      alreadyNotified: serializer.fromJson<List<int>>(json['alreadyNotified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaUploadId': serializer.toJson<int>(mediaUploadId),
      'state': serializer
          .toJson<String>($MediaUploadsTable.$converterstate.toJson(state)),
      'metadata': serializer.toJson<Map<String, Object?>?>(
          $MediaUploadsTable.$convertermetadatan.toJson(metadata)),
      'messageIds': serializer.toJson<List<int>?>(messageIds),
      'encryptionData': serializer.toJson<Map<String, Object?>?>(
          $MediaUploadsTable.$converterencryptionDatan.toJson(encryptionData)),
      'uploadTokens': serializer.toJson<Map<String, Object?>?>(
          $MediaUploadsTable.$converteruploadTokensn.toJson(uploadTokens)),
      'alreadyNotified': serializer.toJson<List<int>>(alreadyNotified),
    };
  }

  MediaUpload copyWith(
          {int? mediaUploadId,
          UploadState? state,
          Value<MediaUploadMetadata?> metadata = const Value.absent(),
          Value<List<int>?> messageIds = const Value.absent(),
          Value<MediaEncryptionData?> encryptionData = const Value.absent(),
          Value<MediaUploadTokens?> uploadTokens = const Value.absent(),
          List<int>? alreadyNotified}) =>
      MediaUpload(
        mediaUploadId: mediaUploadId ?? this.mediaUploadId,
        state: state ?? this.state,
        metadata: metadata.present ? metadata.value : this.metadata,
        messageIds: messageIds.present ? messageIds.value : this.messageIds,
        encryptionData:
            encryptionData.present ? encryptionData.value : this.encryptionData,
        uploadTokens:
            uploadTokens.present ? uploadTokens.value : this.uploadTokens,
        alreadyNotified: alreadyNotified ?? this.alreadyNotified,
      );
  MediaUpload copyWithCompanion(MediaUploadsCompanion data) {
    return MediaUpload(
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
    return (StringBuffer('MediaUpload(')
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
      (other is MediaUpload &&
          other.mediaUploadId == this.mediaUploadId &&
          other.state == this.state &&
          other.metadata == this.metadata &&
          other.messageIds == this.messageIds &&
          other.encryptionData == this.encryptionData &&
          other.uploadTokens == this.uploadTokens &&
          other.alreadyNotified == this.alreadyNotified);
}

class MediaUploadsCompanion extends UpdateCompanion<MediaUpload> {
  final Value<int> mediaUploadId;
  final Value<UploadState> state;
  final Value<MediaUploadMetadata?> metadata;
  final Value<List<int>?> messageIds;
  final Value<MediaEncryptionData?> encryptionData;
  final Value<MediaUploadTokens?> uploadTokens;
  final Value<List<int>> alreadyNotified;
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
    this.metadata = const Value.absent(),
    this.messageIds = const Value.absent(),
    this.encryptionData = const Value.absent(),
    this.uploadTokens = const Value.absent(),
    this.alreadyNotified = const Value.absent(),
  });
  static Insertable<MediaUpload> custom({
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
      Value<UploadState>? state,
      Value<MediaUploadMetadata?>? metadata,
      Value<List<int>?>? messageIds,
      Value<MediaEncryptionData?>? encryptionData,
      Value<MediaUploadTokens?>? uploadTokens,
      Value<List<int>>? alreadyNotified}) {
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
      map['state'] = Variable<String>(
          $MediaUploadsTable.$converterstate.toSql(state.value));
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(
          $MediaUploadsTable.$convertermetadatan.toSql(metadata.value));
    }
    if (messageIds.present) {
      map['message_ids'] = Variable<String>(
          $MediaUploadsTable.$convertermessageIdsn.toSql(messageIds.value));
    }
    if (encryptionData.present) {
      map['encryption_data'] = Variable<String>($MediaUploadsTable
          .$converterencryptionDatan
          .toSql(encryptionData.value));
    }
    if (uploadTokens.present) {
      map['upload_tokens'] = Variable<String>(
          $MediaUploadsTable.$converteruploadTokensn.toSql(uploadTokens.value));
    }
    if (alreadyNotified.present) {
      map['already_notified'] = Variable<String>($MediaUploadsTable
          .$converteralreadyNotified
          .toSql(alreadyNotified.value));
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

class $MediaDownloadsTable extends MediaDownloads
    with TableInfo<$MediaDownloadsTable, MediaDownload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaDownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
      'message_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String> downloadToken =
      GeneratedColumn<String>('download_token', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<int>>(
              $MediaDownloadsTable.$converterdownloadToken);
  @override
  List<GeneratedColumn> get $columns => [messageId, downloadToken];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_downloads';
  @override
  VerificationContext validateIntegrity(Insertable<MediaDownload> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  MediaDownload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaDownload(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}message_id'])!,
      downloadToken: $MediaDownloadsTable.$converterdownloadToken.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}download_token'])!),
    );
  }

  @override
  $MediaDownloadsTable createAlias(String alias) {
    return $MediaDownloadsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int>, String> $converterdownloadToken =
      IntListTypeConverter();
}

class MediaDownload extends DataClass implements Insertable<MediaDownload> {
  final int messageId;
  final List<int> downloadToken;
  const MediaDownload({required this.messageId, required this.downloadToken});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<int>(messageId);
    {
      map['download_token'] = Variable<String>(
          $MediaDownloadsTable.$converterdownloadToken.toSql(downloadToken));
    }
    return map;
  }

  MediaDownloadsCompanion toCompanion(bool nullToAbsent) {
    return MediaDownloadsCompanion(
      messageId: Value(messageId),
      downloadToken: Value(downloadToken),
    );
  }

  factory MediaDownload.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaDownload(
      messageId: serializer.fromJson<int>(json['messageId']),
      downloadToken: serializer.fromJson<List<int>>(json['downloadToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<int>(messageId),
      'downloadToken': serializer.toJson<List<int>>(downloadToken),
    };
  }

  MediaDownload copyWith({int? messageId, List<int>? downloadToken}) =>
      MediaDownload(
        messageId: messageId ?? this.messageId,
        downloadToken: downloadToken ?? this.downloadToken,
      );
  MediaDownload copyWithCompanion(MediaDownloadsCompanion data) {
    return MediaDownload(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      downloadToken: data.downloadToken.present
          ? data.downloadToken.value
          : this.downloadToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaDownload(')
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
      (other is MediaDownload &&
          other.messageId == this.messageId &&
          other.downloadToken == this.downloadToken);
}

class MediaDownloadsCompanion extends UpdateCompanion<MediaDownload> {
  final Value<int> messageId;
  final Value<List<int>> downloadToken;
  final Value<int> rowid;
  const MediaDownloadsCompanion({
    this.messageId = const Value.absent(),
    this.downloadToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaDownloadsCompanion.insert({
    required int messageId,
    required List<int> downloadToken,
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        downloadToken = Value(downloadToken);
  static Insertable<MediaDownload> custom({
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
      Value<List<int>>? downloadToken,
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
      map['download_token'] = Variable<String>($MediaDownloadsTable
          .$converterdownloadToken
          .toSql(downloadToken.value));
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
      type: DriftSqlType.int, requiredDuringInsert: true);
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
      type: DriftSqlType.int, requiredDuringInsert: false);
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

abstract class _$TwonlyDatabase extends GeneratedDatabase {
  _$TwonlyDatabase(QueryExecutor e) : super(e);
  $TwonlyDatabaseManager get managers => $TwonlyDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MediaUploadsTable mediaUploads = $MediaUploadsTable(this);
  late final $MediaDownloadsTable mediaDownloads = $MediaDownloadsTable(this);
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
  late final MessagesDao messagesDao = MessagesDao(this as TwonlyDatabase);
  late final ContactsDao contactsDao = ContactsDao(this as TwonlyDatabase);
  late final MediaUploadsDao mediaUploadsDao =
      MediaUploadsDao(this as TwonlyDatabase);
  late final MediaDownloadsDao mediaDownloadsDao =
      MediaDownloadsDao(this as TwonlyDatabase);
  late final SignalDao signalDao = SignalDao(this as TwonlyDatabase);
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
        signalSessionStores,
        signalContactPreKeys,
        signalContactSignedPreKeys
      ];
}

typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  Value<int> userId,
  required String username,
  Value<String?> displayName,
  Value<String?> nickName,
  Value<String?> avatarSvg,
  Value<int> myAvatarCounter,
  Value<bool> accepted,
  Value<bool> requested,
  Value<bool> blocked,
  Value<bool> verified,
  Value<bool> archived,
  Value<bool> pinned,
  Value<bool> alsoBestFriend,
  Value<int> deleteMessagesAfterXMinutes,
  Value<DateTime> createdAt,
  Value<int> totalMediaCounter,
  Value<DateTime?> lastMessageSend,
  Value<DateTime?> lastMessageReceived,
  Value<DateTime?> lastFlameCounterChange,
  Value<DateTime?> lastFlameSync,
  Value<DateTime> lastMessageExchange,
  Value<int> flameCounter,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<int> userId,
  Value<String> username,
  Value<String?> displayName,
  Value<String?> nickName,
  Value<String?> avatarSvg,
  Value<int> myAvatarCounter,
  Value<bool> accepted,
  Value<bool> requested,
  Value<bool> blocked,
  Value<bool> verified,
  Value<bool> archived,
  Value<bool> pinned,
  Value<bool> alsoBestFriend,
  Value<int> deleteMessagesAfterXMinutes,
  Value<DateTime> createdAt,
  Value<int> totalMediaCounter,
  Value<DateTime?> lastMessageSend,
  Value<DateTime?> lastMessageReceived,
  Value<DateTime?> lastFlameCounterChange,
  Value<DateTime?> lastFlameSync,
  Value<DateTime> lastMessageExchange,
  Value<int> flameCounter,
});

final class $$ContactsTableReferences
    extends BaseReferences<_$TwonlyDatabase, $ContactsTable, Contact> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
          _$TwonlyDatabase db) =>
      MultiTypedResultKey.fromTable(db.messages,
          aliasName:
              $_aliasNameGenerator(db.contacts.userId, db.messages.contactId));

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages).filter(
        (f) => f.contactId.userId.sqlEquals($_itemColumn<int>('user_id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$TwonlyDatabase, $ContactsTable> {
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

  ColumnFilters<String> get avatarSvg => $composableBuilder(
      column: $table.avatarSvg, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get myAvatarCounter => $composableBuilder(
      column: $table.myAvatarCounter,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get accepted => $composableBuilder(
      column: $table.accepted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requested => $composableBuilder(
      column: $table.requested, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get blocked => $composableBuilder(
      column: $table.blocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get verified => $composableBuilder(
      column: $table.verified, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get alsoBestFriend => $composableBuilder(
      column: $table.alsoBestFriend,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deleteMessagesAfterXMinutes => $composableBuilder(
      column: $table.deleteMessagesAfterXMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalMediaCounter => $composableBuilder(
      column: $table.totalMediaCounter,
      builder: (column) => ColumnFilters(column));

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

  ColumnFilters<DateTime> get lastMessageExchange => $composableBuilder(
      column: $table.lastMessageExchange,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get flameCounter => $composableBuilder(
      column: $table.flameCounter, builder: (column) => ColumnFilters(column));

  Expression<bool> messagesRefs(
      Expression<bool> Function($$MessagesTableFilterComposer f) f) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.contactId,
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

class $$ContactsTableOrderingComposer
    extends Composer<_$TwonlyDatabase, $ContactsTable> {
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

  ColumnOrderings<String> get avatarSvg => $composableBuilder(
      column: $table.avatarSvg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get myAvatarCounter => $composableBuilder(
      column: $table.myAvatarCounter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get accepted => $composableBuilder(
      column: $table.accepted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requested => $composableBuilder(
      column: $table.requested, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get blocked => $composableBuilder(
      column: $table.blocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get verified => $composableBuilder(
      column: $table.verified, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get alsoBestFriend => $composableBuilder(
      column: $table.alsoBestFriend,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deleteMessagesAfterXMinutes => $composableBuilder(
      column: $table.deleteMessagesAfterXMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalMediaCounter => $composableBuilder(
      column: $table.totalMediaCounter,
      builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<DateTime> get lastMessageExchange => $composableBuilder(
      column: $table.lastMessageExchange,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get flameCounter => $composableBuilder(
      column: $table.flameCounter,
      builder: (column) => ColumnOrderings(column));
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$TwonlyDatabase, $ContactsTable> {
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

  GeneratedColumn<String> get avatarSvg =>
      $composableBuilder(column: $table.avatarSvg, builder: (column) => column);

  GeneratedColumn<int> get myAvatarCounter => $composableBuilder(
      column: $table.myAvatarCounter, builder: (column) => column);

  GeneratedColumn<bool> get accepted =>
      $composableBuilder(column: $table.accepted, builder: (column) => column);

  GeneratedColumn<bool> get requested =>
      $composableBuilder(column: $table.requested, builder: (column) => column);

  GeneratedColumn<bool> get blocked =>
      $composableBuilder(column: $table.blocked, builder: (column) => column);

  GeneratedColumn<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get alsoBestFriend => $composableBuilder(
      column: $table.alsoBestFriend, builder: (column) => column);

  GeneratedColumn<int> get deleteMessagesAfterXMinutes => $composableBuilder(
      column: $table.deleteMessagesAfterXMinutes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get totalMediaCounter => $composableBuilder(
      column: $table.totalMediaCounter, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageSend => $composableBuilder(
      column: $table.lastMessageSend, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageReceived => $composableBuilder(
      column: $table.lastMessageReceived, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFlameCounterChange => $composableBuilder(
      column: $table.lastFlameCounterChange, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFlameSync => $composableBuilder(
      column: $table.lastFlameSync, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageExchange => $composableBuilder(
      column: $table.lastMessageExchange, builder: (column) => column);

  GeneratedColumn<int> get flameCounter => $composableBuilder(
      column: $table.flameCounter, builder: (column) => column);

  Expression<T> messagesRefs<T extends Object>(
      Expression<T> Function($$MessagesTableAnnotationComposer a) f) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.contactId,
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

class $$ContactsTableTableManager extends RootTableManager<
    _$TwonlyDatabase,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableAnnotationComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder,
    (Contact, $$ContactsTableReferences),
    Contact,
    PrefetchHooks Function({bool messagesRefs})> {
  $$ContactsTableTableManager(_$TwonlyDatabase db, $ContactsTable table)
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
            Value<String?> avatarSvg = const Value.absent(),
            Value<int> myAvatarCounter = const Value.absent(),
            Value<bool> accepted = const Value.absent(),
            Value<bool> requested = const Value.absent(),
            Value<bool> blocked = const Value.absent(),
            Value<bool> verified = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> alsoBestFriend = const Value.absent(),
            Value<int> deleteMessagesAfterXMinutes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> totalMediaCounter = const Value.absent(),
            Value<DateTime?> lastMessageSend = const Value.absent(),
            Value<DateTime?> lastMessageReceived = const Value.absent(),
            Value<DateTime?> lastFlameCounterChange = const Value.absent(),
            Value<DateTime?> lastFlameSync = const Value.absent(),
            Value<DateTime> lastMessageExchange = const Value.absent(),
            Value<int> flameCounter = const Value.absent(),
          }) =>
              ContactsCompanion(
            userId: userId,
            username: username,
            displayName: displayName,
            nickName: nickName,
            avatarSvg: avatarSvg,
            myAvatarCounter: myAvatarCounter,
            accepted: accepted,
            requested: requested,
            blocked: blocked,
            verified: verified,
            archived: archived,
            pinned: pinned,
            alsoBestFriend: alsoBestFriend,
            deleteMessagesAfterXMinutes: deleteMessagesAfterXMinutes,
            createdAt: createdAt,
            totalMediaCounter: totalMediaCounter,
            lastMessageSend: lastMessageSend,
            lastMessageReceived: lastMessageReceived,
            lastFlameCounterChange: lastFlameCounterChange,
            lastFlameSync: lastFlameSync,
            lastMessageExchange: lastMessageExchange,
            flameCounter: flameCounter,
          ),
          createCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            required String username,
            Value<String?> displayName = const Value.absent(),
            Value<String?> nickName = const Value.absent(),
            Value<String?> avatarSvg = const Value.absent(),
            Value<int> myAvatarCounter = const Value.absent(),
            Value<bool> accepted = const Value.absent(),
            Value<bool> requested = const Value.absent(),
            Value<bool> blocked = const Value.absent(),
            Value<bool> verified = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<bool> alsoBestFriend = const Value.absent(),
            Value<int> deleteMessagesAfterXMinutes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> totalMediaCounter = const Value.absent(),
            Value<DateTime?> lastMessageSend = const Value.absent(),
            Value<DateTime?> lastMessageReceived = const Value.absent(),
            Value<DateTime?> lastFlameCounterChange = const Value.absent(),
            Value<DateTime?> lastFlameSync = const Value.absent(),
            Value<DateTime> lastMessageExchange = const Value.absent(),
            Value<int> flameCounter = const Value.absent(),
          }) =>
              ContactsCompanion.insert(
            userId: userId,
            username: username,
            displayName: displayName,
            nickName: nickName,
            avatarSvg: avatarSvg,
            myAvatarCounter: myAvatarCounter,
            accepted: accepted,
            requested: requested,
            blocked: blocked,
            verified: verified,
            archived: archived,
            pinned: pinned,
            alsoBestFriend: alsoBestFriend,
            deleteMessagesAfterXMinutes: deleteMessagesAfterXMinutes,
            createdAt: createdAt,
            totalMediaCounter: totalMediaCounter,
            lastMessageSend: lastMessageSend,
            lastMessageReceived: lastMessageReceived,
            lastFlameCounterChange: lastFlameCounterChange,
            lastFlameSync: lastFlameSync,
            lastMessageExchange: lastMessageExchange,
            flameCounter: flameCounter,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ContactsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
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
                                .where((e) => e.contactId == item.userId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ContactsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDatabase,
    $ContactsTable,
    Contact,
    $$ContactsTableFilterComposer,
    $$ContactsTableOrderingComposer,
    $$ContactsTableAnnotationComposer,
    $$ContactsTableCreateCompanionBuilder,
    $$ContactsTableUpdateCompanionBuilder,
    (Contact, $$ContactsTableReferences),
    Contact,
    PrefetchHooks Function({bool messagesRefs})>;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required int contactId,
  Value<int> messageId,
  Value<int?> messageOtherId,
  Value<int?> mediaUploadId,
  Value<int?> mediaDownloadId,
  Value<int?> responseToMessageId,
  Value<int?> responseToOtherMessageId,
  Value<bool> acknowledgeByUser,
  Value<bool> mediaStored,
  Value<DownloadState> downloadState,
  Value<bool> acknowledgeByServer,
  Value<bool> errorWhileSending,
  required MessageKind kind,
  Value<String?> contentJson,
  Value<DateTime?> openedAt,
  Value<DateTime> sendAt,
  Value<DateTime> updatedAt,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<int> contactId,
  Value<int> messageId,
  Value<int?> messageOtherId,
  Value<int?> mediaUploadId,
  Value<int?> mediaDownloadId,
  Value<int?> responseToMessageId,
  Value<int?> responseToOtherMessageId,
  Value<bool> acknowledgeByUser,
  Value<bool> mediaStored,
  Value<DownloadState> downloadState,
  Value<bool> acknowledgeByServer,
  Value<bool> errorWhileSending,
  Value<MessageKind> kind,
  Value<String?> contentJson,
  Value<DateTime?> openedAt,
  Value<DateTime> sendAt,
  Value<DateTime> updatedAt,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$TwonlyDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ContactsTable _contactIdTable(_$TwonlyDatabase db) =>
      db.contacts.createAlias(
          $_aliasNameGenerator(db.messages.contactId, db.contacts.userId));

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

class $$MessagesTableFilterComposer
    extends Composer<_$TwonlyDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get messageOtherId => $composableBuilder(
      column: $table.messageOtherId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mediaUploadId => $composableBuilder(
      column: $table.mediaUploadId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mediaDownloadId => $composableBuilder(
      column: $table.mediaDownloadId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get responseToMessageId => $composableBuilder(
      column: $table.responseToMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get responseToOtherMessageId => $composableBuilder(
      column: $table.responseToOtherMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get acknowledgeByUser => $composableBuilder(
      column: $table.acknowledgeByUser,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get mediaStored => $composableBuilder(
      column: $table.mediaStored, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DownloadState, DownloadState, int>
      get downloadState => $composableBuilder(
          column: $table.downloadState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get acknowledgeByServer => $composableBuilder(
      column: $table.acknowledgeByServer,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get errorWhileSending => $composableBuilder(
      column: $table.errorWhileSending,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MessageKind, MessageKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sendAt => $composableBuilder(
      column: $table.sendAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

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

class $$MessagesTableOrderingComposer
    extends Composer<_$TwonlyDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get messageOtherId => $composableBuilder(
      column: $table.messageOtherId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mediaUploadId => $composableBuilder(
      column: $table.mediaUploadId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mediaDownloadId => $composableBuilder(
      column: $table.mediaDownloadId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get responseToMessageId => $composableBuilder(
      column: $table.responseToMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get responseToOtherMessageId => $composableBuilder(
      column: $table.responseToOtherMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get acknowledgeByUser => $composableBuilder(
      column: $table.acknowledgeByUser,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get mediaStored => $composableBuilder(
      column: $table.mediaStored, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadState => $composableBuilder(
      column: $table.downloadState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get acknowledgeByServer => $composableBuilder(
      column: $table.acknowledgeByServer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get errorWhileSending => $composableBuilder(
      column: $table.errorWhileSending,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
      column: $table.openedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sendAt => $composableBuilder(
      column: $table.sendAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

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

class $$MessagesTableAnnotationComposer
    extends Composer<_$TwonlyDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get messageOtherId => $composableBuilder(
      column: $table.messageOtherId, builder: (column) => column);

  GeneratedColumn<int> get mediaUploadId => $composableBuilder(
      column: $table.mediaUploadId, builder: (column) => column);

  GeneratedColumn<int> get mediaDownloadId => $composableBuilder(
      column: $table.mediaDownloadId, builder: (column) => column);

  GeneratedColumn<int> get responseToMessageId => $composableBuilder(
      column: $table.responseToMessageId, builder: (column) => column);

  GeneratedColumn<int> get responseToOtherMessageId => $composableBuilder(
      column: $table.responseToOtherMessageId, builder: (column) => column);

  GeneratedColumn<bool> get acknowledgeByUser => $composableBuilder(
      column: $table.acknowledgeByUser, builder: (column) => column);

  GeneratedColumn<bool> get mediaStored => $composableBuilder(
      column: $table.mediaStored, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadState, int> get downloadState =>
      $composableBuilder(
          column: $table.downloadState, builder: (column) => column);

  GeneratedColumn<bool> get acknowledgeByServer => $composableBuilder(
      column: $table.acknowledgeByServer, builder: (column) => column);

  GeneratedColumn<bool> get errorWhileSending => $composableBuilder(
      column: $table.errorWhileSending, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get sendAt =>
      $composableBuilder(column: $table.sendAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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

class $$MessagesTableTableManager extends RootTableManager<
    _$TwonlyDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, $$MessagesTableReferences),
    Message,
    PrefetchHooks Function({bool contactId})> {
  $$MessagesTableTableManager(_$TwonlyDatabase db, $MessagesTable table)
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
            Value<int> contactId = const Value.absent(),
            Value<int> messageId = const Value.absent(),
            Value<int?> messageOtherId = const Value.absent(),
            Value<int?> mediaUploadId = const Value.absent(),
            Value<int?> mediaDownloadId = const Value.absent(),
            Value<int?> responseToMessageId = const Value.absent(),
            Value<int?> responseToOtherMessageId = const Value.absent(),
            Value<bool> acknowledgeByUser = const Value.absent(),
            Value<bool> mediaStored = const Value.absent(),
            Value<DownloadState> downloadState = const Value.absent(),
            Value<bool> acknowledgeByServer = const Value.absent(),
            Value<bool> errorWhileSending = const Value.absent(),
            Value<MessageKind> kind = const Value.absent(),
            Value<String?> contentJson = const Value.absent(),
            Value<DateTime?> openedAt = const Value.absent(),
            Value<DateTime> sendAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MessagesCompanion(
            contactId: contactId,
            messageId: messageId,
            messageOtherId: messageOtherId,
            mediaUploadId: mediaUploadId,
            mediaDownloadId: mediaDownloadId,
            responseToMessageId: responseToMessageId,
            responseToOtherMessageId: responseToOtherMessageId,
            acknowledgeByUser: acknowledgeByUser,
            mediaStored: mediaStored,
            downloadState: downloadState,
            acknowledgeByServer: acknowledgeByServer,
            errorWhileSending: errorWhileSending,
            kind: kind,
            contentJson: contentJson,
            openedAt: openedAt,
            sendAt: sendAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            required int contactId,
            Value<int> messageId = const Value.absent(),
            Value<int?> messageOtherId = const Value.absent(),
            Value<int?> mediaUploadId = const Value.absent(),
            Value<int?> mediaDownloadId = const Value.absent(),
            Value<int?> responseToMessageId = const Value.absent(),
            Value<int?> responseToOtherMessageId = const Value.absent(),
            Value<bool> acknowledgeByUser = const Value.absent(),
            Value<bool> mediaStored = const Value.absent(),
            Value<DownloadState> downloadState = const Value.absent(),
            Value<bool> acknowledgeByServer = const Value.absent(),
            Value<bool> errorWhileSending = const Value.absent(),
            required MessageKind kind,
            Value<String?> contentJson = const Value.absent(),
            Value<DateTime?> openedAt = const Value.absent(),
            Value<DateTime> sendAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            contactId: contactId,
            messageId: messageId,
            messageOtherId: messageOtherId,
            mediaUploadId: mediaUploadId,
            mediaDownloadId: mediaDownloadId,
            responseToMessageId: responseToMessageId,
            responseToOtherMessageId: responseToOtherMessageId,
            acknowledgeByUser: acknowledgeByUser,
            mediaStored: mediaStored,
            downloadState: downloadState,
            acknowledgeByServer: acknowledgeByServer,
            errorWhileSending: errorWhileSending,
            kind: kind,
            contentJson: contentJson,
            openedAt: openedAt,
            sendAt: sendAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MessagesTableReferences(db, table, e)))
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
                    referencedTable:
                        $$MessagesTableReferences._contactIdTable(db),
                    referencedColumn:
                        $$MessagesTableReferences._contactIdTable(db).userId,
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

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, $$MessagesTableReferences),
    Message,
    PrefetchHooks Function({bool contactId})>;
typedef $$MediaUploadsTableCreateCompanionBuilder = MediaUploadsCompanion
    Function({
  Value<int> mediaUploadId,
  Value<UploadState> state,
  Value<MediaUploadMetadata?> metadata,
  Value<List<int>?> messageIds,
  Value<MediaEncryptionData?> encryptionData,
  Value<MediaUploadTokens?> uploadTokens,
  Value<List<int>> alreadyNotified,
});
typedef $$MediaUploadsTableUpdateCompanionBuilder = MediaUploadsCompanion
    Function({
  Value<int> mediaUploadId,
  Value<UploadState> state,
  Value<MediaUploadMetadata?> metadata,
  Value<List<int>?> messageIds,
  Value<MediaEncryptionData?> encryptionData,
  Value<MediaUploadTokens?> uploadTokens,
  Value<List<int>> alreadyNotified,
});

class $$MediaUploadsTableFilterComposer
    extends Composer<_$TwonlyDatabase, $MediaUploadsTable> {
  $$MediaUploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get mediaUploadId => $composableBuilder(
      column: $table.mediaUploadId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<UploadState, UploadState, String> get state =>
      $composableBuilder(
          column: $table.state,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<MediaUploadMetadata?, MediaUploadMetadata,
          String>
      get metadata => $composableBuilder(
          column: $table.metadata,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<int>?, List<int>, String>
      get messageIds => $composableBuilder(
          column: $table.messageIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<MediaEncryptionData?, MediaEncryptionData,
          String>
      get encryptionData => $composableBuilder(
          column: $table.encryptionData,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<MediaUploadTokens?, MediaUploadTokens, String>
      get uploadTokens => $composableBuilder(
          column: $table.uploadTokens,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
      get alreadyNotified => $composableBuilder(
          column: $table.alreadyNotified,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$MediaUploadsTableOrderingComposer
    extends Composer<_$TwonlyDatabase, $MediaUploadsTable> {
  $$MediaUploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get mediaUploadId => $composableBuilder(
      column: $table.mediaUploadId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageIds => $composableBuilder(
      column: $table.messageIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get encryptionData => $composableBuilder(
      column: $table.encryptionData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uploadTokens => $composableBuilder(
      column: $table.uploadTokens,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alreadyNotified => $composableBuilder(
      column: $table.alreadyNotified,
      builder: (column) => ColumnOrderings(column));
}

class $$MediaUploadsTableAnnotationComposer
    extends Composer<_$TwonlyDatabase, $MediaUploadsTable> {
  $$MediaUploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get mediaUploadId => $composableBuilder(
      column: $table.mediaUploadId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UploadState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaUploadMetadata?, String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<int>?, String> get messageIds =>
      $composableBuilder(
          column: $table.messageIds, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaEncryptionData?, String>
      get encryptionData => $composableBuilder(
          column: $table.encryptionData, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaUploadTokens?, String>
      get uploadTokens => $composableBuilder(
          column: $table.uploadTokens, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<int>, String> get alreadyNotified =>
      $composableBuilder(
          column: $table.alreadyNotified, builder: (column) => column);
}

class $$MediaUploadsTableTableManager extends RootTableManager<
    _$TwonlyDatabase,
    $MediaUploadsTable,
    MediaUpload,
    $$MediaUploadsTableFilterComposer,
    $$MediaUploadsTableOrderingComposer,
    $$MediaUploadsTableAnnotationComposer,
    $$MediaUploadsTableCreateCompanionBuilder,
    $$MediaUploadsTableUpdateCompanionBuilder,
    (
      MediaUpload,
      BaseReferences<_$TwonlyDatabase, $MediaUploadsTable, MediaUpload>
    ),
    MediaUpload,
    PrefetchHooks Function()> {
  $$MediaUploadsTableTableManager(_$TwonlyDatabase db, $MediaUploadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaUploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaUploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> mediaUploadId = const Value.absent(),
            Value<UploadState> state = const Value.absent(),
            Value<MediaUploadMetadata?> metadata = const Value.absent(),
            Value<List<int>?> messageIds = const Value.absent(),
            Value<MediaEncryptionData?> encryptionData = const Value.absent(),
            Value<MediaUploadTokens?> uploadTokens = const Value.absent(),
            Value<List<int>> alreadyNotified = const Value.absent(),
          }) =>
              MediaUploadsCompanion(
            mediaUploadId: mediaUploadId,
            state: state,
            metadata: metadata,
            messageIds: messageIds,
            encryptionData: encryptionData,
            uploadTokens: uploadTokens,
            alreadyNotified: alreadyNotified,
          ),
          createCompanionCallback: ({
            Value<int> mediaUploadId = const Value.absent(),
            Value<UploadState> state = const Value.absent(),
            Value<MediaUploadMetadata?> metadata = const Value.absent(),
            Value<List<int>?> messageIds = const Value.absent(),
            Value<MediaEncryptionData?> encryptionData = const Value.absent(),
            Value<MediaUploadTokens?> uploadTokens = const Value.absent(),
            Value<List<int>> alreadyNotified = const Value.absent(),
          }) =>
              MediaUploadsCompanion.insert(
            mediaUploadId: mediaUploadId,
            state: state,
            metadata: metadata,
            messageIds: messageIds,
            encryptionData: encryptionData,
            uploadTokens: uploadTokens,
            alreadyNotified: alreadyNotified,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaUploadsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDatabase,
    $MediaUploadsTable,
    MediaUpload,
    $$MediaUploadsTableFilterComposer,
    $$MediaUploadsTableOrderingComposer,
    $$MediaUploadsTableAnnotationComposer,
    $$MediaUploadsTableCreateCompanionBuilder,
    $$MediaUploadsTableUpdateCompanionBuilder,
    (
      MediaUpload,
      BaseReferences<_$TwonlyDatabase, $MediaUploadsTable, MediaUpload>
    ),
    MediaUpload,
    PrefetchHooks Function()>;
typedef $$MediaDownloadsTableCreateCompanionBuilder = MediaDownloadsCompanion
    Function({
  required int messageId,
  required List<int> downloadToken,
  Value<int> rowid,
});
typedef $$MediaDownloadsTableUpdateCompanionBuilder = MediaDownloadsCompanion
    Function({
  Value<int> messageId,
  Value<List<int>> downloadToken,
  Value<int> rowid,
});

class $$MediaDownloadsTableFilterComposer
    extends Composer<_$TwonlyDatabase, $MediaDownloadsTable> {
  $$MediaDownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
      get downloadToken => $composableBuilder(
          column: $table.downloadToken,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$MediaDownloadsTableOrderingComposer
    extends Composer<_$TwonlyDatabase, $MediaDownloadsTable> {
  $$MediaDownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get downloadToken => $composableBuilder(
      column: $table.downloadToken,
      builder: (column) => ColumnOrderings(column));
}

class $$MediaDownloadsTableAnnotationComposer
    extends Composer<_$TwonlyDatabase, $MediaDownloadsTable> {
  $$MediaDownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<int>, String> get downloadToken =>
      $composableBuilder(
          column: $table.downloadToken, builder: (column) => column);
}

class $$MediaDownloadsTableTableManager extends RootTableManager<
    _$TwonlyDatabase,
    $MediaDownloadsTable,
    MediaDownload,
    $$MediaDownloadsTableFilterComposer,
    $$MediaDownloadsTableOrderingComposer,
    $$MediaDownloadsTableAnnotationComposer,
    $$MediaDownloadsTableCreateCompanionBuilder,
    $$MediaDownloadsTableUpdateCompanionBuilder,
    (
      MediaDownload,
      BaseReferences<_$TwonlyDatabase, $MediaDownloadsTable, MediaDownload>
    ),
    MediaDownload,
    PrefetchHooks Function()> {
  $$MediaDownloadsTableTableManager(
      _$TwonlyDatabase db, $MediaDownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaDownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaDownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaDownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> messageId = const Value.absent(),
            Value<List<int>> downloadToken = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaDownloadsCompanion(
            messageId: messageId,
            downloadToken: downloadToken,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int messageId,
            required List<int> downloadToken,
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaDownloadsCompanion.insert(
            messageId: messageId,
            downloadToken: downloadToken,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaDownloadsTableProcessedTableManager = ProcessedTableManager<
    _$TwonlyDatabase,
    $MediaDownloadsTable,
    MediaDownload,
    $$MediaDownloadsTableFilterComposer,
    $$MediaDownloadsTableOrderingComposer,
    $$MediaDownloadsTableAnnotationComposer,
    $$MediaDownloadsTableCreateCompanionBuilder,
    $$MediaDownloadsTableUpdateCompanionBuilder,
    (
      MediaDownload,
      BaseReferences<_$TwonlyDatabase, $MediaDownloadsTable, MediaDownload>
    ),
    MediaDownload,
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
    extends Composer<_$TwonlyDatabase, $SignalIdentityKeyStoresTable> {
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
    extends Composer<_$TwonlyDatabase, $SignalIdentityKeyStoresTable> {
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
    extends Composer<_$TwonlyDatabase, $SignalIdentityKeyStoresTable> {
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
    _$TwonlyDatabase,
    $SignalIdentityKeyStoresTable,
    SignalIdentityKeyStore,
    $$SignalIdentityKeyStoresTableFilterComposer,
    $$SignalIdentityKeyStoresTableOrderingComposer,
    $$SignalIdentityKeyStoresTableAnnotationComposer,
    $$SignalIdentityKeyStoresTableCreateCompanionBuilder,
    $$SignalIdentityKeyStoresTableUpdateCompanionBuilder,
    (
      SignalIdentityKeyStore,
      BaseReferences<_$TwonlyDatabase, $SignalIdentityKeyStoresTable,
          SignalIdentityKeyStore>
    ),
    SignalIdentityKeyStore,
    PrefetchHooks Function()> {
  $$SignalIdentityKeyStoresTableTableManager(
      _$TwonlyDatabase db, $SignalIdentityKeyStoresTable table)
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
        _$TwonlyDatabase,
        $SignalIdentityKeyStoresTable,
        SignalIdentityKeyStore,
        $$SignalIdentityKeyStoresTableFilterComposer,
        $$SignalIdentityKeyStoresTableOrderingComposer,
        $$SignalIdentityKeyStoresTableAnnotationComposer,
        $$SignalIdentityKeyStoresTableCreateCompanionBuilder,
        $$SignalIdentityKeyStoresTableUpdateCompanionBuilder,
        (
          SignalIdentityKeyStore,
          BaseReferences<_$TwonlyDatabase, $SignalIdentityKeyStoresTable,
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
    extends Composer<_$TwonlyDatabase, $SignalPreKeyStoresTable> {
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
    extends Composer<_$TwonlyDatabase, $SignalPreKeyStoresTable> {
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
    extends Composer<_$TwonlyDatabase, $SignalPreKeyStoresTable> {
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
    _$TwonlyDatabase,
    $SignalPreKeyStoresTable,
    SignalPreKeyStore,
    $$SignalPreKeyStoresTableFilterComposer,
    $$SignalPreKeyStoresTableOrderingComposer,
    $$SignalPreKeyStoresTableAnnotationComposer,
    $$SignalPreKeyStoresTableCreateCompanionBuilder,
    $$SignalPreKeyStoresTableUpdateCompanionBuilder,
    (
      SignalPreKeyStore,
      BaseReferences<_$TwonlyDatabase, $SignalPreKeyStoresTable,
          SignalPreKeyStore>
    ),
    SignalPreKeyStore,
    PrefetchHooks Function()> {
  $$SignalPreKeyStoresTableTableManager(
      _$TwonlyDatabase db, $SignalPreKeyStoresTable table)
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
    _$TwonlyDatabase,
    $SignalPreKeyStoresTable,
    SignalPreKeyStore,
    $$SignalPreKeyStoresTableFilterComposer,
    $$SignalPreKeyStoresTableOrderingComposer,
    $$SignalPreKeyStoresTableAnnotationComposer,
    $$SignalPreKeyStoresTableCreateCompanionBuilder,
    $$SignalPreKeyStoresTableUpdateCompanionBuilder,
    (
      SignalPreKeyStore,
      BaseReferences<_$TwonlyDatabase, $SignalPreKeyStoresTable,
          SignalPreKeyStore>
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
    extends Composer<_$TwonlyDatabase, $SignalSenderKeyStoresTable> {
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
    extends Composer<_$TwonlyDatabase, $SignalSenderKeyStoresTable> {
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
    extends Composer<_$TwonlyDatabase, $SignalSenderKeyStoresTable> {
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
    _$TwonlyDatabase,
    $SignalSenderKeyStoresTable,
    SignalSenderKeyStore,
    $$SignalSenderKeyStoresTableFilterComposer,
    $$SignalSenderKeyStoresTableOrderingComposer,
    $$SignalSenderKeyStoresTableAnnotationComposer,
    $$SignalSenderKeyStoresTableCreateCompanionBuilder,
    $$SignalSenderKeyStoresTableUpdateCompanionBuilder,
    (
      SignalSenderKeyStore,
      BaseReferences<_$TwonlyDatabase, $SignalSenderKeyStoresTable,
          SignalSenderKeyStore>
    ),
    SignalSenderKeyStore,
    PrefetchHooks Function()> {
  $$SignalSenderKeyStoresTableTableManager(
      _$TwonlyDatabase db, $SignalSenderKeyStoresTable table)
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
        _$TwonlyDatabase,
        $SignalSenderKeyStoresTable,
        SignalSenderKeyStore,
        $$SignalSenderKeyStoresTableFilterComposer,
        $$SignalSenderKeyStoresTableOrderingComposer,
        $$SignalSenderKeyStoresTableAnnotationComposer,
        $$SignalSenderKeyStoresTableCreateCompanionBuilder,
        $$SignalSenderKeyStoresTableUpdateCompanionBuilder,
        (
          SignalSenderKeyStore,
          BaseReferences<_$TwonlyDatabase, $SignalSenderKeyStoresTable,
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
    extends Composer<_$TwonlyDatabase, $SignalSessionStoresTable> {
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
    extends Composer<_$TwonlyDatabase, $SignalSessionStoresTable> {
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
    extends Composer<_$TwonlyDatabase, $SignalSessionStoresTable> {
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
    _$TwonlyDatabase,
    $SignalSessionStoresTable,
    SignalSessionStore,
    $$SignalSessionStoresTableFilterComposer,
    $$SignalSessionStoresTableOrderingComposer,
    $$SignalSessionStoresTableAnnotationComposer,
    $$SignalSessionStoresTableCreateCompanionBuilder,
    $$SignalSessionStoresTableUpdateCompanionBuilder,
    (
      SignalSessionStore,
      BaseReferences<_$TwonlyDatabase, $SignalSessionStoresTable,
          SignalSessionStore>
    ),
    SignalSessionStore,
    PrefetchHooks Function()> {
  $$SignalSessionStoresTableTableManager(
      _$TwonlyDatabase db, $SignalSessionStoresTable table)
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
    _$TwonlyDatabase,
    $SignalSessionStoresTable,
    SignalSessionStore,
    $$SignalSessionStoresTableFilterComposer,
    $$SignalSessionStoresTableOrderingComposer,
    $$SignalSessionStoresTableAnnotationComposer,
    $$SignalSessionStoresTableCreateCompanionBuilder,
    $$SignalSessionStoresTableUpdateCompanionBuilder,
    (
      SignalSessionStore,
      BaseReferences<_$TwonlyDatabase, $SignalSessionStoresTable,
          SignalSessionStore>
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

class $$SignalContactPreKeysTableFilterComposer
    extends Composer<_$TwonlyDatabase, $SignalContactPreKeysTable> {
  $$SignalContactPreKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get contactId => $composableBuilder(
      column: $table.contactId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get preKeyId => $composableBuilder(
      column: $table.preKeyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get preKey => $composableBuilder(
      column: $table.preKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SignalContactPreKeysTableOrderingComposer
    extends Composer<_$TwonlyDatabase, $SignalContactPreKeysTable> {
  $$SignalContactPreKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get contactId => $composableBuilder(
      column: $table.contactId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get preKeyId => $composableBuilder(
      column: $table.preKeyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get preKey => $composableBuilder(
      column: $table.preKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SignalContactPreKeysTableAnnotationComposer
    extends Composer<_$TwonlyDatabase, $SignalContactPreKeysTable> {
  $$SignalContactPreKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<int> get preKeyId =>
      $composableBuilder(column: $table.preKeyId, builder: (column) => column);

  GeneratedColumn<Uint8List> get preKey =>
      $composableBuilder(column: $table.preKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignalContactPreKeysTableTableManager extends RootTableManager<
    _$TwonlyDatabase,
    $SignalContactPreKeysTable,
    SignalContactPreKey,
    $$SignalContactPreKeysTableFilterComposer,
    $$SignalContactPreKeysTableOrderingComposer,
    $$SignalContactPreKeysTableAnnotationComposer,
    $$SignalContactPreKeysTableCreateCompanionBuilder,
    $$SignalContactPreKeysTableUpdateCompanionBuilder,
    (
      SignalContactPreKey,
      BaseReferences<_$TwonlyDatabase, $SignalContactPreKeysTable,
          SignalContactPreKey>
    ),
    SignalContactPreKey,
    PrefetchHooks Function()> {
  $$SignalContactPreKeysTableTableManager(
      _$TwonlyDatabase db, $SignalContactPreKeysTable table)
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SignalContactPreKeysTableProcessedTableManager
    = ProcessedTableManager<
        _$TwonlyDatabase,
        $SignalContactPreKeysTable,
        SignalContactPreKey,
        $$SignalContactPreKeysTableFilterComposer,
        $$SignalContactPreKeysTableOrderingComposer,
        $$SignalContactPreKeysTableAnnotationComposer,
        $$SignalContactPreKeysTableCreateCompanionBuilder,
        $$SignalContactPreKeysTableUpdateCompanionBuilder,
        (
          SignalContactPreKey,
          BaseReferences<_$TwonlyDatabase, $SignalContactPreKeysTable,
              SignalContactPreKey>
        ),
        SignalContactPreKey,
        PrefetchHooks Function()>;
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

class $$SignalContactSignedPreKeysTableFilterComposer
    extends Composer<_$TwonlyDatabase, $SignalContactSignedPreKeysTable> {
  $$SignalContactSignedPreKeysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get contactId => $composableBuilder(
      column: $table.contactId, builder: (column) => ColumnFilters(column));

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
}

class $$SignalContactSignedPreKeysTableOrderingComposer
    extends Composer<_$TwonlyDatabase, $SignalContactSignedPreKeysTable> {
  $$SignalContactSignedPreKeysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get contactId => $composableBuilder(
      column: $table.contactId, builder: (column) => ColumnOrderings(column));

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
}

class $$SignalContactSignedPreKeysTableAnnotationComposer
    extends Composer<_$TwonlyDatabase, $SignalContactSignedPreKeysTable> {
  $$SignalContactSignedPreKeysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<int> get signedPreKeyId => $composableBuilder(
      column: $table.signedPreKeyId, builder: (column) => column);

  GeneratedColumn<Uint8List> get signedPreKey => $composableBuilder(
      column: $table.signedPreKey, builder: (column) => column);

  GeneratedColumn<Uint8List> get signedPreKeySignature => $composableBuilder(
      column: $table.signedPreKeySignature, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SignalContactSignedPreKeysTableTableManager extends RootTableManager<
    _$TwonlyDatabase,
    $SignalContactSignedPreKeysTable,
    SignalContactSignedPreKey,
    $$SignalContactSignedPreKeysTableFilterComposer,
    $$SignalContactSignedPreKeysTableOrderingComposer,
    $$SignalContactSignedPreKeysTableAnnotationComposer,
    $$SignalContactSignedPreKeysTableCreateCompanionBuilder,
    $$SignalContactSignedPreKeysTableUpdateCompanionBuilder,
    (
      SignalContactSignedPreKey,
      BaseReferences<_$TwonlyDatabase, $SignalContactSignedPreKeysTable,
          SignalContactSignedPreKey>
    ),
    SignalContactSignedPreKey,
    PrefetchHooks Function()> {
  $$SignalContactSignedPreKeysTableTableManager(
      _$TwonlyDatabase db, $SignalContactSignedPreKeysTable table)
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SignalContactSignedPreKeysTableProcessedTableManager
    = ProcessedTableManager<
        _$TwonlyDatabase,
        $SignalContactSignedPreKeysTable,
        SignalContactSignedPreKey,
        $$SignalContactSignedPreKeysTableFilterComposer,
        $$SignalContactSignedPreKeysTableOrderingComposer,
        $$SignalContactSignedPreKeysTableAnnotationComposer,
        $$SignalContactSignedPreKeysTableCreateCompanionBuilder,
        $$SignalContactSignedPreKeysTableUpdateCompanionBuilder,
        (
          SignalContactSignedPreKey,
          BaseReferences<_$TwonlyDatabase, $SignalContactSignedPreKeysTable,
              SignalContactSignedPreKey>
        ),
        SignalContactSignedPreKey,
        PrefetchHooks Function()>;

class $TwonlyDatabaseManager {
  final _$TwonlyDatabase _db;
  $TwonlyDatabaseManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MediaUploadsTableTableManager get mediaUploads =>
      $$MediaUploadsTableTableManager(_db, _db.mediaUploads);
  $$MediaDownloadsTableTableManager get mediaDownloads =>
      $$MediaDownloadsTableTableManager(_db, _db.mediaDownloads);
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
}
