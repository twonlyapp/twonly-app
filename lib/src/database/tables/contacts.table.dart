import 'package:drift/drift.dart';

class Contacts extends Table {
  IntColumn get userId => integer()();

  TextColumn get username => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get nickName => text().nullable()();
  TextColumn get avatarSvg => text().nullable()();

  IntColumn get senderProfileCounter =>
      integer().withDefault(const Constant(0))();

  BoolColumn get accepted => boolean().withDefault(const Constant(false))();
  BoolColumn get requested => boolean().withDefault(const Constant(false))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();
  BoolColumn get blocked => boolean().withDefault(const Constant(false))();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  BoolColumn get alsoBestFriend =>
      boolean().withDefault(const Constant(false))();

  IntColumn get deleteMessagesAfterXMinutes =>
      integer().withDefault(const Constant(60 * 24))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get totalMediaCounter => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastMessageSend => dateTime().nullable()();
  DateTimeColumn get lastMessageReceived => dateTime().nullable()();
  DateTimeColumn get lastFlameCounterChange => dateTime().nullable()();
  DateTimeColumn get lastFlameSync => dateTime().nullable()();

  IntColumn get flameCounter => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId};
}
