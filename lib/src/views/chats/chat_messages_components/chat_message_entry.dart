import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_media_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_reaction_row.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_text_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_text_response_columns.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_actions.dart';

class ChatListEntry extends StatefulWidget {
  const ChatListEntry(
    this.message,
    this.contact,
    this.galleryItems,
    this.lastMessageFromSameUser,
    this.textReactions,
    this.otherReactions, {
    required this.onResponseTriggered,
    super.key,
  });
  final Message message;
  final Contact contact;
  final bool lastMessageFromSameUser;
  final List<Message> textReactions;
  final List<Message> otherReactions;
  final List<MemoryItem> galleryItems;
  final void Function(Message) onResponseTriggered;

  @override
  State<ChatListEntry> createState() => _ChatListEntryState();
}

class _ChatListEntryState extends State<ChatListEntry> {
  MessageContent? content;
  String? textMessage;

  @override
  void initState() {
    super.initState();
    final msgContent = MessageContent.fromJson(
        widget.message.kind, jsonDecode(widget.message.contentJson!) as Map);
    if (msgContent is TextMessageContent) {
      textMessage = msgContent.text;
    }
    content = msgContent;
  }

  @override
  Widget build(BuildContext context) {
    if (content == null) return Container();
    final right = widget.message.messageOtherId == null;

    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: widget.lastMessageFromSameUser
            ? const EdgeInsets.only(top: 5, right: 10, left: 10)
            : const EdgeInsets.only(top: 5, bottom: 20, right: 10, left: 10),
        child: Column(
          mainAxisAlignment:
              right ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment:
              right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            MessageActions(
              message: widget.message,
              child: Stack(
                alignment: right ? Alignment.centerRight : Alignment.centerLeft,
                children: [
                  if (textMessage != null)
                    ChatTextEntry(
                      message: widget.message,
                      text: textMessage!,
                    )
                  else
                    ChatMediaEntry(
                      message: widget.message,
                      contact: widget.contact,
                      galleryItems: widget.galleryItems,
                      content: content!,
                    ),
                  Positioned(
                    bottom: 5,
                    left: 5,
                    right: 5,
                    child: ReactionRow(
                      otherReactions: widget.otherReactions,
                      message: widget.message,
                    ),
                  ),
                ],
              ),
              onResponseTriggered: () {
                widget.onResponseTriggered(widget.message);
              },
            ),
            ChatTextResponseColumns(
              textReactions: widget.textReactions,
              right: right,
            )
          ],
        ),
      ),
    );
  }
}
