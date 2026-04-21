import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

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

  StreamSubscription<int>? flameCounterSub;

  @override
  void initState() {
    initAsync();
    super.initState();
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
          AppSession.currentUser.myBestFriendGroupId == groupId && group.alsoBestFriend;
      final stream = twonlyDB.groupsDao.watchFlameCounter(groupId);
      flameCounterSub = stream.listen((counter) {
        if (mounted) {
          setState(() {
            flameCounter = counter;
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
          child: EmojiAnimation(
            emoji: flameEmoji,
          ),
        ),
      ],
    );
  }
}
