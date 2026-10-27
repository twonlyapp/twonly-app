import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/typing_indicator.dart';

class TypingIndicatorSubtitleComp extends StatefulWidget {
  const TypingIndicatorSubtitleComp({
    required this.groupId,
    this.isTyping,
    super.key,
  });

  final String groupId;
  final bool? isTyping;

  @override
  State<TypingIndicatorSubtitleComp> createState() =>
      _TypingIndicatorSubtitleCompState();
}

class _TypingIndicatorSubtitleCompState
    extends State<TypingIndicatorSubtitleComp> {
  List<GroupMember> _groupMembers = [];

  StreamSubscription<List<(Contact, GroupMember)>>? membersSub;

  Timer? _periodicUpdate;

  @override
  void initState() {
    super.initState();

    if (widget.isTyping != null) return;

    final membersStream = watchRustDatabase(
      (control) => rust_groups
          .watchGroupContacts(
            input: db_groups.GroupMembersQuery(
              groupId: widget.groupId,
            ),
            control: control,
          )
          .map(joinedGroupContacts),
    );
    membersSub = membersStream.listen((update) {
      filterOpenUsers(update.map((m) => m.$2).toList());
    });
  }

  void filterOpenUsers(List<GroupMember> input) {
    if (!mounted) return;

    final typingMembers = input.where(isTyping).toList();

    if (typingMembers.isEmpty) {
      _periodicUpdate?.cancel();
      _periodicUpdate = null;
    } else {
      _periodicUpdate ??= Timer.periodic(const Duration(seconds: 1), (_) {
        filterOpenUsers(_groupMembers);
      });
    }

    setState(() {
      _groupMembers = typingMembers;
    });
  }

  @override
  void dispose() {
    membersSub?.cancel();
    _periodicUpdate?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTyping ?? _groupMembers.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: getMessageColor(context, true),
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
    return Container();
  }
}
