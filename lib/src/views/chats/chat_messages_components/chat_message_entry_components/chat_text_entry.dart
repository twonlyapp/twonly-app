import 'package:flutter/material.dart';
import 'package:twonly/src/views/chats/chat_messages_view.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/better_text.dart';
import 'package:twonly/src/database/twonly_database.dart';

class ChatTextEntry extends StatelessWidget {
  const ChatTextEntry({super.key, required this.message, required this.text});

  final String text;
  final Message message;

  @override
  Widget build(BuildContext context) {
    if (EmojiAnimation.supported(text)) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: 100,
        ),
        padding: EdgeInsets.symmetric(
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
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: getMessageColor(message),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: BetterText(text: text),
    );
  }
}
