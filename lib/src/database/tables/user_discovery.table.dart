import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

// config: Option<Vec<u8>>,

// announced_users: HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>,
@DataClassName('UserDiscoveryAnnouncedUser')
class UserDiscoveryAnnouncedUsers extends Table {
  IntColumn get announcedUserId => integer()();
  BlobColumn get announcedPublicKey => blob()();
  IntColumn get publicId => integer().unique()();

  // When a new user got announced this data will be requested without adding the users to the contacts...
  TextColumn get username => text().nullable()();

  BoolColumn get wasShownToTheUser =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {announcedUserId};
}

// announced_users: HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>,
@DataClassName('UserDiscoveryUserRelation')
class UserDiscoveryUserRelations extends Table {
  IntColumn get announcedUserId => integer().references(
    UserDiscoveryAnnouncedUsers,
    #announcedUserId,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get fromContactId => integer().references(
    Contacts,
    #userId,
    onDelete: KeyAction.cascade,
  )();

  DateTimeColumn get publicKeyVerifiedTimestamp => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {announcedUserId, fromContactId};
}

// own_promotions: Vec<(UserID, Vec<u8>)>,
@DataClassName('UserDiscoveryOwnPromotion')
class UserDiscoveryOwnPromotions extends Table {
  IntColumn get versionId => integer().autoIncrement()();
  IntColumn get contactId => integer().references(
    Contacts,
    #userId,
    onDelete: KeyAction.cascade,
  )();
  BlobColumn get promotion => blob()();
}

// other_promotions: Vec<OtherPromotion>,
@DataClassName('UserDiscoveryOtherPromotion')
class UserDiscoveryOtherPromotions extends Table {
  IntColumn get fromContactId => integer().references(
    Contacts,
    #userId,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get promotionId => integer()();
  IntColumn get publicId => integer()();
  IntColumn get threshold => integer()();
  BlobColumn get announcementShare => blob()();
  DateTimeColumn get publicKeyVerifiedTimestamp => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {fromContactId, promotionId};
}

// unused_shares: Vec<Vec<u8>>,
// used_shares: HashMap<UserID, Vec<u8>>,
@DataClassName('UserDiscoveryShare')
class UserDiscoveryShares extends Table {
  IntColumn get shareId => integer().autoIncrement()();
  BlobColumn get share => blob()();
  IntColumn get contactId => integer().nullable().references(
    Contacts,
    #userId,
    onDelete: KeyAction.cascade,
  )();
}
