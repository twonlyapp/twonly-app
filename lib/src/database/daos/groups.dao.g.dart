// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groups.dao.dart';

// ignore_for_file: type=lint
mixin _$GroupsDaoMixin on DatabaseAccessor<TwonlyDB> {
  $GroupsTable get groups => attachedDatabase.groups;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $GroupMembersTable get groupMembers => attachedDatabase.groupMembers;
  $GroupHistoriesTable get groupHistories => attachedDatabase.groupHistories;
  GroupsDaoManager get managers => GroupsDaoManager(this);
}

class GroupsDaoManager {
  final _$GroupsDaoMixin _db;
  GroupsDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db.attachedDatabase, _db.groupMembers);
  $$GroupHistoriesTableTableManager get groupHistories =>
      $$GroupHistoriesTableTableManager(
          _db.attachedDatabase, _db.groupHistories);
}
