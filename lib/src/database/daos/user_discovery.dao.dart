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

  /// 1. Get count for contacts which are in announced but not in the contacts table

  /// Returns all users which are not yet in the contacts table but have no data loaded (e.g. Avatar, username and display name)
  Future<List<UserDiscoveryAnnouncedUser>>
  getNewAnnouncementsWithoutData() async {
    final query =
        select(userDiscoveryAnnouncedUsers).join([
            leftOuterJoin(
              contacts,
              contacts.userId.equalsExp(
                userDiscoveryAnnouncedUsers.announcedUserId,
              ),
            ),
          ])
          // Apply filters:
          // 1. The user must NOT exist in the contacts table
          // 2. The username must be null
          ..where(
            contacts.userId.isNull() &
                userDiscoveryAnnouncedUsers.username.isNull(),
          );

    return (await query.get())
        .map((row) => row.readTable(userDiscoveryAnnouncedUsers))
        .toList();
  }

  Future<Map<UserDiscoveryAnnouncedUser, List<(int, DateTime?)>>>
  getAnnouncedUsersWithRelations() async {
    final query = select(userDiscoveryAnnouncedUsers).join([
      innerJoin(
        userDiscoveryUserRelations,
        userDiscoveryUserRelations.announcedUserId.equalsExp(
          userDiscoveryAnnouncedUsers.announcedUserId,
        ),
      ),
    ]);

    final rows = await query.get();

    final results = <UserDiscoveryAnnouncedUser, List<(int, DateTime?)>>{};

    for (final row in rows) {
      final user = row.readTable(userDiscoveryAnnouncedUsers);
      final relation = row.readTable(userDiscoveryUserRelations);

      final relationData = (
        relation.fromContactId,
        relation.publicKeyVerifiedTimestamp,
      );

      if (!results.containsKey(user)) {
        results[user] = [];
      }
      results[user]!.add(relationData);
    }

    return results;
  }

  Stream<int> watchNewAnnouncementsWithDataCount() {
    final countExp = userDiscoveryAnnouncedUsers.announcedUserId.count();

    final query = selectOnly(userDiscoveryAnnouncedUsers)
      ..addColumns([countExp])
      ..where(
        // Filters: Has a username AND has not been shown to the user yet
        userDiscoveryAnnouncedUsers.username.isNotNull() &
            userDiscoveryAnnouncedUsers.wasShownToTheUser.equals(false) &
            userDiscoveryAnnouncedUsers.isHidden.equals(false),
      );

    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> updateAnnouncedUser(
    int announcedUserId,
    UserDiscoveryAnnouncedUsersCompanion updatedValues,
  ) async {
    await (update(
      userDiscoveryAnnouncedUsers,
    )..where((c) => c.announcedUserId.equals(announcedUserId))).write(
      updatedValues,
    );
  }
}
