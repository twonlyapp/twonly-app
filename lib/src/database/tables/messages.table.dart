import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';

enum MessageType { media, text }

@DataClassName('Message')
class Messages extends Table {
  TextColumn get groupId =>
      text().references(Groups, #groupId, onDelete: KeyAction.cascade)();
  TextColumn get messageId => text().clientDefault(() => uuid.v7())();

  // in case senderId is null, it was send by user itself
  IntColumn get senderId =>
      integer().nullable().references(Contacts, #userId)();

  TextColumn get type => textEnum<MessageType>()();

  TextColumn get content => text().nullable()();
  TextColumn get mediaId => text()
      .nullable()
      .references(MediaFiles, #mediaId, onDelete: KeyAction.cascade)();

  BoolColumn get mediaStored => boolean().withDefault(const Constant(false))();

  BlobColumn get downloadToken => blob().nullable()();

  TextColumn get quotesMessageId =>
      text().nullable().references(Messages, #messageId)();

  BoolColumn get isDeletedFromSender =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {messageId};
}

enum MessageActionType {
  openedAt,
  modifiedAt,
  ackByUserAt,
  ackByServerAt,
}

@DataClassName('MessageAction')
class MessageActions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get messageId =>
      text().references(Messages, #messageId, onDelete: KeyAction.cascade)();

  IntColumn get contactId =>
      integer().references(Contacts, #contactId, onDelete: KeyAction.cascade)();

  TextColumn get type => textEnum<MessageActionType>()();
  DateTimeColumn get actionAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MessageHistory')
class MessageHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get messageId =>
      text().references(Messages, #messageId, onDelete: KeyAction.cascade)();

  IntColumn get contactId =>
      integer().references(Contacts, #contactId, onDelete: KeyAction.cascade)();

  TextColumn get content => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
