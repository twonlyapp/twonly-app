import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
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
    if (widget.groupId == null && widget.contactId != null) {
      final group = await twonlyDB.groupsDao.getDirectChat(widget.contactId!);
      groupId = group?.groupId;
    } else if (groupId != null) {
      // do not display the flame counter for groups
      final group = await twonlyDB.groupsDao.getGroup(groupId);
      if (!(group?.isDirectChat ?? false)) {
        return;
      }
    }
    if (groupId != null) {
      isBestFriend = gUser.myBestFriendGroupId == groupId;
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
    return Row(
      children: [
        if (widget.prefix) const SizedBox(width: 5),
        if (widget.prefix) const Text('•'),
        if (widget.prefix) const SizedBox(width: 5),
        Text(
          flameCounter.toString(),
          style: const TextStyle(fontSize: 13),
        ),
        SizedBox(
          height: 15,
          child: EmojiAnimation(
            emoji: isBestFriend ? '❤️‍🔥' : '🔥',
          ),
        ),
      ],
    );
  }
}
