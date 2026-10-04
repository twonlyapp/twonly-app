import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';

class ChatUnknownEntry extends StatelessWidget {
  const ChatUnknownEntry({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
      ),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 10),
      decoration: BoxDecoration(
        color: context.appColor(AppColor.chatBubbleDeleted),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BetterText(
        text: context.lang.updateTwonlyMessage,
        textColor: context.appColor(AppColor.onChatBubbleDeleted),
      ),
    );
  }
}
