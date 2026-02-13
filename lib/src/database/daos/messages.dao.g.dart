// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages.dao.dart';

// ignore_for_file: type=lint
mixin _$MessagesDaoMixin on DatabaseAccessor<TwonlyDB> {
  $GroupsTable get groups => attachedDatabase.groups;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $MediaFilesTable get mediaFiles => attachedDatabase.mediaFiles;
  $MessagesTable get messages => attachedDatabase.messages;
  $ReactionsTable get reactions => attachedDatabase.reactions;
  $MessageHistoriesTable get messageHistories =>
      attachedDatabase.messageHistories;
  $GroupMembersTable get groupMembers => attachedDatabase.groupMembers;
  $MessageActionsTable get messageActions => attachedDatabase.messageActions;
  MessagesDaoManager get managers => MessagesDaoManager(this);
}

class MessagesDaoManager {
  final _$MessagesDaoMixin _db;
  MessagesDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db.attachedDatabase, _db.mediaFiles);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
  $$ReactionsTableTableManager get reactions =>
      $$ReactionsTableTableManager(_db.attachedDatabase, _db.reactions);
  $$MessageHistoriesTableTableManager get messageHistories =>
      $$MessageHistoriesTableTableManager(
          _db.attachedDatabase, _db.messageHistories);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db.attachedDatabase, _db.groupMembers);
  $$MessageActionsTableTableManager get messageActions =>
      $$MessageActionsTableTableManager(
          _db.attachedDatabase, _db.messageActions);
}
