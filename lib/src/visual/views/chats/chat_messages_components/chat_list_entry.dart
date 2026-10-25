import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/bridge/database/reactions.dart' as rust_reactions;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/reactions/table.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/services/live_location.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_reaction_row.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_ask_a_friend.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_audio_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_contacts.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_flame_restored.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_live_location.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_media_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_sticker.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_text_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_unknown.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_webxdc.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_webxdc_message.entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_context_menu.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_reply_drag.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/response_container.dart';

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
    this.mediaFile,
    this.reactions,
    this.messagesById,
    this.mediaFilesById,
    this.useSharedData = false,
    super.key,
  });
  final StoredMessage? prevMessage;
  final StoredMessage? nextMessage;
  final StoredMessage message;
  final Group group;
  final Map<int, Contact>? userIdToContact;
  final bool hideReactions;
  final MediaFile? mediaFile;
  final List<StoredReaction>? reactions;
  final Map<String, StoredMessage>? messagesById;
  final Map<String, MediaFile>? mediaFilesById;
  final bool useSharedData;
  final List<MemoryItem> galleryItems;
  final void Function(String)? scrollToMessage;
  final void Function()? onResponseTriggered;

  @override
  State<ChatListEntry> createState() => _ChatListEntryState();
}

class _ChatListEntryState extends State<ChatListEntry> {
  MediaFileService? mediaService;

  List<StoredReaction> reactions = [];
  StreamSubscription<List<StoredReaction>>? reactionsSub;

  StreamSubscription<MediaFile?>? mediaFileSub;

  @override
  void initState() {
    super.initState();
    _applySharedData();
    initAsync();
  }

