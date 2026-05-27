import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';

class ChatDateChip extends StatelessWidget {
  const ChatDateChip({required this.item, super.key});
  final ChatItem item;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date = item.date!;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDay = DateTime(date.year, date.month, date.day);

    String formattedDate;
    if (itemDay == today) {
      formattedDate = context.lang.today;
    } else if (itemDay == yesterday) {
      formattedDate = context.lang.yesterday;
    } else if (date.year == now.year) {
      formattedDate = DateFormat('E, d. MMM.', locale).format(date);
    } else {
      formattedDate = DateFormat('E, d. MMM. y', locale).format(date);
    }

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
