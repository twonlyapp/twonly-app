// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal.dao.dart';

// ignore_for_file: type=lint
mixin _$SignalDaoMixin on DatabaseAccessor<TwonlyDB> {
  $ContactsTable get contacts => attachedDatabase.contacts;
  $SignalContactPreKeysTable get signalContactPreKeys =>
      attachedDatabase.signalContactPreKeys;
  $SignalContactSignedPreKeysTable get signalContactSignedPreKeys =>
      attachedDatabase.signalContactSignedPreKeys;
  SignalDaoManager get managers => SignalDaoManager(this);
}

class SignalDaoManager {
  final _$SignalDaoMixin _db;
  SignalDaoManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$SignalContactPreKeysTableTableManager get signalContactPreKeys =>
      $$SignalContactPreKeysTableTableManager(
          _db.attachedDatabase, _db.signalContactPreKeys);
  $$SignalContactSignedPreKeysTableTableManager
      get signalContactSignedPreKeys =>
          $$SignalContactSignedPreKeysTableTableManager(
              _db.attachedDatabase, _db.signalContactSignedPreKeys);
}
