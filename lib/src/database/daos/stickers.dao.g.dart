// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stickers.dao.dart';

// ignore_for_file: type=lint
mixin _$StickersDaoMixin on DatabaseAccessor<TwonlyDB> {
  $StickersTable get stickers => attachedDatabase.stickers;
  StickersDaoManager get managers => StickersDaoManager(this);
}

class StickersDaoManager {
  final _$StickersDaoMixin _db;
  StickersDaoManager(this._db);
  $$StickersTableTableManager get stickers =>
      $$StickersTableTableManager(_db.attachedDatabase, _db.stickers);
}
