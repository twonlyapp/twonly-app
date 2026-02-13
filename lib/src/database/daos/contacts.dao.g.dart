// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contacts.dao.dart';

// ignore_for_file: type=lint
mixin _$ContactsDaoMixin on DatabaseAccessor<TwonlyDB> {
  $ContactsTable get contacts => attachedDatabase.contacts;
  ContactsDaoManager get managers => ContactsDaoManager(this);
}

class ContactsDaoManager {
  final _$ContactsDaoMixin _db;
  ContactsDaoManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
}
