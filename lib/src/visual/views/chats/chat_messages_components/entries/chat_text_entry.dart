import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';

class ChatTextEntry extends StatelessWidget {
  const ChatTextEntry({
    required this.message,
    required this.nextMessage,
    required this.prevMessage,
    required this.borderRadius,
    required this.userIdToContact,
    required this.minWidth,
    super.key,
  });

  final Message message;
  final Message? nextMessage;
  final Message? prevMessage;
  final Map<int, Contact>? userIdToContact;
  final BorderRadius borderRadius;
  final double minWidth;

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

    final info = getBubbleInfo(
      context,
      message,
      nextMessage,
      prevMessage,
      userIdToContact,
      minWidth,
    );

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
        minWidth: minWidth,
      ),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 10),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.displayUserName != '')
            Text(
              info.displayUserName,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (info.expanded)
                Expanded(
                  child: BetterText(text: info.text, textColor: info.textColor),
                )
              else ...[
                BetterText(text: info.text, textColor: info.textColor),
                SizedBox(
                  width: info.spacerWidth,
                ),
              ],
              if (info.displayTime || message.modifiedAt != null)
                FriendlyMessageTime(message: message),
            ],
          ),
        ],
      ),
    );
  }
}
