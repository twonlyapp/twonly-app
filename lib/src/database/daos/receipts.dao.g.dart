// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts.dao.dart';

// ignore_for_file: type=lint
mixin _$ReceiptsDaoMixin on DatabaseAccessor<TwonlyDB> {
  $ContactsTable get contacts => attachedDatabase.contacts;
  $GroupsTable get groups => attachedDatabase.groups;
  $MediaFilesTable get mediaFiles => attachedDatabase.mediaFiles;
  $MessagesTable get messages => attachedDatabase.messages;
  $ReceiptsTable get receipts => attachedDatabase.receipts;
  $MessageActionsTable get messageActions => attachedDatabase.messageActions;
  $ReceivedReceiptsTable get receivedReceipts =>
      attachedDatabase.receivedReceipts;
  ReceiptsDaoManager get managers => ReceiptsDaoManager(this);
}

class ReceiptsDaoManager {
  final _$ReceiptsDaoMixin _db;
  ReceiptsDaoManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db.attachedDatabase, _db.mediaFiles);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db.attachedDatabase, _db.receipts);
  $$MessageActionsTableTableManager get messageActions =>
      $$MessageActionsTableTableManager(
          _db.attachedDatabase, _db.messageActions);
  $$ReceivedReceiptsTableTableManager get receivedReceipts =>
      $$ReceivedReceiptsTableTableManager(
          _db.attachedDatabase, _db.receivedReceipts);
}
