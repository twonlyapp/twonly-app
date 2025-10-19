import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';

@DataClassName('Message')
class Messages extends Table {
  TextColumn get groupId => text()();
  TextColumn get messageId => text().clientDefault(() => uuid.v7())();

  // in case senderId is null, it was send by user itself
  IntColumn get senderId =>
      integer().nullable().references(Contacts, #userId)();

  TextColumn get content => text().nullable()();
  TextColumn get mediaId =>
      text().nullable().references(MediaFiles, #mediaId)();

  TextColumn get quotesMessageId =>
      text().nullable().references(Messages, #messageId)();

  BoolColumn get isDeletedFromSender =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();

  BoolColumn get ackByUser => boolean().withDefault(const Constant(false))();
  BoolColumn get ackByServer => boolean().withDefault(const Constant(false))();

  IntColumn get openedByCounter => integer().withDefault(const Constant(0))();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get modifiedAt =>
      dateTime().nullable().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {messageId};
}

@DataClassName('MessageHistory')
class MessageHistories extends Table {
  TextColumn get messageId =>
      text().references(Messages, #messageId, onDelete: KeyAction.cascade)();

  TextColumn get content => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {messageId, createdAt};
}
