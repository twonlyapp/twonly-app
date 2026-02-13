// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reactions.dao.dart';

// ignore_for_file: type=lint
mixin _$ReactionsDaoMixin on DatabaseAccessor<TwonlyDB> {
  $GroupsTable get groups => attachedDatabase.groups;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $MediaFilesTable get mediaFiles => attachedDatabase.mediaFiles;
  $MessagesTable get messages => attachedDatabase.messages;
  $ReactionsTable get reactions => attachedDatabase.reactions;
  ReactionsDaoManager get managers => ReactionsDaoManager(this);
}

class ReactionsDaoManager {
  final _$ReactionsDaoMixin _db;
  ReactionsDaoManager(this._db);
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
}
