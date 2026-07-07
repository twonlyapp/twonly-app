// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mediafiles.dao.dart';

// ignore_for_file: type=lint
mixin _$MediaFilesDaoMixin on DatabaseAccessor<TwonlyDB> {
  $MediaFilesTable get mediaFiles => attachedDatabase.mediaFiles;
  $GroupsTable get groups => attachedDatabase.groups;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $MessagesTable get messages => attachedDatabase.messages;
  MediaFilesDaoManager get managers => MediaFilesDaoManager(this);
}

class MediaFilesDaoManager {
  final _$MediaFilesDaoMixin _db;
  MediaFilesDaoManager(this._db);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db.attachedDatabase, _db.mediaFiles);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
}
