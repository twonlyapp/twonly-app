import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/message_old.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_media_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_reaction_row.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_text_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_actions.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_context_menu.dart';
import 'package:twonly/src/views/chats/chat_messages_components/response_container.dart';

class ChatListEntry extends StatefulWidget {
  const ChatListEntry(
    this.msg,
    this.contact,
    this.galleryItems,
    this.lastMessageFromSameUser,
    this.otherReactions, {
    required this.onResponseTriggered,
    required this.scrollToMessage,
    super.key,
  });
  final ChatMessage msg;
  final Contact contact;
  final bool lastMessageFromSameUser;
  final List<Message> otherReactions;
  final List<MemoryItem> galleryItems;
  final void Function(int) scrollToMessage;
  final void Function() onResponseTriggered;

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
      widget.msg.message.kind,
      jsonDecode(widget.msg.message.contentJson!) as Map,
    );
    if (msgContent is TextMessageContent) {
      textMessage = msgContent.text;
    }
    content = msgContent;
  }

  @override
  Widget build(BuildContext context) {
    if (content == null) return Container();
    final right = widget.msg.message.messageOtherId == null;

    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: widget.lastMessageFromSameUser
            ? const EdgeInsets.only(top: 5, right: 10, left: 10)
            : const EdgeInsets.only(top: 5, bottom: 20, right: 10, left: 10),
        child: MessageContextMenu(
          message: widget.msg.message,
          onResponseTriggered: widget.onResponseTriggered,
          child: Column(
            mainAxisAlignment:
                right ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment:
                right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              MessageActions(
                message: widget.msg.message,
                onResponseTriggered: widget.onResponseTriggered,
                child: Stack(
                  alignment:
                      right ? Alignment.centerRight : Alignment.centerLeft,
                  children: [
                    ResponseContainer(
                      msg: widget.msg,
                      contact: widget.contact,
                      scrollToMessage: widget.scrollToMessage,
                      child: (textMessage != null)
                          ? ChatTextEntry(
                              message: widget.msg,
                              text: textMessage!,
                              hasReaction: widget.otherReactions.isNotEmpty,
                            )
                          : ChatMediaEntry(
                              message: widget.msg.message,
                              contact: widget.contact,
                              galleryItems: widget.galleryItems,
                              content: content!,
                            ),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 5,
                      right: 5,
                      child: ReactionRow(
                        otherReactions: widget.otherReactions,
                        message: widget.msg.message,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
