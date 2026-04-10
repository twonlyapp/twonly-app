import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({required this.group, super.key});

  final Group group;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

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
      widget.group.groupId,
    );
    membersSub = membersStream.listen((update) {
      filterOpenUsers(update.map((m) => m.$2).toList());
    });

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _animations = List.generate(3, (index) {
      final start = index * 0.2;
      final end = start + 0.6;

      return TweenSequence<double>([
        // First half: Animate from 0.5 to 1.0
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.5,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50,
        ),
        // Second half: Animate back from 1.0 to 0.5
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1,
            end: 0.5,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end),
        ),
      );
    });
  }

  void filterOpenUsers(List<GroupMember> input) {
    setState(() {
      _groupMembers = input.where(hasChatOpen).toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    membersSub.cancel();
    _periodicUpdate.cancel();
    super.dispose();
  }

  bool isTyping(GroupMember member) {
    return member.lastTypeIndicator != null &&
        DateTime.now()
                .difference(
                  member.lastTypeIndicator!,
                )
                .inSeconds <=
            12;
  }

  bool hasChatOpen(GroupMember member) {
    return member.lastChatOpened != null &&
        DateTime.now()
                .difference(
                  member.lastChatOpened!,
                )
                .inSeconds <=
            12;
  }

  @override
  Widget build(BuildContext context) {
    if (_groupMembers.isEmpty) return Container();

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: _groupMembers
              .map(
                (member) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.group.isDirectChat)
                        GestureDetector(
                          onTap: () => context.push(
                            Routes.profileContact(member.contactId),
                          ),
                          child: AvatarIcon(
                            contactId: member.contactId,
                            fontSize: 12,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: getMessageColor(true),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (index) => _AnimatedDot(
                              isTyping: isTyping(member),
                              animation: _animations[index],
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _AnimatedDot extends AnimatedWidget {
  const _AnimatedDot({
    required this.isTyping,
    required Animation<double> animation,
  }) : super(listenable: animation);

  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Opacity(
        opacity: isTyping ? animation.value : 0.5,
        child: Transform.scale(
          scale: isTyping ? 1 + (0.5 * animation.value) : 1,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
