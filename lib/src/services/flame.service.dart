import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/groups.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

Future<void> syncFlameCounters() async {
  final groups = await twonlyDB.groupsDao.getAllDirectChats();
  if (groups.isEmpty) return;
  final maxMessageCounter = groups.map((x) => x.totalMediaCounter).max;
  final bestFriend =
      groups.firstWhere((x) => x.totalMediaCounter == maxMessageCounter);

  if (gUser.myBestFriendGroupId != bestFriend.groupId) {
    await updateUserdata((user) {
      user.myBestFriendGroupId = bestFriend.groupId;
      return user;
    });
  }

  for (final group in groups) {
    if (group.lastFlameCounterChange == null) continue;
    if (!isToday(group.lastFlameCounterChange!)) continue;
    if (group.lastFlameSync != null) {
      if (isToday(group.lastFlameSync!)) continue;
    }

    final flameCounter = getFlameCounterFromGroup(group) - 1;

    // only sync when flame counter is higher than three days or when they are bestFriends
    if (flameCounter < 1 && bestFriend.groupId != group.groupId) continue;

    final groupMembers =
        await twonlyDB.groupsDao.getGroupMembers(group.groupId);
    if (groupMembers.length != 1) {
      continue; // flame sync is only done for groups of two
    }

    await sendCipherText(
      groupMembers.first.contactId,
      EncryptedContent(
        flameSync: EncryptedContent_FlameSync(
          flameCounter: Int64(flameCounter),
          lastFlameCounterChange:
              Int64(group.lastFlameCounterChange!.millisecondsSinceEpoch),
          bestFriend: group.groupId == bestFriend.groupId,
        ),
      ),
    );

    await twonlyDB.groupsDao.updateGroup(
      group.groupId,
      GroupsCompanion(
        lastFlameSync: Value(DateTime.now()),
      ),
    );
  }
}
