// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'labels.dao.dart';

// ignore_for_file: type=lint
mixin _$LabelsDaoMixin on DatabaseAccessor<TwonlyDB> {
  $LabelsTable get labels => attachedDatabase.labels;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $ContactLabelsTable get contactLabels => attachedDatabase.contactLabels;
  LabelsDaoManager get managers => LabelsDaoManager(this);
}

class LabelsDaoManager {
  final _$LabelsDaoMixin _db;
  LabelsDaoManager(this._db);
  $$LabelsTableTableManager get labels =>
      $$LabelsTableTableManager(_db.attachedDatabase, _db.labels);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$ContactLabelsTableTableManager get contactLabels =>
      $$ContactLabelsTableTableManager(_db.attachedDatabase, _db.contactLabels);
}
