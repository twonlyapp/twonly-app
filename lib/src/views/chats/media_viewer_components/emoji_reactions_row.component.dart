// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

class EmojiReactionWidget extends StatefulWidget {
  const EmojiReactionWidget({
    required this.messageId,
    required this.groupId,
    required this.hide,
    required this.show,
    required this.emoji,
    super.key,
  });
  final String messageId;
  final String groupId;
  final Function hide;
  final bool show;
  final String emoji;

  @override
  State<EmojiReactionWidget> createState() => _EmojiReactionWidgetState();
}

class _EmojiReactionWidgetState extends State<EmojiReactionWidget> {
  int selectedShortReaction = -1;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linearToEaseOut,
      child: GestureDetector(
        onTap: () async {
          await twonlyDB.reactionsDao
              .updateMyReaction(widget.messageId, widget.emoji);

          await sendCipherTextToGroup(
            widget.groupId,
            EncryptedContent(
              reaction: EncryptedContent_Reaction(
                targetMessageId: widget.messageId,
                emoji: widget.emoji,
              ),
            ),
            null,
          );

          setState(() {
            selectedShortReaction = 0; // Assuming index is 0 for this example
          });
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                widget.hide();
                selectedShortReaction = -1;
              });
            }
          });
        },
        child: (selectedShortReaction ==
                0) // Assuming index is 0 for this example
            ? EmojiAnimationFlying(
                emoji: widget.emoji,
                duration: const Duration(milliseconds: 300),
                startPosition: 0,
                size: (widget.show) ? 40 : 10,
              )
            : AnimatedOpacity(
                opacity: (selectedShortReaction == -1) ? 1 : 0, // Fade in/out
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  width: widget.show ? 40 : 10,
                  child: Center(
                    child: EmojiAnimation(
                      emoji: widget.emoji,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
