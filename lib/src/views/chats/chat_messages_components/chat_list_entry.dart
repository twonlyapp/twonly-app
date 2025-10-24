import 'package:flutter/material.dart';
import 'package:twonly/src/database/tables/messages.table.dart'
    hide MessageActions;
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_media_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_reaction_row.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_text_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_actions.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_context_menu.dart';
import 'package:twonly/src/views/chats/chat_messages_components/response_container.dart';

class ChatListEntry extends StatefulWidget {
  const ChatListEntry(
    this.message,
    this.group,
    this.galleryItems,
    this.lastMessageFromSameUser, {
    required this.onResponseTriggered,
    required this.scrollToMessage,
    super.key,
  });
  final Message message;
  final Group group;
  final bool lastMessageFromSameUser;
  final List<MemoryItem> galleryItems;
  final void Function(String) scrollToMessage;
  final void Function() onResponseTriggered;

  @override
  State<ChatListEntry> createState() => _ChatListEntryState();
}

class _ChatListEntryState extends State<ChatListEntry> {
  MediaFileService? mediaService;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    mediaService = await MediaFileService.fromMediaId(widget.message.messageId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final right = widget.message.senderId == null;

    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: widget.lastMessageFromSameUser
            ? const EdgeInsets.only(top: 5, right: 10, left: 10)
            : const EdgeInsets.only(top: 5, bottom: 20, right: 10, left: 10),
        child: MessageContextMenu(
          message: widget.message,
          onResponseTriggered: widget.onResponseTriggered,
          child: Column(
            mainAxisAlignment:
                right ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment:
                right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              MessageActions(
                message: widget.message,
                onResponseTriggered: widget.onResponseTriggered,
                child: Stack(
                  alignment:
                      right ? Alignment.centerRight : Alignment.centerLeft,
                  children: [
                    ResponseContainer(
                      msg: widget.message,
                      group: widget.group,
                      mediaService: mediaService,
                      scrollToMessage: widget.scrollToMessage,
                      child: (widget.message.type == MessageType.text)
                          ? ChatTextEntry(
                              message: widget.message,
                            )
                          : (mediaService == null)
                              ? null
                              : ChatMediaEntry(
                                  message: widget.message,
                                  group: widget.group,
                                  mediaService: mediaService!,
                                  galleryItems: widget.galleryItems,
                                ),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 5,
                      right: 5,
                      child: ReactionRow(
                        message: widget.message,
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
