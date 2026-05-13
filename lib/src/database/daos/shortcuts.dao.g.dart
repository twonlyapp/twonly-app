// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shortcuts.dao.dart';

// ignore_for_file: type=lint
mixin _$ShortcutsDaoMixin on DatabaseAccessor<TwonlyDB> {
  $ShortcutsTable get shortcuts => attachedDatabase.shortcuts;
  $GroupsTable get groups => attachedDatabase.groups;
  $ShortcutMembersTable get shortcutMembers => attachedDatabase.shortcutMembers;
  ShortcutsDaoManager get managers => ShortcutsDaoManager(this);
}

class ShortcutsDaoManager {
  final _$ShortcutsDaoMixin _db;
  ShortcutsDaoManager(this._db);
  $$ShortcutsTableTableManager get shortcuts =>
      $$ShortcutsTableTableManager(_db.attachedDatabase, _db.shortcuts);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$ShortcutMembersTableTableManager get shortcutMembers =>
      $$ShortcutMembersTableTableManager(
        _db.attachedDatabase,
        _db.shortcutMembers,
      );
}
