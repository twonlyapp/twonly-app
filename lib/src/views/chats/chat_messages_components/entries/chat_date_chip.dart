import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';

class ChatDateChip extends StatelessWidget {
  const ChatDateChip({required this.item, super.key});
  final ChatItem item;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${DateFormat.Hm(Localizations.localeOf(context).toLanguageTag()).format(item.date!)}\n${DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(item.date!)}';

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode(context)
              ? const Color.fromARGB(255, 38, 38, 38)
              : Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 20),
        child: Text(
          formattedDate,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode(context) ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
