import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/views/chats/media_viewer_components/reaction_buttons.component.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

Offset getGlobalOffset(GlobalKey targetKey) {
  final ctx = targetKey.currentContext;
  if (ctx == null) {
    return Offset.zero;
  }
  final renderObject = ctx.findRenderObject();
  if (renderObject is RenderBox) {
    return renderObject.localToGlobal(
      Offset(renderObject.size.width / 2, renderObject.size.height / 2),
    );
  }
  return Offset.zero;
}

Future<void> sendReaction(
  String groupId,
  String messageId,
  String emoji,
) async {
  await twonlyDB.reactionsDao.updateMyReaction(
    messageId,
    emoji,
    false,
  );
  await sendCipherTextToGroup(
    groupId,
    EncryptedContent(
      reaction: EncryptedContent_Reaction(
        targetMessageId: messageId,
        emoji: emoji,
        remove: false,
      ),
    ),
  );
}

class EmojiReactionWidget extends StatefulWidget {
  const EmojiReactionWidget({
    required this.messageId,
    required this.groupId,
    required this.hide,
    required this.show,
    required this.emoji,
    required this.emojiKey,
    super.key,
  });
  final String messageId;
  final String groupId;
  final void Function() hide;
  final bool show;
  final String emoji;
  final GlobalKey<EmojiFloatWidgetState> emojiKey;

  @override
  State<EmojiReactionWidget> createState() => _EmojiReactionWidgetState();
}

class _EmojiReactionWidgetState extends State<EmojiReactionWidget> {
  final GlobalKey _targetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      key: _targetKey,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linearToEaseOut,
      child: GestureDetector(
        onTap: () async {
          await sendReaction(widget.groupId, widget.messageId, widget.emoji);
          widget.emojiKey.currentState?.spawn(
            getGlobalOffset(_targetKey),
            widget.emoji,
          );
          widget.hide();
        },
        child: SizedBox(
          width: widget.show ? 40 : 10,
          child: Center(
            child: EmojiAnimation(
              emoji: widget.emoji,
            ),
          ),
        ),
      ),
    );
  }
}
