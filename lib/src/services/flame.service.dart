import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

Future<void> syncFlameCounters({String? forceForGroup}) async {
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
    if (forceForGroup == null || group.groupId != forceForGroup) {
      if (group.lastFlameSync != null) {
        if (isToday(group.lastFlameSync!)) continue;
      }
    }

    final flameCounter = getFlameCounterFromGroup(group);

    // only sync when flame counter is higher three or when they are bestFriends
    if (flameCounter <= 2 && bestFriend.groupId != group.groupId) continue;

    final groupMembers =
        await twonlyDB.groupsDao.getGroupNonLeftMembers(group.groupId);
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
          forceUpdate: group.groupId == forceForGroup,
        ),
      ),
    );

    await twonlyDB.groupsDao.updateGroup(
      group.groupId,
      GroupsCompanion(
        lastFlameSync: Value(clock.now()),
      ),
    );
  }
}

int getFlameCounterFromGroup(Group? group) {
  if (group == null) return 0;
  if (group.lastMessageSend == null ||
      group.lastMessageReceived == null ||
      group.lastFlameCounterChange == null) {
    return 0;
  }
  final now = clock.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final twoDaysAgo = startOfToday.subtract(const Duration(days: 2));
  final oneDayAgo = startOfToday.subtract(const Duration(days: 1));
  if (group.lastMessageSend!.isAfter(twoDaysAgo) &&
          group.lastMessageReceived!.isAfter(twoDaysAgo) ||
      group.lastFlameCounterChange!.isAfter(oneDayAgo)) {
    return group.flameCounter;
  } else {
    return 0;
  }
}

Future<void> incFlameCounter(
  String groupId,
  bool received,
  DateTime timestamp,
) async {
  final group = await twonlyDB.groupsDao.getGroup(groupId);
  if (group == null) return;

  final totalMediaCounter = group.totalMediaCounter + 1;
  var flameCounter = group.flameCounter;
  var maxFlameCounter = group.maxFlameCounter;
  var maxFlameCounterFrom = group.maxFlameCounterFrom;

  if (group.lastMessageReceived != null && group.lastMessageSend != null) {
    final now = clock.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final twoDaysAgo = startOfToday.subtract(const Duration(days: 2));
    if (group.lastMessageSend!.isBefore(twoDaysAgo) ||
        group.lastMessageReceived!.isBefore(twoDaysAgo)) {
      flameCounter = 0;
    }
  }

  var lastMessageSend = const Value<DateTime?>.absent();
  var lastMessageReceived = const Value<DateTime?>.absent();
  var lastFlameCounterChange = const Value<DateTime?>.absent();

  final now = clock.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  if (group.lastFlameCounterChange == null ||
      group.lastFlameCounterChange!.isBefore(startOfToday)) {
    // last flame update was yesterday. check if it can be updated.
    var updateFlame = false;
    if (received) {
      if (group.lastMessageSend != null &&
          group.lastMessageSend!.isAfter(startOfToday)) {
        // today a message was already send -> update flame
        updateFlame = true;
      }
    } else if (group.lastMessageReceived != null &&
        group.lastMessageReceived!.isAfter(startOfToday)) {
      // today a message was already received -> update flame
      updateFlame = true;
    }
    if (updateFlame) {
      flameCounter += 1;
      if (group.lastFlameCounterChange == null ||
          group.lastFlameCounterChange!.isBefore(timestamp)) {
        // only update if the timestamp is newer
        lastFlameCounterChange = Value(timestamp);
      }
      // Overwrite max flame counter either the current is bigger or the the max flame counter is older then 4 days
      if (flameCounter >= maxFlameCounter ||
          maxFlameCounterFrom == null ||
          maxFlameCounterFrom
              .isBefore(clock.now().subtract(const Duration(days: 5)))) {
        maxFlameCounter = flameCounter;
        maxFlameCounterFrom = clock.now();
      }
    }
  }

  if (received) {
    if (group.lastMessageReceived == null ||
        group.lastMessageReceived!.isBefore(timestamp)) {
      lastMessageReceived = Value(timestamp);
    }
  } else {
    if (group.lastMessageSend == null ||
        group.lastMessageSend!.isBefore(timestamp)) {
      lastMessageSend = Value(timestamp);
    }
  }

  await twonlyDB.groupsDao.updateGroup(
    groupId,
    GroupsCompanion(
      totalMediaCounter: Value(totalMediaCounter),
      lastFlameCounterChange: lastFlameCounterChange,
      lastMessageReceived: lastMessageReceived,
      lastMessageSend: lastMessageSend,
      flameCounter: Value(flameCounter),
      maxFlameCounter: Value(maxFlameCounter),
      maxFlameCounterFrom: Value(maxFlameCounterFrom),
    ),
  );
}

bool isItPossibleToRestoreFlames(Group group) {
  final flameCounter = getFlameCounterFromGroup(group);
  return group.maxFlameCounter > 2 &&
      flameCounter < group.maxFlameCounter &&
      group.maxFlameCounterFrom!
          .isAfter(clock.now().subtract(const Duration(days: 5)));
}
