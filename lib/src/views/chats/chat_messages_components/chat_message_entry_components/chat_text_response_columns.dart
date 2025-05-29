import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/views/chats/chat_messages_view.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';

class ChatTextResponseColumns extends StatelessWidget {
  const ChatTextResponseColumns({
    super.key,
    required this.textReactions,
    required this.right,
  });

  final List<Message> textReactions;
  final bool right;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (final reaction in textReactions) {
      MessageContent? content = MessageContent.fromJson(
          reaction.kind, jsonDecode(reaction.contentJson!));

      if (content is TextMessageContent) {
        var entries = [
          FaIcon(
            FontAwesomeIcons.reply,
            size: 10,
          ),
          SizedBox(width: 5),
          Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: Text(
                content.text,
                style: TextStyle(fontSize: 14),
                textAlign: right ? TextAlign.left : TextAlign.right,
              )),
        ];
        if (!right) {
          entries = entries.reversed.toList();
        }

        Color color = getMessageColor(reaction);

        children.insert(
          0,
          Container(
            padding: EdgeInsets.only(top: 5, bottom: 0, right: 10, left: 10),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: EdgeInsets.symmetric(vertical: 1, horizontal: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: entries,
              ),
            ),
          ),
        );
      }
    }

    if (children.isEmpty) return Container();

    return Column(
      crossAxisAlignment:
          right ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: children,
    );
  }
}
