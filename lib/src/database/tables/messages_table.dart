import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';

enum MessageKind {
  textMessage,
  storedMediaFile,
  media,
  contactRequest,
  profileChange,
  rejectRequest,
  acceptRequest,
  opened,
  ack,
  pushKey,
  pushKeyAck,
}

enum DownloadState {
  pending,
  downloading,
  downloaded,
}

@DataClassName('Message')
class Messages extends Table {
  IntColumn get contactId => integer().references(Contacts, #userId)();

  IntColumn get messageId => integer().autoIncrement()();
  IntColumn get messageOtherId => integer().nullable()();

  IntColumn get responseToMessageId => integer().nullable()();
  IntColumn get responseToOtherMessageId => integer().nullable()();

  BoolColumn get acknowledgeByUser => boolean().withDefault(Constant(false))();
  IntColumn get downloadState => intEnum<DownloadState>()
      .withDefault(Constant(DownloadState.downloaded.index))();

  BoolColumn get acknowledgeByServer =>
      boolean().withDefault(Constant(false))();

  BoolColumn get errorWhileSending => boolean().withDefault(Constant(false))();

  TextColumn get kind => textEnum<MessageKind>()();
  TextColumn get contentJson => text().nullable()();

  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get sendAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
