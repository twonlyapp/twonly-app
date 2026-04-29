import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';

class FlameCounterWidget extends StatefulWidget {
  const FlameCounterWidget({
    this.groupId,
    this.contactId,
    this.prefix = false,
    super.key,
  });
  final String? groupId;
  final int? contactId;
  final bool prefix;

  @override
  State<FlameCounterWidget> createState() => _FlameCounterWidgetState();
}

class _FlameCounterWidgetState extends State<FlameCounterWidget> {
  int flameCounter = 0;
  bool isBestFriend = false;
  bool isExpiring = false;

  StreamSubscription<({int counter, bool isExpiring})>? flameCounterSub;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void dispose() {
    flameCounterSub?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    var groupId = widget.groupId;
    late Group? group;
    if (widget.groupId == null && widget.contactId != null) {
      group = await twonlyDB.groupsDao.getDirectChat(widget.contactId!);
      groupId = group?.groupId;
    } else if (groupId != null) {
      group = await twonlyDB.groupsDao.getGroup(groupId);
    }
    if (groupId != null && group != null) {
      isBestFriend =
          userService.currentUser.myBestFriendGroupId == groupId &&
          group.alsoBestFriend;
      final stream = twonlyDB.groupsDao.watchFlameCounter(groupId);
      flameCounterSub = stream.listen((result) {
        if (mounted) {
          setState(() {
            flameCounter = result.counter;
            isExpiring = result.isExpiring;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (flameCounter < 1) return Container();

    var flameEmoji = '🔥';

    if (isBestFriend) flameEmoji = '❤️‍🔥';
    if (flameCounter == 100) flameEmoji = '💯';

    if (flameCounter >= 365 && flameCounter % 365 == 0) {
      flameEmoji = '🎂';
    }

    // Override with hourglass when the flame is about to expire
    if (isExpiring) flameEmoji = '⌛';

    return Row(
      children: [
        if (widget.prefix) const SizedBox(width: 5),
        if (widget.prefix) const Text('•'),
        if (widget.prefix) const SizedBox(width: 5),
        if (flameCounter != 100)
          Text(
            flameCounter.toString(),
            style: const TextStyle(fontSize: 13),
          ),
        SizedBox(
          height: 15,
          child: EmojiAnimationComp(
            emoji: flameEmoji,
          ),
        ),
      ],
    );
  }
}
