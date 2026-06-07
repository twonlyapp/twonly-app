import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';

class ChatTextEntry extends StatelessWidget {
  const ChatTextEntry({
    required this.message,
    required this.borderRadius,
    required this.info,
    super.key,
  });

  final Message message;
  final BorderRadius borderRadius;
  final BubbleInfo info;

  @override
  Widget build(BuildContext context) {
    final text = message.content ?? '';

    if (EmojiAnimationComp.supported(text)) {
      return Container(
        constraints: const BoxConstraints(
          maxWidth: 100,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 10,
        ),
        child: EmojiAnimationComp(emoji: text),
      );
    }

    final showTime = info.displayTime || message.modifiedAt != null;

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minWidth: info.minWidth,
        ),
        padding: info.padding,
        decoration: BoxDecoration(
          color: info.color,
          borderRadius: borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info.displayUserName != '')
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  info.displayUserName,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: BetterText(
                    text: info.text,
                    textColor: info.textColor,
                  ),
                ),
                if (showTime) FriendlyMessageTime(message: message),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
