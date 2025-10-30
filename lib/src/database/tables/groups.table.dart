import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

@DataClassName('Group')
class Groups extends Table {
  TextColumn get groupId => text()();

  BoolColumn get isGroupAdmin => boolean()();
  BoolColumn get isDirectChat => boolean()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  TextColumn get groupName => text()();

  IntColumn get totalMediaCounter => integer().withDefault(const Constant(0))();

  BoolColumn get alsoBestFriend =>
      boolean().withDefault(const Constant(false))();

  IntColumn get deleteMessagesAfterMilliseconds =>
      integer().withDefault(const Constant(1000 * 60 * 60 * 24))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get lastMessageSend => dateTime().nullable()();
  DateTimeColumn get lastMessageReceived => dateTime().nullable()();
  DateTimeColumn get lastFlameCounterChange => dateTime().nullable()();
  DateTimeColumn get lastFlameSync => dateTime().nullable()();

  IntColumn get flameCounter => integer().withDefault(const Constant(0))();

  IntColumn get maxFlameCounter => integer().withDefault(const Constant(0))();
  DateTimeColumn get maxFlameCounterFrom => dateTime().nullable()();

  DateTimeColumn get lastMessageExchange =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {groupId};
}

enum MemberState { invited, accepted, admin }

@DataClassName('GroupMember')
class GroupMembers extends Table {
  TextColumn get groupId => text()();

  IntColumn get contactId => integer().references(Contacts, #userId)();
  TextColumn get memberState => textEnum<MemberState>().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {groupId, contactId};
}
