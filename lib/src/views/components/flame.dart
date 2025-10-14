import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

class FlameCounterWidget extends StatelessWidget {
  const FlameCounterWidget(
    this.user,
    this.flameCounter, {
    this.prefix = false,
    super.key,
  });
  final Contact user;
  final int flameCounter;
  final bool prefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (prefix) const SizedBox(width: 5),
        if (prefix) const Text('•'),
        if (prefix) const SizedBox(width: 5),
        Text(
          flameCounter.toString(),
          style: const TextStyle(fontSize: 13),
        ),
        SizedBox(
          height: 15,
          child: EmojiAnimation(
            emoji: (globalBestFriendUserId == user.userId) ? '❤️‍🔥' : '🔥',
          ),
        ),
      ],
    );
  }
}
