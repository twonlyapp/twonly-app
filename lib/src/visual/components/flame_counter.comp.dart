import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';

class FlameCounterWidget extends StatefulWidget {
  const FlameCounterWidget({
    this.groupId,
    this.contactId,
    this.group,
    this.prefix = false,
    super.key,
  });
  final String? groupId;
  final int? contactId;
  final Group? group;
  final bool prefix;

  @override
  State<FlameCounterWidget> createState() => _FlameCounterWidgetState();
}

class _FlameCounterWidgetState extends State<FlameCounterWidget> {
  int flameCounter = 0;
  bool isBestFriend = false;
  bool isExpiring = false;

  StreamSubscription<FlameState>? flameCounterSub;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didUpdateWidget(FlameCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.group != null && widget.group != oldWidget.group) {
      initAsync();
    }
  }

  @override
  void dispose() {
    flameCounterSub?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    var groupId = widget.groupId;
    var group = widget.group;
    if (group != null) {
      groupId = group.groupId;
    } else if (widget.groupId == null && widget.contactId != null) {
      group = await rust_groups
          .listGroups(
            input: db_groups.GroupQuery(
              filter: db_groups.GroupFilter.directContact,
              contactId: widget.contactId,
            ),
            transaction: currentDatabaseSession(),
          )
          .then((rows) => rows.isEmpty ? null : rows.single);
      groupId = group?.groupId;
    } else if (groupId != null) {
      group = await rust_groups.getGroup(
        id: groupId,
        transaction: currentDatabaseSession(),
      );
    }
    if (groupId != null && group != null) {
      if (widget.group != null) {
        _apply(await rust_groups.flameState(groupId: groupId));
        return;
      }
      final watchedGroupId = groupId;
      final stream = watchRustDatabase(
        (control) => rust_groups.watchGroupFlame(
          group: watchedGroupId,
          control: control,
        ),
      );
      flameCounterSub = stream.listen(_apply);
    }
  }

  void _apply(FlameState state) {
    if (!mounted) return;
    setState(() {
      flameCounter = state.counter;
      isExpiring = state.isExpiring;
      isBestFriend = state.isBestFriend;
    });
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
          child: EmojiAnimationComp(
            emoji: flameEmoji,
          ),
        ),
        if (isExpiring)
          const SizedBox(
            height: 11,
            child: EmojiAnimationComp(
              emoji: '⌛',
              repeat: false,
            ),
          ),
      ],
    );
  }
}
