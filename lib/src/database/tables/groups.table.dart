import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

const int defaultDeleteMessagesAfterMilliseconds = 1000 * 60 * 60 * 24;

@DataClassName('Group')
class Groups extends Table {
  TextColumn get groupId => text()();

  BoolColumn get isGroupAdmin => boolean().withDefault(const Constant(false))();
  BoolColumn get isDirectChat => boolean().withDefault(const Constant(false))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  BoolColumn get joinedGroup => boolean().withDefault(const Constant(false))();
  BoolColumn get leftGroup => boolean().withDefault(const Constant(false))();

  IntColumn get stateVersionId => integer().withDefault(const Constant(0))();

  BlobColumn get stateEncryptionKey => blob().nullable()();
  BlobColumn get myGroupPrivateKey => blob().nullable()();

  TextColumn get groupName => text()();

  IntColumn get totalMediaCounter => integer().withDefault(const Constant(0))();

  BoolColumn get alsoBestFriend =>
      boolean().withDefault(const Constant(false))();

  IntColumn get deleteMessagesAfterMilliseconds => integer()
      .withDefault(const Constant(defaultDeleteMessagesAfterMilliseconds))();

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

enum MemberState { normal, admin }

@DataClassName('GroupMember')
class GroupMembers extends Table {
  TextColumn get groupId =>
      text().references(Groups, #groupId, onDelete: KeyAction.cascade)();

  IntColumn get contactId => integer().references(Contacts, #userId)();
  TextColumn get memberState => textEnum<MemberState>().nullable()();
  BlobColumn get groupPublicKey => blob().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {groupId, contactId};
}

enum GroupActionType {
  createdGroup,
  removedMember,
  addMember,
  leftGroup,
  promoteToAdmin,
  demoteToMember,
  updatedGroupName,
}

@DataClassName('GroupHistory')
class GroupHistories extends Table {
  TextColumn get groupHistoryId => text()();
  TextColumn get groupId =>
      text().references(Groups, #groupId, onDelete: KeyAction.cascade)();

  IntColumn get affectedContactId =>
      integer().nullable().references(Contacts, #userId)();

  TextColumn get oldGroupName => text().nullable()();
  TextColumn get newGroupName => text().nullable()();

  TextColumn get type => textEnum<GroupActionType>()();

  DateTimeColumn get actionAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {groupHistoryId};
}
