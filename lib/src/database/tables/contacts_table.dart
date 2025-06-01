import 'package:drift/drift.dart';

class Contacts extends Table {
  IntColumn get userId => integer()();

  TextColumn get username => text().unique()();
  TextColumn get displayName => text().nullable()();
  TextColumn get nickName => text().nullable()();
  TextColumn get avatarSvg => text().nullable()();

  IntColumn get myAvatarCounter => integer().withDefault(Constant(0))();

  BoolColumn get accepted => boolean().withDefault(Constant(false))();
  BoolColumn get requested => boolean().withDefault(Constant(false))();
  BoolColumn get blocked => boolean().withDefault(Constant(false))();
  BoolColumn get verified => boolean().withDefault(Constant(false))();
  BoolColumn get archived => boolean().withDefault(Constant(false))();
  BoolColumn get pinned => boolean().withDefault(Constant(false))();
  BoolColumn get deleted => boolean().withDefault(Constant(false))();

  BoolColumn get alsoBestFriend => boolean().withDefault(Constant(false))();

  IntColumn get deleteMessagesAfterXMinutes =>
      integer().withDefault(Constant(60 * 24))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get totalMediaCounter => integer().withDefault(Constant(0))();

  DateTimeColumn get lastMessageSend => dateTime().nullable()();
  DateTimeColumn get lastMessageReceived => dateTime().nullable()();
  DateTimeColumn get lastFlameCounterChange => dateTime().nullable()();
  DateTimeColumn get lastFlameSync => dateTime().nullable()();
  DateTimeColumn get lastMessageExchange =>
      dateTime().withDefault(currentDateAndTime)();

  IntColumn get flameCounter => integer().withDefault(Constant(0))();

  @override
  Set<Column> get primaryKey => {userId};
}