  @override
  void didUpdateWidget(ChatListEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.useSharedData != widget.useSharedData ||
        oldWidget.message.messageId != widget.message.messageId ||
        oldWidget.message.mediaId != widget.message.mediaId) {
      mediaFileSub?.cancel();
      reactionsSub?.cancel();
      mediaService = null;
      reactions = [];
      _applySharedData();
      initAsync();
    } else if (widget.useSharedData) {
      _applySharedData();
    }
  }

  void _applySharedData() {
    if (!widget.useSharedData) return;
    reactions = widget.reactions ?? const [];
    final mediaFile = widget.mediaFile;
    if (mediaFile == null) {
      mediaService = null;
      return;
    }
    // Reuse the existing service when the row is unchanged: it memoises the
    // media paths, and a fresh instance would also force the thumbnail below to
    // re-resolve its image.
    final current = mediaService;
    if (current == null || current.mediaFile != mediaFile) {
      mediaService = MediaFileService(mediaFile);
    }
  }

  @override
  void dispose() {
    mediaFileSub?.cancel();
    reactionsSub?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    if (widget.useSharedData) return;
    final mediaId = widget.message.mediaId;
    final messageId = widget.message.messageId;
    if (mediaId != null) {
      final mediaFileStream = watchRustDatabase(
        (control) => rust_mediafiles
            .watchMediaFiles(
              input: db_mediafiles.MediaQuery(
                filter: db_mediafiles.MediaFilter.ids,
                ids: [mediaId],
              ),
              control: control,
            )
            .map(orderedMediaFiles),
      ).map((rows) => rows.isEmpty ? null : rows.single);
      mediaFileSub = mediaFileStream.listen((mediaFiles) {
        if (!mounted ||
            widget.useSharedData ||
            widget.message.mediaId != mediaId) {
          return;
        }
        // Deletion emits an empty result before the parent message rebuilds.
        // Drop the old service so the tile cannot keep opening deleted media.
        setState(() {
          mediaService = mediaFiles == null
              ? null
              : MediaFileService(mediaFiles);
        });
      });
    }
    final stream = watchRustDatabase(
      (control) => rust_reactions.watchReactions(
        messages: [messageId],
        control: control,
      ),
    );

    reactionsSub = stream.listen((update) {
      if (!mounted ||
          widget.useSharedData ||
          widget.message.messageId != messageId) {
        return;
      }
      setState(() {
        reactions = update;
      });
    });
    setState(() {});
  }

  Widget? _getChatEntry(
    BorderRadius borderRadius,
    int reactionsForWidth,
    BubbleInfo info,
  ) {
    if (widget.message.type == MessageType.text.name) {
      final location = LiveLocationService.decode(
        widget.message.additionalMessageData,
      );
      if (location != null) {
        return ChatLiveLocationEntry(
          message: widget.message,
          location: location,
          borderRadius: borderRadius,
          info: info,
        );
      }
      final sticker = StickerService.decodeAdditional(
        widget.message.additionalMessageData,
      );
      if (sticker != null) {
        return ChatStickerEntry(message: widget.message, sticker: sticker);
      }
      if (widget.message.additionalMessageData != null) {
        return ChatWebxdcMessageEntry(
          message: widget.message,
          borderRadius: borderRadius,
          info: info,
        );
      }
      return ChatTextEntry(
        contactsById: widget.useSharedData ? widget.userIdToContact : null,
        message: widget.message,
        borderRadius: borderRadius,
        info: info,
      );
    }

    if (widget.message.type == MessageType.media.name) {
      if (mediaService == null) return null;
      if (mediaService!.mediaFile.type == MediaType.audio) {
        return ChatAudioEntry(
          message: widget.message,
          mediaService: mediaService!,
          borderRadius: borderRadius,
          info: info,
        );
      }
      return ChatMediaEntry(
        message: widget.message,
        group: widget.group,
        mediaService: mediaService!,
        galleryItems: widget.galleryItems,
        useSharedData: widget.useSharedData,
        borderRadius: borderRadius,
        info: info,
      );
    }

    if (widget.message.type == MessageType.contacts.name) {
      return ChatContactsEntry(
        message: widget.message,
        borderRadius: borderRadius,
        info: info,
        contactsById: widget.useSharedData ? widget.userIdToContact : null,
      );
    }

    if (widget.message.type == MessageType.restoreFlameCounter.name) {
      return ChatFlameRestoredEntry(
        message: widget.message,
        borderRadius: borderRadius,
        info: info,
      );
    }

    if (widget.message.type == MessageType.askAboutUser.name) {
      return ChatAskAFriendEntry(
        message: widget.message,
        borderRadius: borderRadius,
        info: info,
        contactsById: widget.useSharedData ? widget.userIdToContact : null,
      );
    }

    if (widget.message.type == MessageType.webxdcApp.name) {
      return ChatWebxdcEntry(
        message: widget.message,
        borderRadius: borderRadius,
        info: info,
      );
    }

    return const ChatUnknownEntry();
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
    var reactionsForWidth = reactions
        .where((t) => seen.add(t.emoji))
        .toList()
        .length;
    if (reactionsForWidth > 4) reactionsForWidth = 4;

    final info = getBubbleInfo(
      context,
      widget.message,
      widget.nextMessage,
      widget.prevMessage,
      widget.userIdToContact,
      reactionsForWidth * 43.0,
    );

    Widget child = Stack(
      // overflow: Overflow.visible,
      // clipBehavior: Clip.none,
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      children: [
        if (widget.message.isDeletedFromSender)
          ChatTextEntry(
            contactsById: widget.useSharedData ? widget.userIdToContact : null,
            message: widget.message,
            borderRadius: borderRadius,
            info: info,
          )
        else
          Column(
            crossAxisAlignment: right
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (info.displayUserName != '' && !widget.group.isDirectChat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 4),
                  child: Text(
                    info.displayUserName,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ResponseContainer(
                msg: widget.message,
                group: widget.group,
                mediaService: mediaService,
                borderRadius: borderRadius,
                scrollToMessage: widget.scrollToMessage,
                quotedMessage: widget.msgQuote(
                  messagesById: widget.messagesById,
                ),
                quotedMediaFile: widget.msgQuoteMedia(
                  messagesById: widget.messagesById,
                  mediaFilesById: widget.mediaFilesById,
                ),
                contactsById: widget.userIdToContact,
                useSharedData: widget.useSharedData,
                child: _getChatEntry(borderRadius, reactionsForWidth, info),
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
      child = MessageReplyDrag(
        message: widget.message,
        onResponseTriggered: widget.onResponseTriggered!,
        child: child,
      );

      child = MessageContextMenu(
        message: widget.message,
        group: widget.group,
        onResponseTriggered: widget.onResponseTriggered!,
        galleryItems: widget.galleryItems,
        mediaFileService: mediaService,
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
          mainAxisAlignment: right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!right && !widget.group.isDirectChat)
              if (hideContactAvatar)
                const SizedBox(width: 24)
              else
                GestureDetector(
                  onTap: () => context.push(
                    Routes.profileContact(widget.message.senderId!),
                  ),
                  child: AvatarIcon(
                    contactId: widget.message.senderId,
                    contacts:
                        widget.userIdToContact?[widget.message.senderId] == null
                        ? null
                        : [widget.userIdToContact![widget.message.senderId]!],
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

extension on ChatListEntry {
  StoredMessage? msgQuote({Map<String, StoredMessage>? messagesById}) {
    final quotedId = message.quotesMessageId;
    return quotedId == null ? null : messagesById?[quotedId];
  }

  MediaFile? msgQuoteMedia({
    Map<String, StoredMessage>? messagesById,
    Map<String, MediaFile>? mediaFilesById,
  }) {
    final quoted = msgQuote(messagesById: messagesById);
    return quoted?.mediaId == null ? null : mediaFilesById?[quoted!.mediaId];
  }
}

(EdgeInsetsGeometry, BorderRadius, bool) getMessageLayout(
  StoredMessage message,
  StoredMessage? prevMessage,
  StoredMessage? nextMessage,
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
    hideContactAvatar,
  );
}
