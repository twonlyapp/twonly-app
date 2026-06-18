import 'package:drift/drift.dart';

@DataClassName('Contact')
class Contacts extends Table {
  IntColumn get userId => integer()();

  TextColumn get username => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get nickName => text().nullable()();
  BlobColumn get avatarSvgCompressed => blob().nullable()();

  IntColumn get senderProfileCounter =>
      integer().withDefault(const Constant(0))();

  BoolColumn get accepted => boolean().withDefault(const Constant(false))();
  BoolColumn get deletedByUser =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get requested => boolean().withDefault(const Constant(false))();
  BoolColumn get blocked => boolean().withDefault(const Constant(false))();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  BoolColumn get accountDeleted =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // User Discovery
  BlobColumn get userDiscoveryVersion => blob().nullable()();
  BoolColumn get userDiscoveryExcluded =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get userDiscoveryManualApproved =>
      boolean().nullable().withDefault(const Constant(false))();

  // Passwordless-Recovery
  BoolColumn get recoveryIsTrustedFriend =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get recoveryLastHeartbeat => dateTime().nullable()();
  BlobColumn get recoverySecretShare => blob().nullable()();

  BoolColumn get askForFriendPromotions => boolean().nullable()();

  IntColumn get mediaSendCounter => integer().withDefault(const Constant(0))();
  IntColumn get mediaReceivedCounter =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId};
}

enum VerificationType {
  migratedFromOldVersion,
  qrScanned,
  link,
  secretQrToken,
  contactSharedByVerified,
}

@DataClassName('KeyVerification')
class KeyVerifications extends Table {
  IntColumn get verificationId => integer().autoIncrement()();
  IntColumn get contactId => integer().references(
    Contacts,
    #userId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get type => textEnum<VerificationType>()();
  IntColumn get verifiedBy => integer().nullable().references(
    Contacts,
    #userId,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('VerificationToken')
class VerificationTokens extends Table {
  IntColumn get tokenId => integer().autoIncrement()();
  BlobColumn get token => blob()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
