import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';

class ReactionRow extends StatefulWidget {
  const ReactionRow({
    super.key,
    required this.otherReactions,
    required this.message,
  });

  final List<Message> otherReactions;
  final Message message;

  @override
  State<ReactionRow> createState() => _ReactionRowState();
}

class _ReactionRowState extends State<ReactionRow> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    bool hasOneTextReaction = false;
    bool hasOneReopened = false;
    for (final reaction in widget.otherReactions) {
      MessageContent? content = MessageContent.fromJson(
          reaction.kind, jsonDecode(reaction.contentJson!));

      if (content is ReopenedMediaFileContent) {
        if (hasOneReopened) continue;
        hasOneReopened = true;
        children.add(
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(right: 3),
                child: FaIcon(
                  FontAwesomeIcons.repeat,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }
      // only show one reaction
      if (hasOneTextReaction) continue;

      if (content is TextMessageContent) {
        hasOneTextReaction = true;
        if (!isEmoji(content.text)) continue;
        late Widget child;
        if (EmojiAnimation.animatedIcons.containsKey(content.text)) {
          child = SizedBox(
            height: 18,
            child: EmojiAnimation(emoji: content.text),
          );
        } else {
          child = Text(content.text, style: TextStyle(fontSize: 14));
        }
        children.insert(
          0,
          Padding(
            padding: EdgeInsets.only(left: 3),
            child: child,
          ),
        );
      }
    }

    if (children.isEmpty) return Container();

    return Row(
      mainAxisAlignment: widget.message.messageOtherId == null
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: children,
    );
  }
}
