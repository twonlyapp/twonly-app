import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/user_discovery.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'user_discovery.dao.g.dart';

@DriftAccessor(
  tables: [
    UserDiscoveryAnnouncedUsers,
    UserDiscoveryUserRelations,
    UserDiscoveryOwnPromotions,
    UserDiscoveryShares,
  ],
)
class UserDiscoveryDao extends DatabaseAccessor<TwonlyDB>
    with _$UserDiscoveryDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  UserDiscoveryDao(super.db);
}
