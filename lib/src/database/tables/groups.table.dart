import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

@DataClassName('Group')
class Groups extends Table {
  TextColumn get groupId => text().clientDefault(() => uuid.v4())();

  BoolColumn get isGroupAdmin => boolean()();
  BoolColumn get isGroupOfTwo => boolean()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get lastMessageExchange =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

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
