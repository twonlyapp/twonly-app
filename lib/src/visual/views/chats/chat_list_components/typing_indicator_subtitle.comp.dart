import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/typing_indicator.dart';

class TypingIndicatorSubtitleComp extends StatefulWidget {
  const TypingIndicatorSubtitleComp({required this.groupId, super.key});

  final String groupId;

  @override
  State<TypingIndicatorSubtitleComp> createState() =>
      _TypingIndicatorSubtitleCompState();
}

class _TypingIndicatorSubtitleCompState
    extends State<TypingIndicatorSubtitleComp> {
  List<GroupMember> _groupMembers = [];

  late StreamSubscription<List<(Contact, GroupMember)>> membersSub;

  late Timer _periodicUpdate;

  @override
  void initState() {
    super.initState();

    _periodicUpdate = Timer.periodic(const Duration(seconds: 1), (_) {
      filterOpenUsers(_groupMembers);
    });

    final membersStream = twonlyDB.groupsDao.watchGroupMembers(
      widget.groupId,
    );
    membersSub = membersStream.listen((update) {
      filterOpenUsers(update.map((m) => m.$2).toList());
    });
  }

  void filterOpenUsers(List<GroupMember> input) {
    if (mounted) {
      setState(() {
        _groupMembers = input.where(isTyping).toList();
      });
    }
  }

  @override
  void dispose() {
    membersSub.cancel();
    _periodicUpdate.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_groupMembers.isEmpty) return Container();
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: getMessageColor(true),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Transform.scale(
          scale: 0.6,
          child: const AnimatedTypingDots(
            isTyping: true,
          ),
        ),
      ),
    );
  }
}
