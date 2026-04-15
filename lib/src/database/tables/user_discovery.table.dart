import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';

// contact_versions: HashMap<UserID, Vec<u8>>,
// -> New Column in Contacts

// config: Option<Vec<u8>>,

// announced_users: HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>,

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
  IntColumn get versionId => integer().autoIncrement()();
  IntColumn get contactId => integer().references(
    Contacts,
    #userId,
    onDelete: KeyAction.cascade,
  )();

  BlobColumn get promotion => blob()();
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
