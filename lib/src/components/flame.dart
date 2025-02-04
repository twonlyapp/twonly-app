import 'package:flutter/material.dart';
import 'package:twonly/src/model/contacts_model.dart';

class FlameCounterWidget extends StatelessWidget {
  final Contact user;
  final int maxTotalMediaCounter;

  const FlameCounterWidget(
    this.user,
    this.maxTotalMediaCounter, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 5),
        Text("•"),
        const SizedBox(width: 5),
        Text(
          user.flameCounter.toString(),
          style: const TextStyle(fontSize: 13),
        ),
        Text(
          (maxTotalMediaCounter == user.totalMediaCounter) ? "❤️‍🔥" : "🔥",
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
