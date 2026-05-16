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

    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = measureTextWidth(info.text);
        const timeWidth = 60.0;
        final isExpanded =
            info.expanded ||
            (textWidth + timeWidth + 20 > constraints.maxWidth);
        final effectiveSpacerWidth =
            constraints.minWidth - textWidth - timeWidth;
        final spacerWidth = effectiveSpacerWidth > 0
            ? effectiveSpacerWidth
            : 0.0;

        return Container(
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
                  if (isExpanded)
                    Expanded(
                      child: BetterText(
                        text: info.text,
                        textColor: info.textColor,
                      ),
                    )
                  else ...[
                    BetterText(text: info.text, textColor: info.textColor),
                    SizedBox(
                      width: spacerWidth,
                    ),
                  ],
                  if (info.displayTime || message.modifiedAt != null)
                    FriendlyMessageTime(message: message),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
