import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';

class ChatTextResponseColumns extends StatelessWidget {
  const ChatTextResponseColumns({
    required this.textReactions,
    required this.right,
    super.key,
  });

  final List<Message> textReactions;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final reaction in textReactions) {
      final content = MessageContent.fromJson(
          reaction.kind, jsonDecode(reaction.contentJson!) as Map);

      if (content is TextMessageContent) {
        var entries = [
          const FaIcon(
            FontAwesomeIcons.reply,
            size: 10,
          ),
          const SizedBox(width: 5),
          Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: Text(
                content.text,
                style: const TextStyle(fontSize: 14),
                textAlign: right ? TextAlign.right : TextAlign.left,
              )),
        ];
        if (right) {
          entries = entries.reversed.toList();
        }

        final color = getMessageColor(reaction);

        children.insert(
          0,
          Container(
            padding: const EdgeInsets.only(top: 5, right: 10, left: 10),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
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
          right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: children,
    );
  }
}
