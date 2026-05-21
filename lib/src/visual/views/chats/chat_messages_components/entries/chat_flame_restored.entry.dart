import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';

import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

class ChatFlameRestoredEntry extends StatelessWidget {
  const ChatFlameRestoredEntry({
    required this.message,
    required this.borderRadius,
    required this.info,
    super.key,
  });

  final Message message;
  final BorderRadiusGeometry borderRadius;
  final BubbleInfo info;

  @override
  Widget build(BuildContext context) {
    AdditionalMessageData? data;

    if (message.additionalMessageData != null) {
      try {
        data = AdditionalMessageData.fromBuffer(
          message.additionalMessageData!,
        );
      } catch (e) {
        data = null;
      }
    }

    if (data == null || !data.hasRestoredFlameCounter()) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: EmojiAnimationComp(emoji: '🔥'),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: BetterText(
              text: context.lang.chatEntryFlameRestored(
                data.restoredFlameCounter.toInt(),
              ),
              textColor: isDarkMode(context) ? Colors.black : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
