import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/better_text.dart';

class ChatTextEntry extends StatelessWidget {
  const ChatTextEntry({
    required this.message,
    super.key,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    final text = message.content ?? '';
    if (EmojiAnimation.supported(text)) {
      return Container(
        constraints: const BoxConstraints(
          maxWidth: 100,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 10,
        ),
        child: EmojiAnimation(emoji: text),
      );
    }
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color:
            message.quotesMessageId == null ? getMessageColor(message) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BetterText(text: text),
    );
  }
}
