import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/chats/chat_messages_components/bottom_sheets/all_reactions.bottom_sheet.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

class ReactionRow extends StatelessWidget {
  const ReactionRow({
    required this.reactions,
    required this.message,
    super.key,
  });

  final List<Reaction> reactions;
  final Message message;

  Future<void> _showReactionMenu(BuildContext context) async {
    // ignore: inference_failure_on_function_invocation
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return AllReactionsView(
          message: message,
        );
      },
    );
    // if (layer == null) return;
  }

  @override
  Widget build(BuildContext context) {
    final emojis = <String, (Widget, int)>{};
    for (final reaction in reactions) {
      late Widget child;
      if (EmojiAnimation.animatedIcons.containsKey(reaction.emoji)) {
        child = SizedBox(
          height: 18,
          child: EmojiAnimation(emoji: reaction.emoji),
        );
      } else {
        child = SizedBox(
          height: 18,
          child: Center(
            child: Text(
              reaction.emoji,
              style: const TextStyle(fontSize: 18),
              strutStyle: const StrutStyle(
                forceStrutHeight: true,
                height: 1.6,
              ),
            ),
          ),
        );
      }
      if (emojis.containsKey(reaction.emoji)) {
        emojis[reaction.emoji] =
            (emojis[reaction.emoji]!.$1, emojis[reaction.emoji]!.$2 + 1);
      } else {
        emojis[reaction.emoji] = (child, 1);
      }
    }

    if (emojis.isEmpty) return Container();

    var emojisToShow = emojis.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    if (emojisToShow.length > 4) {
      emojisToShow = emojisToShow.slice(0, 3).toList()
        ..add(
          (
            SizedBox(
              height: 18,
              child: Transform.translate(
                offset: const Offset(0, -3),
                child: const FaIcon(FontAwesomeIcons.ellipsis),
              ),
            ),
            1
          ),
        );
    }

    return GestureDetector(
      onTap: () => _showReactionMenu(context),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(bottom: 20, top: 5),
        child: Row(
          mainAxisAlignment: message.senderId == null
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: emojisToShow.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
                color: const Color.fromARGB(255, 74, 74, 74),
              ),
              child: Row(
                children: [
                  entry.$1,
                  if (entry.$2 > 1)
                    SizedBox(
                      height: 19,
                      child: Text(
                        entry.$2.toString(),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
