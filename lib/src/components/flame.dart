import 'package:flutter/material.dart';
import 'package:twonly/src/model/contacts_model.dart';

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
        Text(
          (maxTotalMediaCounter == user.totalMediaCounter) ? "❤️‍🔥" : "🔥",
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
