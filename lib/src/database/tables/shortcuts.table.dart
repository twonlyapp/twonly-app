import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/groups.table.dart';

@DataClassName('Shortcut')
class Shortcuts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get emoji => text().unique()();
  IntColumn get usageCounter => integer().withDefault(const Constant(0))();
}

@DataClassName('ShortcutMember')
class ShortcutMembers extends Table {
  IntColumn get shortcutId => integer().references(
    Shortcuts,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get groupId => text().references(
    Groups,
    #groupId,
    onDelete: KeyAction.cascade,
  )();

  @override
  Set<Column> get primaryKey => {shortcutId, groupId};
}
