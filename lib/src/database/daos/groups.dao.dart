import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'groups.dao.g.dart';

@DriftAccessor(tables: [Groups, GroupMembers])
class GroupsDao extends DatabaseAccessor<TwonlyDB> with _$GroupsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  GroupsDao(super.db);

  Future<bool> isContactInGroup(int contactId, String groupId) async {
    final entry = await (select(groupMembers)
          ..where(
              (t) => t.contactId.equals(contactId) & t.groupId.equals(groupId)))
        .getSingleOrNull();
    return entry != null;
  }
}
