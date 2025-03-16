import 'package:drift/drift.dart';
import 'package:twonly/src/database/twonly_database.dart';

class Contacts extends Table {
  IntColumn get userId => integer()();

  TextColumn get username => text().unique()();
  TextColumn get displayName => text().nullable()();
  TextColumn get nickName => text().nullable()();

  BoolColumn get accepted => boolean().withDefault(Constant(false))();
  BoolColumn get requested => boolean().withDefault(Constant(false))();
  BoolColumn get blocked => boolean().withDefault(Constant(false))();
  BoolColumn get verified => boolean().withDefault(Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get totalMediaCounter => integer().withDefault(Constant(0))();

  DateTimeColumn get lastMessageSend => dateTime().nullable()();
  DateTimeColumn get lastMessageReceived => dateTime().nullable()();
  DateTimeColumn get lastMessage => dateTime().nullable()();

  IntColumn get flameCounter => integer().withDefault(Constant(0))();

  @override
  Set<Column> get primaryKey => {userId};
}

String getContactDisplayName(Contact user) {
  if (user.nickName != null) {
    return user.nickName!;
  }
  if (user.displayName != null) {
    return user.displayName!;
  }
  return user.username;
}

int getFlameCounterFromContact(Contact contact) {
  if (contact.lastMessageSend == null || contact.lastMessageReceived == null) {
    return 0;
  }
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final twoDaysAgo = startOfToday.subtract(Duration(days: 2));
  if (contact.lastMessageSend!.isAfter(twoDaysAgo) &&
      contact.lastMessageReceived!.isAfter(twoDaysAgo)) {
    return contact.flameCounter + 1;
  } else {
    return 0;
  }
}
