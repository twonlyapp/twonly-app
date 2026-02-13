import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/better_text.dart';

class ChatUnknownEntry extends StatelessWidget {
  const ChatUnknownEntry({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 10),
      decoration: BoxDecoration(
        color: isDarkMode(context) ? Colors.black : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BetterText(
        text: context.lang.updateTwonlyMessage,
        textColor: isDarkMode(context)
            ? const Color.fromARGB(255, 99, 99, 99)
            : Colors.black,
      ),
    );
  }
}
