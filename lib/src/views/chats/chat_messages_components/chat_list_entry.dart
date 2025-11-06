import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart'
    hide MessageActions;
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_reaction_row.dart';
import 'package:twonly/src/views/chats/chat_messages_components/entries/chat_audio_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/entries/chat_media_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/entries/chat_text_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_actions.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_context_menu.dart';
import 'package:twonly/src/views/chats/chat_messages_components/response_container.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/contact/contact.view.dart';

class ChatListEntry extends StatefulWidget {
  const ChatListEntry({
    required this.group,
    required this.message,
    this.galleryItems = const [],
    this.scrollToMessage,
    this.onResponseTriggered,
    this.prevMessage,
    this.nextMessage,
    this.userIdToContact,
    this.hideReactions = false,
    super.key,
  });
  final Message? prevMessage;
  final Message? nextMessage;
  final Message message;
  final Group group;
  final Map<int, Contact>? userIdToContact;
  final bool hideReactions;
  final List<MemoryItem> galleryItems;
  final void Function(String)? scrollToMessage;
  final void Function()? onResponseTriggered;

  @override
  State<ChatListEntry> createState() => _ChatListEntryState();
}

class _ChatListEntryState extends State<ChatListEntry> {
  MediaFileService? mediaService;

  List<Reaction> reactions = [];
  StreamSubscription<List<Reaction>>? reactionsSub;

  StreamSubscription<MediaFile?>? mediaFileSub;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  @override
  void dispose() {
    mediaFileSub?.cancel();
    reactionsSub?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    if (widget.message.mediaId != null) {
      final mediaFileStream =
          twonlyDB.mediaFilesDao.watchMedia(widget.message.mediaId!);
      mediaFileSub = mediaFileStream.listen((mediaFiles) async {
        if (mediaFiles != null) {
          mediaService = await MediaFileService.fromMedia(mediaFiles);
          if (mounted) setState(() {});
        }
      });
    }
    final stream =
        twonlyDB.reactionsDao.watchReactions(widget.message.messageId);

    reactionsSub = stream.listen((update) {
      setState(() {
        reactions = update;
      });
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final right = widget.message.senderId == null;

    final (padding, borderRadius, hideContactAvatar) = getMessageLayout(
      widget.message,
      widget.prevMessage,
      widget.nextMessage,
      reactions.isNotEmpty,
    );

    final seen = <String>{};
    var reactionsForWidth =
        reactions.where((t) => seen.add(t.emoji)).toList().length;
    if (reactionsForWidth > 4) reactionsForWidth = 4;

    Widget child = Stack(
      // overflow: Overflow.visible,
      // clipBehavior: Clip.none,
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      children: [
        if (widget.message.isDeletedFromSender)
          ChatTextEntry(
            message: widget.message,
            nextMessage: widget.nextMessage,
            prevMessage: widget.prevMessage,
            userIdToContact: widget.userIdToContact,
            borderRadius: borderRadius,
            minWidth: reactionsForWidth * 43,
          )
        else
          Column(
            children: [
              ResponseContainer(
                msg: widget.message,
                group: widget.group,
                mediaService: mediaService,
                borderRadius: borderRadius,
                scrollToMessage: widget.scrollToMessage,
                child: (widget.message.type == MessageType.text)
                    ? ChatTextEntry(
                        message: widget.message,
                        nextMessage: widget.nextMessage,
                        prevMessage: widget.prevMessage,
                        userIdToContact: widget.userIdToContact,
                        borderRadius: borderRadius,
                        minWidth: reactionsForWidth * 43,
                      )
                    : (mediaService == null)
                        ? null
                        : (mediaService!.mediaFile.type == MediaType.audio)
                            ? ChatAudioEntry(
                                message: widget.message,
                                nextMessage: widget.nextMessage,
                                prevMessage: widget.prevMessage,
                                mediaService: mediaService!,
                                userIdToContact: widget.userIdToContact,
                                borderRadius: borderRadius,
                                minWidth: reactionsForWidth * 43,
                              )
                            : ChatMediaEntry(
                                message: widget.message,
                                group: widget.group,
                                mediaService: mediaService!,
                                galleryItems: widget.galleryItems,
                                minWidth: reactionsForWidth * 43,
                              ),
              ),
              if (reactionsForWidth > 0) const SizedBox(height: 20, width: 10),
            ],
          ),
        if (!widget.message.isDeletedFromSender && !widget.hideReactions)
          Positioned(
            bottom: -20,
            left: 5,
            right: 5,
            child: ReactionRow(
              message: widget.message,
              reactions: reactions,
            ),
          ),
      ],
    );

    if (widget.onResponseTriggered != null) {
      child = MessageActions(
        message: widget.message,
        onResponseTriggered: widget.onResponseTriggered!,
        child: child,
      );

      child = MessageContextMenu(
        message: widget.message,
        group: widget.group,
        onResponseTriggered: widget.onResponseTriggered!,
        galleryItems: widget.galleryItems,
        child: Container(
          child: child,
        ),
      );
    }

    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisAlignment:
              right ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!right && !widget.group.isDirectChat)
              hideContactAvatar
                  ? const SizedBox(width: 24)
                  : GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ContactView(widget.message.senderId!),
                          ),
                        );
                      },
                      child: AvatarIcon(
                        contactId: widget.message.senderId,
                        fontSize: 12,
                      ),
                    ),
            child,
          ],
        ),
      ),
    );
  }
}

(EdgeInsetsGeometry, BorderRadius, bool) getMessageLayout(
  Message message,
  Message? prevMessage,
  Message? nextMessage,
  bool hasReactions,
) {
  var bottom = 10.0;
  var top = 10.0;
  var hideContactAvatar = false;

  var topLeft = 12.0;
  var topRight = 12.0;
  var bottomRight = 12.0;
  var bottomLeft = 12.0;

  if (nextMessage != null) {
    if (message.senderId == nextMessage.senderId) {
      bottom = 3;
    }
  }

  if (prevMessage != null) {
    final combinesWidthNext = combineTextMessageWithNext(prevMessage, message);
    if (combinesWidthNext) {
      top = 1;
      topLeft = 5.0;
    }
  }

  final combinesWidthNext = combineTextMessageWithNext(message, nextMessage);
  if (combinesWidthNext) {
    bottom = 0;
    bottomLeft = 5.0;
    hideContactAvatar = true;
  }

  if (message.senderId == null) {
    final tmp = topLeft;
    topLeft = topRight;
    topRight = tmp;

    final tmp2 = bottomLeft;
    bottomLeft = bottomRight;
    bottomRight = tmp2;
    hideContactAvatar = true;
  }

  return (
    EdgeInsets.only(top: top, bottom: bottom, right: 10, left: 10),
    BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomRight: Radius.circular(bottomRight),
      bottomLeft: Radius.circular(bottomLeft),
    ),
    hideContactAvatar
  );
}
