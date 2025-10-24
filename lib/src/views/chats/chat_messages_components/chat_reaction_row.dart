import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

class ReactionRow extends StatefulWidget {
  const ReactionRow({
    required this.message,
    super.key,
  });

  final Message message;

  @override
  State<ReactionRow> createState() => _ReactionRowState();
}

class _ReactionRowState extends State<ReactionRow> {
  List<Reaction> reactions = [];
  StreamSubscription<List<Reaction>>? reactionsSub;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  @override
  void dispose() {
    reactionsSub?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    final stream =
        twonlyDB.reactionsDao.watchReactions(widget.message.messageId);

    reactionsSub = stream.listen((update) {
      setState(() {
        reactions = update;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final reaction in reactions) {
      // if (content is ReopenedMediaFileContent) {
      //   if (hasOneReopened) continue;
      //   hasOneReopened = true;
      //   children.add(
      //     Expanded(
      //       child: Align(
      //         alignment: Alignment.bottomRight,
      //         child: Padding(
      //           padding: const EdgeInsets.only(right: 3),
      //           child: FaIcon(
      //             FontAwesomeIcons.repeat,
      //             size: 12,
      //             color: isDarkMode(context) ? Colors.white : Colors.black,
      //           ),
      //         ),
      //       ),
      //     ),
      //   );
      // }
      // only show one reaction

      late Widget child;
      if (EmojiAnimation.animatedIcons.containsKey(reaction.emoji)) {
        child = SizedBox(
          height: 18,
          child: EmojiAnimation(emoji: reaction.emoji),
        );
      } else {
        child = Text(reaction.emoji, style: const TextStyle(fontSize: 14));
      }
      children.insert(
        0,
        Padding(
          padding: const EdgeInsets.only(left: 3),
          child: child,
        ),
      );
    }

    if (children.isEmpty) return Container();

    return Row(
      mainAxisAlignment: widget.message.senderId == null
          ? MainAxisAlignment.end
          : MainAxisAlignment.end,
      children: children,
    );
  }
}
