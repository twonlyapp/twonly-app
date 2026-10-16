// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stories.dao.dart';

// ignore_for_file: type=lint
mixin _$StoriesDaoMixin on DatabaseAccessor<TwonlyDB> {
  $GroupsTable get groups => attachedDatabase.groups;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $MediaFilesTable get mediaFiles => attachedDatabase.mediaFiles;
  $MessagesTable get messages => attachedDatabase.messages;
  $GroupMembersTable get groupMembers => attachedDatabase.groupMembers;
  $MessageActionsTable get messageActions => attachedDatabase.messageActions;
  StoriesDaoManager get managers => StoriesDaoManager(this);
}

class StoriesDaoManager {
  final _$StoriesDaoMixin _db;
  StoriesDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db.attachedDatabase, _db.mediaFiles);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db.attachedDatabase, _db.groupMembers);
  $$MessageActionsTableTableManager get messageActions =>
      $$MessageActionsTableTableManager(
        _db.attachedDatabase,
        _db.messageActions,
      );
}
