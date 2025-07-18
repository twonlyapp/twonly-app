import 'package:flutter/material.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/better_text.dart';

class ChatTextEntry extends StatelessWidget {
  const ChatTextEntry({
    required this.message,
    required this.text,
    required this.hasReaction,
    super.key,
  });

  final String text;
  final ChatMessage message;
  final bool hasReaction;

  @override
  Widget build(BuildContext context) {
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
      padding: EdgeInsets.only(
          left: 10, top: 4, bottom: 4, right: hasReaction ? 30 : 10),
      decoration: BoxDecoration(
        color: message.responseTo == null
            ? getMessageColor(message.message)
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BetterText(text: text),
    );
  }
}
