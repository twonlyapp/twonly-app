import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';

class ChatDateChip extends StatelessWidget {
  const ChatDateChip({required this.item, super.key});
  final ChatItem item;

  @override
  Widget build(BuildContext context) {
    var formattedDate = item.isTime
        ? DateFormat.Hm(Localizations.localeOf(context).toLanguageTag())
            .format(item.time!)
        : '${DateFormat.Hm(Localizations.localeOf(context).toLanguageTag()).format(item.date!)} ${DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(item.date!)}';

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Text(
          formattedDate,
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode(context) ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
