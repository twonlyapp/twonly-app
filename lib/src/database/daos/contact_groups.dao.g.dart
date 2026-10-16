// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_groups.dao.dart';

// ignore_for_file: type=lint
mixin _$ContactGroupsDaoMixin on DatabaseAccessor<TwonlyDB> {
  $ContactGroupsTable get contactGroups => attachedDatabase.contactGroups;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $GroupsTable get groups => attachedDatabase.groups;
  $ContactGroupMembersTable get contactGroupMembers =>
      attachedDatabase.contactGroupMembers;
  ContactGroupsDaoManager get managers => ContactGroupsDaoManager(this);
}

class ContactGroupsDaoManager {
  final _$ContactGroupsDaoMixin _db;
  ContactGroupsDaoManager(this._db);
  $$ContactGroupsTableTableManager get contactGroups =>
      $$ContactGroupsTableTableManager(_db.attachedDatabase, _db.contactGroups);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$ContactGroupMembersTableTableManager get contactGroupMembers =>
      $$ContactGroupMembersTableTableManager(
        _db.attachedDatabase,
        _db.contactGroupMembers,
      );
}
