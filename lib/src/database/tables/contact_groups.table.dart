import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';

@DataClassName('ContactGroup')
class ContactGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get emoji => text().nullable()();
  IntColumn get textColor => integer()();
  IntColumn get backgroundColor => integer()();
  BoolColumn get showAsShortcut =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showAsLabel => boolean().withDefault(const Constant(true))();
  IntColumn get usageCounter => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ContactGroupMember')
class ContactGroupMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contactGroupId => integer().references(
    ContactGroups,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get userId => integer().nullable().references(
    Contacts,
    #userId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get groupId => text().nullable().references(
    Groups,
    #groupId,
    onDelete: KeyAction.cascade,
  )();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {contactGroupId, userId},
    {contactGroupId, groupId},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK ((user_id IS NOT NULL) != (group_id IS NOT NULL))',
  ];
}
