import 'package:flutter/material.dart';
import 'package:twonly/src/components/animate_icon.dart';
import 'package:twonly/src/database/database.dart';

class FlameCounterWidget extends StatelessWidget {
  final Contact user;
  final int maxTotalMediaCounter;
  final int flameCounter;
  final bool prefix;

  const FlameCounterWidget(
    this.user,
    this.flameCounter,
    this.maxTotalMediaCounter, {
    this.prefix = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (prefix) const SizedBox(width: 5),
        if (prefix) Text("•"),
        if (prefix) const SizedBox(width: 5),
        Text(
          flameCounter.toString(),
          style: const TextStyle(fontSize: 13),
        ),
        SizedBox(
          height: 15,
          child: EmojiAnimation(
              emoji: (maxTotalMediaCounter == user.totalMediaCounter)
                  ? "❤️‍🔥"
                  : "🔥"),
        ),
      ],
    );
  }
}
