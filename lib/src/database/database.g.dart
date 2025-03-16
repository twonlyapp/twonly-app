// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

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
  static const VerificationMeta _lastMessageMeta =
      const VerificationMeta('lastMessage');
  @override
  late final GeneratedColumn<DateTime> lastMessage = GeneratedColumn<DateTime>(
      'last_message', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
        accepted,
        requested,
        blocked,
        verified,
        createdAt,
        totalMediaCounter,
        lastMessageSend,
        lastMessageReceived,
        lastMessage,
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
    if (data.containsKey('last_message')) {
      context.handle(
          _lastMessageMeta,
          lastMessage.isAcceptableOrUnknown(
              data['last_message']!, _lastMessageMeta));
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
      accepted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}accepted'])!,
      requested: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}requested'])!,
      blocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}blocked'])!,
      verified: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}verified'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      totalMediaCounter: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_media_counter'])!,
      lastMessageSend: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_message_send']),
      lastMessageReceived: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_message_received']),
      lastMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_message']),
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
  final bool accepted;
  final bool requested;
  final bool blocked;
  final bool verified;
  final DateTime createdAt;
  final int totalMediaCounter;
  final DateTime? lastMessageSend;
  final DateTime? lastMessageReceived;
  final DateTime? lastMessage;
  final int flameCounter;
  const Contact(
      {required this.userId,
      required this.username,
      this.displayName,
      this.nickName,
      required this.accepted,
      required this.requested,
      required this.blocked,
      required this.verified,
      required this.createdAt,
      required this.totalMediaCounter,
      this.lastMessageSend,
      this.lastMessageReceived,
      this.lastMessage,
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
    map['accepted'] = Variable<bool>(accepted);
    map['requested'] = Variable<bool>(requested);
    map['blocked'] = Variable<bool>(blocked);
    map['verified'] = Variable<bool>(verified);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['total_media_counter'] = Variable<int>(totalMediaCounter);
    if (!nullToAbsent || lastMessageSend != null) {
      map['last_message_send'] = Variable<DateTime>(lastMessageSend);
    }
    if (!nullToAbsent || lastMessageReceived != null) {
      map['last_message_received'] = Variable<DateTime>(lastMessageReceived);
    }
    if (!nullToAbsent || lastMessage != null) {
      map['last_message'] = Variable<DateTime>(lastMessage);
    }
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
      accepted: Value(accepted),
      requested: Value(requested),
      blocked: Value(blocked),
      verified: Value(verified),
      createdAt: Value(createdAt),
      totalMediaCounter: Value(totalMediaCounter),
      lastMessageSend: lastMessageSend == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSend),
      lastMessageReceived: lastMessageReceived == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageReceived),
      lastMessage: lastMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessage),
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
      accepted: serializer.fromJson<bool>(json['accepted']),
      requested: serializer.fromJson<bool>(json['requested']),
      blocked: serializer.fromJson<bool>(json['blocked']),
      verified: serializer.fromJson<bool>(json['verified']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      totalMediaCounter: serializer.fromJson<int>(json['totalMediaCounter']),
      lastMessageSend: serializer.fromJson<DateTime?>(json['lastMessageSend']),
      lastMessageReceived:
          serializer.fromJson<DateTime?>(json['lastMessageReceived']),
      lastMessage: serializer.fromJson<DateTime?>(json['lastMessage']),
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
      'accepted': serializer.toJson<bool>(accepted),
      'requested': serializer.toJson<bool>(requested),
      'blocked': serializer.toJson<bool>(blocked),
      'verified': serializer.toJson<bool>(verified),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'totalMediaCounter': serializer.toJson<int>(totalMediaCounter),
      'lastMessageSend': serializer.toJson<DateTime?>(lastMessageSend),
      'lastMessageReceived': serializer.toJson<DateTime?>(lastMessageReceived),
      'lastMessage': serializer.toJson<DateTime?>(lastMessage),
      'flameCounter': serializer.toJson<int>(flameCounter),
    };
  }

  Contact copyWith(
          {int? userId,
          String? username,
          Value<String?> displayName = const Value.absent(),
          Value<String?> nickName = const Value.absent(),
          bool? accepted,
          bool? requested,
          bool? blocked,
          bool? verified,
          DateTime? createdAt,
          int? totalMediaCounter,
          Value<DateTime?> lastMessageSend = const Value.absent(),
          Value<DateTime?> lastMessageReceived = const Value.absent(),
          Value<DateTime?> lastMessage = const Value.absent(),
          int? flameCounter}) =>
      Contact(
        userId: userId ?? this.userId,
        username: username ?? this.username,
        displayName: displayName.present ? displayName.value : this.displayName,
        nickName: nickName.present ? nickName.value : this.nickName,
        accepted: accepted ?? this.accepted,
        requested: requested ?? this.requested,
        blocked: blocked ?? this.blocked,
        verified: verified ?? this.verified,
        createdAt: createdAt ?? this.createdAt,
        totalMediaCounter: totalMediaCounter ?? this.totalMediaCounter,
        lastMessageSend: lastMessageSend.present
            ? lastMessageSend.value
            : this.lastMessageSend,
        lastMessageReceived: lastMessageReceived.present
            ? lastMessageReceived.value
            : this.lastMessageReceived,
        lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
        flameCounter: flameCounter ?? this.flameCounter,
      );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      nickName: data.nickName.present ? data.nickName.value : this.nickName,
      accepted: data.accepted.present ? data.accepted.value : this.accepted,
      requested: data.requested.present ? data.requested.value : this.requested,
      blocked: data.blocked.present ? data.blocked.value : this.blocked,
      verified: data.verified.present ? data.verified.value : this.verified,
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
      lastMessage:
          data.lastMessage.present ? data.lastMessage.value : this.lastMessage,
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
          ..write('accepted: $accepted, ')
          ..write('requested: $requested, ')
          ..write('blocked: $blocked, ')
          ..write('verified: $verified, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalMediaCounter: $totalMediaCounter, ')
          ..write('lastMessageSend: $lastMessageSend, ')
          ..write('lastMessageReceived: $lastMessageReceived, ')
          ..write('lastMessage: $lastMessage, ')
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
      accepted,
      requested,
      blocked,
      verified,
      createdAt,
      totalMediaCounter,
      lastMessageSend,
      lastMessageReceived,
      lastMessage,
      flameCounter);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.nickName == this.nickName &&
          other.accepted == this.accepted &&
          other.requested == this.requested &&
          other.blocked == this.blocked &&
          other.verified == this.verified &&
          other.createdAt == this.createdAt &&
          other.totalMediaCounter == this.totalMediaCounter &&
          other.lastMessageSend == this.lastMessageSend &&
          other.lastMessageReceived == this.lastMessageReceived &&
          other.lastMessage == this.lastMessage &&
          other.flameCounter == this.flameCounter);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<int> userId;
  final Value<String> username;
  final Value<String?> displayName;
  final Value<String?> nickName;
  final Value<bool> accepted;
  final Value<bool> requested;
  final Value<bool> blocked;
  final Value<bool> verified;
  final Value<DateTime> createdAt;
  final Value<int> totalMediaCounter;
  final Value<DateTime?> lastMessageSend;
  final Value<DateTime?> lastMessageReceived;
  final Value<DateTime?> lastMessage;
  final Value<int> flameCounter;
  const ContactsCompanion({
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.nickName = const Value.absent(),
    this.accepted = const Value.absent(),
    this.requested = const Value.absent(),
    this.blocked = const Value.absent(),
    this.verified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.totalMediaCounter = const Value.absent(),
    this.lastMessageSend = const Value.absent(),
    this.lastMessageReceived = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.flameCounter = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.userId = const Value.absent(),
    required String username,
    this.displayName = const Value.absent(),
    this.nickName = const Value.absent(),
    this.accepted = const Value.absent(),
    this.requested = const Value.absent(),
    this.blocked = const Value.absent(),
    this.verified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.totalMediaCounter = const Value.absent(),
    this.lastMessageSend = const Value.absent(),
    this.lastMessageReceived = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.flameCounter = const Value.absent(),
  }) : username = Value(username);
  static Insertable<Contact> custom({
    Expression<int>? userId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? nickName,
    Expression<bool>? accepted,
    Expression<bool>? requested,
    Expression<bool>? blocked,
    Expression<bool>? verified,
    Expression<DateTime>? createdAt,
    Expression<int>? totalMediaCounter,
    Expression<DateTime>? lastMessageSend,
    Expression<DateTime>? lastMessageReceived,
    Expression<DateTime>? lastMessage,
    Expression<int>? flameCounter,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (nickName != null) 'nick_name': nickName,
      if (accepted != null) 'accepted': accepted,
      if (requested != null) 'requested': requested,
      if (blocked != null) 'blocked': blocked,
      if (verified != null) 'verified': verified,
      if (createdAt != null) 'created_at': createdAt,
      if (totalMediaCounter != null) 'total_media_counter': totalMediaCounter,
      if (lastMessageSend != null) 'last_message_send': lastMessageSend,
      if (lastMessageReceived != null)
        'last_message_received': lastMessageReceived,
      if (lastMessage != null) 'last_message': lastMessage,
      if (flameCounter != null) 'flame_counter': flameCounter,
    });
  }

  ContactsCompanion copyWith(
      {Value<int>? userId,
      Value<String>? username,
      Value<String?>? displayName,
      Value<String?>? nickName,
      Value<bool>? accepted,
      Value<bool>? requested,
      Value<bool>? blocked,
      Value<bool>? verified,
      Value<DateTime>? createdAt,
      Value<int>? totalMediaCounter,
      Value<DateTime?>? lastMessageSend,
      Value<DateTime?>? lastMessageReceived,
      Value<DateTime?>? lastMessage,
      Value<int>? flameCounter}) {
    return ContactsCompanion(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      nickName: nickName ?? this.nickName,
      accepted: accepted ?? this.accepted,
      requested: requested ?? this.requested,
      blocked: blocked ?? this.blocked,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      totalMediaCounter: totalMediaCounter ?? this.totalMediaCounter,
      lastMessageSend: lastMessageSend ?? this.lastMessageSend,
      lastMessageReceived: lastMessageReceived ?? this.lastMessageReceived,
      lastMessage: lastMessage ?? this.lastMessage,
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
    if (lastMessage.present) {
      map['last_message'] = Variable<DateTime>(lastMessage.value);
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
          ..write('accepted: $accepted, ')
          ..write('requested: $requested, ')
          ..write('blocked: $blocked, ')
          ..write('verified: $verified, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalMediaCounter: $totalMediaCounter, ')
          ..write('lastMessageSend: $lastMessageSend, ')
          ..write('lastMessageReceived: $lastMessageReceived, ')
          ..write('lastMessage: $lastMessage, ')
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
  static const VerificationMeta _downloadStateMeta =
      const VerificationMeta('downloadState');
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
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
        responseToMessageId,
        responseToOtherMessageId,
        acknowledgeByUser,
        downloadState,
        acknowledgeByServer,
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
    context.handle(_downloadStateMeta, const VerificationResult.success());
    if (data.containsKey('acknowledge_by_server')) {
      context.handle(
          _acknowledgeByServerMeta,
          acknowledgeByServer.isAcceptableOrUnknown(
              data['acknowledge_by_server']!, _acknowledgeByServerMeta));
    }
    context.handle(_kindMeta, const VerificationResult.success());
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
      responseToMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}response_to_message_id']),
      responseToOtherMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}response_to_other_message_id']),
      acknowledgeByUser: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}acknowledge_by_user'])!,
      downloadState: $MessagesTable.$converterdownloadState.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}download_state'])!),
      acknowledgeByServer: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}acknowledge_by_server'])!,
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
  final int? responseToMessageId;
  final int? responseToOtherMessageId;
  final bool acknowledgeByUser;
  final DownloadState downloadState;
  final bool acknowledgeByServer;
  final MessageKind kind;
  final String? contentJson;
  final DateTime? openedAt;
  final DateTime sendAt;
  final DateTime updatedAt;
  const Message(
      {required this.contactId,
      required this.messageId,
      this.messageOtherId,
      this.responseToMessageId,
      this.responseToOtherMessageId,
      required this.acknowledgeByUser,
      required this.downloadState,
      required this.acknowledgeByServer,
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
    if (!nullToAbsent || responseToMessageId != null) {
      map['response_to_message_id'] = Variable<int>(responseToMessageId);
    }
    if (!nullToAbsent || responseToOtherMessageId != null) {
      map['response_to_other_message_id'] =
          Variable<int>(responseToOtherMessageId);
    }
    map['acknowledge_by_user'] = Variable<bool>(acknowledgeByUser);
    {
      map['download_state'] = Variable<int>(
          $MessagesTable.$converterdownloadState.toSql(downloadState));
    }
    map['acknowledge_by_server'] = Variable<bool>(acknowledgeByServer);
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
      responseToMessageId: responseToMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(responseToMessageId),
      responseToOtherMessageId: responseToOtherMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(responseToOtherMessageId),
      acknowledgeByUser: Value(acknowledgeByUser),
      downloadState: Value(downloadState),
      acknowledgeByServer: Value(acknowledgeByServer),
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
      responseToMessageId:
          serializer.fromJson<int?>(json['responseToMessageId']),
      responseToOtherMessageId:
          serializer.fromJson<int?>(json['responseToOtherMessageId']),
      acknowledgeByUser: serializer.fromJson<bool>(json['acknowledgeByUser']),
      downloadState: $MessagesTable.$converterdownloadState
          .fromJson(serializer.fromJson<int>(json['downloadState'])),
      acknowledgeByServer:
          serializer.fromJson<bool>(json['acknowledgeByServer']),
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
      'responseToMessageId': serializer.toJson<int?>(responseToMessageId),
      'responseToOtherMessageId':
          serializer.toJson<int?>(responseToOtherMessageId),
      'acknowledgeByUser': serializer.toJson<bool>(acknowledgeByUser),
      'downloadState': serializer.toJson<int>(
          $MessagesTable.$converterdownloadState.toJson(downloadState)),
      'acknowledgeByServer': serializer.toJson<bool>(acknowledgeByServer),
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
          Value<int?> responseToMessageId = const Value.absent(),
          Value<int?> responseToOtherMessageId = const Value.absent(),
          bool? acknowledgeByUser,
          DownloadState? downloadState,
          bool? acknowledgeByServer,
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
        responseToMessageId: responseToMessageId.present
            ? responseToMessageId.value
            : this.responseToMessageId,
        responseToOtherMessageId: responseToOtherMessageId.present
            ? responseToOtherMessageId.value
            : this.responseToOtherMessageId,
        acknowledgeByUser: acknowledgeByUser ?? this.acknowledgeByUser,
        downloadState: downloadState ?? this.downloadState,
        acknowledgeByServer: acknowledgeByServer ?? this.acknowledgeByServer,
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
      responseToMessageId: data.responseToMessageId.present
          ? data.responseToMessageId.value
          : this.responseToMessageId,
      responseToOtherMessageId: data.responseToOtherMessageId.present
          ? data.responseToOtherMessageId.value
          : this.responseToOtherMessageId,
      acknowledgeByUser: data.acknowledgeByUser.present
          ? data.acknowledgeByUser.value
          : this.acknowledgeByUser,
      downloadState: data.downloadState.present
          ? data.downloadState.value
          : this.downloadState,
      acknowledgeByServer: data.acknowledgeByServer.present
          ? data.acknowledgeByServer.value
          : this.acknowledgeByServer,
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
          ..write('responseToMessageId: $responseToMessageId, ')
          ..write('responseToOtherMessageId: $responseToOtherMessageId, ')
          ..write('acknowledgeByUser: $acknowledgeByUser, ')
          ..write('downloadState: $downloadState, ')
          ..write('acknowledgeByServer: $acknowledgeByServer, ')
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
      responseToMessageId,
      responseToOtherMessageId,
      acknowledgeByUser,
      downloadState,
      acknowledgeByServer,
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
          other.responseToMessageId == this.responseToMessageId &&
          other.responseToOtherMessageId == this.responseToOtherMessageId &&
          other.acknowledgeByUser == this.acknowledgeByUser &&
          other.downloadState == this.downloadState &&
          other.acknowledgeByServer == this.acknowledgeByServer &&
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
  final Value<int?> responseToMessageId;
  final Value<int?> responseToOtherMessageId;
  final Value<bool> acknowledgeByUser;
  final Value<DownloadState> downloadState;
  final Value<bool> acknowledgeByServer;
  final Value<MessageKind> kind;
  final Value<String?> contentJson;
  final Value<DateTime?> openedAt;
  final Value<DateTime> sendAt;
  final Value<DateTime> updatedAt;
  const MessagesCompanion({
    this.contactId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.messageOtherId = const Value.absent(),
    this.responseToMessageId = const Value.absent(),
    this.responseToOtherMessageId = const Value.absent(),
    this.acknowledgeByUser = const Value.absent(),
    this.downloadState = const Value.absent(),
    this.acknowledgeByServer = const Value.absent(),
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
    this.responseToMessageId = const Value.absent(),
    this.responseToOtherMessageId = const Value.absent(),
    this.acknowledgeByUser = const Value.absent(),
    this.downloadState = const Value.absent(),
    this.acknowledgeByServer = const Value.absent(),
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
    Expression<int>? responseToMessageId,
    Expression<int>? responseToOtherMessageId,
    Expression<bool>? acknowledgeByUser,
    Expression<int>? downloadState,
    Expression<bool>? acknowledgeByServer,
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
      if (responseToMessageId != null)
        'response_to_message_id': responseToMessageId,
      if (responseToOtherMessageId != null)
        'response_to_other_message_id': responseToOtherMessageId,
      if (acknowledgeByUser != null) 'acknowledge_by_user': acknowledgeByUser,
      if (downloadState != null) 'download_state': downloadState,
      if (acknowledgeByServer != null)
        'acknowledge_by_server': acknowledgeByServer,
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
      Value<int?>? responseToMessageId,
      Value<int?>? responseToOtherMessageId,
      Value<bool>? acknowledgeByUser,
      Value<DownloadState>? downloadState,
      Value<bool>? acknowledgeByServer,
      Value<MessageKind>? kind,
      Value<String?>? contentJson,
      Value<DateTime?>? openedAt,
      Value<DateTime>? sendAt,
      Value<DateTime>? updatedAt}) {
    return MessagesCompanion(
      contactId: contactId ?? this.contactId,
      messageId: messageId ?? this.messageId,
      messageOtherId: messageOtherId ?? this.messageOtherId,
      responseToMessageId: responseToMessageId ?? this.responseToMessageId,
      responseToOtherMessageId:
          responseToOtherMessageId ?? this.responseToOtherMessageId,
      acknowledgeByUser: acknowledgeByUser ?? this.acknowledgeByUser,
      downloadState: downloadState ?? this.downloadState,
      acknowledgeByServer: acknowledgeByServer ?? this.acknowledgeByServer,
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
    if (downloadState.present) {
      map['download_state'] = Variable<int>(
          $MessagesTable.$converterdownloadState.toSql(downloadState.value));
    }
    if (acknowledgeByServer.present) {
      map['acknowledge_by_server'] = Variable<bool>(acknowledgeByServer.value);
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
          ..write('responseToMessageId: $responseToMessageId, ')
          ..write('responseToOtherMessageId: $responseToOtherMessageId, ')
          ..write('acknowledgeByUser: $acknowledgeByUser, ')
          ..write('downloadState: $downloadState, ')
          ..write('acknowledgeByServer: $acknowledgeByServer, ')
          ..write('kind: $kind, ')
          ..write('contentJson: $contentJson, ')
          ..write('openedAt: $openedAt, ')
          ..write('sendAt: $sendAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$TwonlyDatabase extends GeneratedDatabase {
  _$TwonlyDatabase(QueryExecutor e) : super(e);
  $TwonlyDatabaseManager get managers => $TwonlyDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [contacts, messages];
}

typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  Value<int> userId,
  required String username,
  Value<String?> displayName,
  Value<String?> nickName,
  Value<bool> accepted,
  Value<bool> requested,
  Value<bool> blocked,
  Value<bool> verified,
  Value<DateTime> createdAt,
  Value<int> totalMediaCounter,
  Value<DateTime?> lastMessageSend,
  Value<DateTime?> lastMessageReceived,
  Value<DateTime?> lastMessage,
  Value<int> flameCounter,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<int> userId,
  Value<String> username,
  Value<String?> displayName,
  Value<String?> nickName,
  Value<bool> accepted,
  Value<bool> requested,
  Value<bool> blocked,
  Value<bool> verified,
  Value<DateTime> createdAt,
  Value<int> totalMediaCounter,
  Value<DateTime?> lastMessageSend,
  Value<DateTime?> lastMessageReceived,
  Value<DateTime?> lastMessage,
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

  ColumnFilters<bool> get accepted => $composableBuilder(
      column: $table.accepted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get requested => $composableBuilder(
      column: $table.requested, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get blocked => $composableBuilder(
      column: $table.blocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get verified => $composableBuilder(
      column: $table.verified, builder: (column) => ColumnFilters(column));

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

  ColumnFilters<DateTime> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<bool> get accepted => $composableBuilder(
      column: $table.accepted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get requested => $composableBuilder(
      column: $table.requested, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get blocked => $composableBuilder(
      column: $table.blocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get verified => $composableBuilder(
      column: $table.verified, builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<DateTime> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<bool> get accepted =>
      $composableBuilder(column: $table.accepted, builder: (column) => column);

  GeneratedColumn<bool> get requested =>
      $composableBuilder(column: $table.requested, builder: (column) => column);

  GeneratedColumn<bool> get blocked =>
      $composableBuilder(column: $table.blocked, builder: (column) => column);

  GeneratedColumn<bool> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get totalMediaCounter => $composableBuilder(
      column: $table.totalMediaCounter, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageSend => $composableBuilder(
      column: $table.lastMessageSend, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessageReceived => $composableBuilder(
      column: $table.lastMessageReceived, builder: (column) => column);

  GeneratedColumn<DateTime> get lastMessage => $composableBuilder(
      column: $table.lastMessage, builder: (column) => column);

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
            Value<bool> accepted = const Value.absent(),
            Value<bool> requested = const Value.absent(),
            Value<bool> blocked = const Value.absent(),
            Value<bool> verified = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> totalMediaCounter = const Value.absent(),
            Value<DateTime?> lastMessageSend = const Value.absent(),
            Value<DateTime?> lastMessageReceived = const Value.absent(),
            Value<DateTime?> lastMessage = const Value.absent(),
            Value<int> flameCounter = const Value.absent(),
          }) =>
              ContactsCompanion(
            userId: userId,
            username: username,
            displayName: displayName,
            nickName: nickName,
            accepted: accepted,
            requested: requested,
            blocked: blocked,
            verified: verified,
            createdAt: createdAt,
            totalMediaCounter: totalMediaCounter,
            lastMessageSend: lastMessageSend,
            lastMessageReceived: lastMessageReceived,
            lastMessage: lastMessage,
            flameCounter: flameCounter,
          ),
          createCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            required String username,
            Value<String?> displayName = const Value.absent(),
            Value<String?> nickName = const Value.absent(),
            Value<bool> accepted = const Value.absent(),
            Value<bool> requested = const Value.absent(),
            Value<bool> blocked = const Value.absent(),
            Value<bool> verified = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> totalMediaCounter = const Value.absent(),
            Value<DateTime?> lastMessageSend = const Value.absent(),
            Value<DateTime?> lastMessageReceived = const Value.absent(),
            Value<DateTime?> lastMessage = const Value.absent(),
            Value<int> flameCounter = const Value.absent(),
          }) =>
              ContactsCompanion.insert(
            userId: userId,
            username: username,
            displayName: displayName,
            nickName: nickName,
            accepted: accepted,
            requested: requested,
            blocked: blocked,
            verified: verified,
            createdAt: createdAt,
            totalMediaCounter: totalMediaCounter,
            lastMessageSend: lastMessageSend,
            lastMessageReceived: lastMessageReceived,
            lastMessage: lastMessage,
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
  Value<int?> responseToMessageId,
  Value<int?> responseToOtherMessageId,
  Value<bool> acknowledgeByUser,
  Value<DownloadState> downloadState,
  Value<bool> acknowledgeByServer,
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
  Value<int?> responseToMessageId,
  Value<int?> responseToOtherMessageId,
  Value<bool> acknowledgeByUser,
  Value<DownloadState> downloadState,
  Value<bool> acknowledgeByServer,
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

  ColumnFilters<int> get responseToMessageId => $composableBuilder(
      column: $table.responseToMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get responseToOtherMessageId => $composableBuilder(
      column: $table.responseToOtherMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get acknowledgeByUser => $composableBuilder(
      column: $table.acknowledgeByUser,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DownloadState, DownloadState, int>
      get downloadState => $composableBuilder(
          column: $table.downloadState,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get acknowledgeByServer => $composableBuilder(
      column: $table.acknowledgeByServer,
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

  ColumnOrderings<int> get responseToMessageId => $composableBuilder(
      column: $table.responseToMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get responseToOtherMessageId => $composableBuilder(
      column: $table.responseToOtherMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get acknowledgeByUser => $composableBuilder(
      column: $table.acknowledgeByUser,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadState => $composableBuilder(
      column: $table.downloadState,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get acknowledgeByServer => $composableBuilder(
      column: $table.acknowledgeByServer,
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

  GeneratedColumn<int> get responseToMessageId => $composableBuilder(
      column: $table.responseToMessageId, builder: (column) => column);

  GeneratedColumn<int> get responseToOtherMessageId => $composableBuilder(
      column: $table.responseToOtherMessageId, builder: (column) => column);

  GeneratedColumn<bool> get acknowledgeByUser => $composableBuilder(
      column: $table.acknowledgeByUser, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadState, int> get downloadState =>
      $composableBuilder(
          column: $table.downloadState, builder: (column) => column);

  GeneratedColumn<bool> get acknowledgeByServer => $composableBuilder(
      column: $table.acknowledgeByServer, builder: (column) => column);

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
            Value<int?> responseToMessageId = const Value.absent(),
            Value<int?> responseToOtherMessageId = const Value.absent(),
            Value<bool> acknowledgeByUser = const Value.absent(),
            Value<DownloadState> downloadState = const Value.absent(),
            Value<bool> acknowledgeByServer = const Value.absent(),
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
            responseToMessageId: responseToMessageId,
            responseToOtherMessageId: responseToOtherMessageId,
            acknowledgeByUser: acknowledgeByUser,
            downloadState: downloadState,
            acknowledgeByServer: acknowledgeByServer,
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
            Value<int?> responseToMessageId = const Value.absent(),
            Value<int?> responseToOtherMessageId = const Value.absent(),
            Value<bool> acknowledgeByUser = const Value.absent(),
            Value<DownloadState> downloadState = const Value.absent(),
            Value<bool> acknowledgeByServer = const Value.absent(),
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
            responseToMessageId: responseToMessageId,
            responseToOtherMessageId: responseToOtherMessageId,
            acknowledgeByUser: acknowledgeByUser,
            downloadState: downloadState,
            acknowledgeByServer: acknowledgeByServer,
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

class $TwonlyDatabaseManager {
  final _$TwonlyDatabase _db;
  $TwonlyDatabaseManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
}
