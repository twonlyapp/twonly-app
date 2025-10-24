import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/chats/media_viewer_components/emoji_reactions_row.component.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

class ReactionButtons extends StatefulWidget {
  const ReactionButtons({
    required this.show,
    required this.textInputFocused,
    required this.mediaViewerDistanceFromBottom,
    required this.messageId,
    required this.groupId,
    required this.hide,
    super.key,
  });

  final double mediaViewerDistanceFromBottom;
  final bool show;
  final bool textInputFocused;
  final String messageId;
  final String groupId;
  final void Function() hide;

  @override
  State<ReactionButtons> createState() => _ReactionButtonsState();
}

class _ReactionButtonsState extends State<ReactionButtons> {
  int selectedShortReaction = -1;

  List<String> selectedEmojis =
      EmojiAnimation.animatedIcons.keys.toList().sublist(0, 6);

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    final user = await getUser();
    if (user != null && user.preSelectedEmojies != null) {
      selectedEmojis = user.preSelectedEmojies!;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final firstRowEmojis = selectedEmojis.take(6).toList();
    final secondRowEmojis =
        selectedEmojis.length > 6 ? selectedEmojis.skip(6).toList() : [];

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200), // Animation duration
      bottom: widget.show
          ? (widget.textInputFocused
              ? 50
              : widget.mediaViewerDistanceFromBottom)
          : widget.mediaViewerDistanceFromBottom - 20,
      left: widget.show ? 0 : MediaQuery.sizeOf(context).width / 2,
      right: widget.show ? 0 : MediaQuery.sizeOf(context).width / 2,
      curve: Curves.linearToEaseOut,
      child: AnimatedOpacity(
        opacity: widget.show ? 1.0 : 0.0, // Fade in/out
        duration: const Duration(milliseconds: 150),
        child: Container(
          color: widget.show ? Colors.black.withAlpha(0) : Colors.transparent,
          padding:
              widget.show ? const EdgeInsets.symmetric(vertical: 32) : null,
          child: Column(
            children: [
              if (secondRowEmojis.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: secondRowEmojis
                      .map(
                        (emoji) => EmojiReactionWidget(
                          messageId: widget.messageId,
                          groupId: widget.groupId,
                          hide: widget.hide,
                          show: widget.show,
                          emoji: emoji as String,
                        ),
                      )
                      .toList(),
                ),
              if (secondRowEmojis.isNotEmpty) const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: firstRowEmojis
                    .map(
                      (emoji) => EmojiReactionWidget(
                        messageId: widget.messageId,
                        groupId: widget.groupId,
                        hide: widget.hide,
                        show: widget.show,
                        emoji: emoji,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
