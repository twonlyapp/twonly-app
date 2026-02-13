// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mediafiles.dao.dart';

// ignore_for_file: type=lint
mixin _$MediaFilesDaoMixin on DatabaseAccessor<TwonlyDB> {
  $MediaFilesTable get mediaFiles => attachedDatabase.mediaFiles;
  MediaFilesDaoManager get managers => MediaFilesDaoManager(this);
}

class MediaFilesDaoManager {
  final _$MediaFilesDaoMixin _db;
  MediaFilesDaoManager(this._db);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db.attachedDatabase, _db.mediaFiles);
}
