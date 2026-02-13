import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    hide Message;
import 'package:twonly/src/services/api/mediafiles/download.service.dart'
    as received;
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages_components/in_chat_media_viewer.dart';
import 'package:twonly/src/views/chats/media_viewer.view.dart';

class ChatMediaEntry extends StatefulWidget {
  const ChatMediaEntry({
    required this.message,
    required this.group,
    required this.galleryItems,
    required this.mediaService,
    required this.minWidth,
    super.key,
  });

  final Message message;
  final double minWidth;
  final Group group;
  final List<MemoryItem> galleryItems;
  final MediaFileService mediaService;

  @override
  State<ChatMediaEntry> createState() => _ChatMediaEntryState();
}

class _ChatMediaEntryState extends State<ChatMediaEntry> {
  GlobalKey reopenMediaFile = GlobalKey();
  bool _canBeReopened = false;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    if (widget.message.senderId == null || widget.message.mediaStored) {
      return;
    }
    if (widget.mediaService.mediaFile.requiresAuthentication ||
        widget.mediaService.mediaFile.displayLimitInMilliseconds != null) {
      return;
    }
    if (widget.mediaService.tempPath.existsSync()) {
      if (mounted) {
        setState(() {
          _canBeReopened = true;
        });
      }
    }
  }

  Future<void> onDoubleTap() async {
    if (widget.message.openedAt == null || widget.message.mediaStored) {
      return;
    }
    if (widget.mediaService.tempPath.existsSync() &&
        widget.message.senderId != null) {
      await sendCipherText(
        widget.message.senderId!,
        EncryptedContent(
          mediaUpdate: EncryptedContent_MediaUpdate(
            type: EncryptedContent_MediaUpdate_Type.REOPENED,
            targetMessageId: widget.message.messageId,
          ),
        ),
      );
      await twonlyDB.messagesDao.updateMessageId(
        widget.message.messageId,
        const MessagesCompanion(openedAt: Value(null)),
      );
    }
  }

  Future<void> onTap() async {
    if (widget.mediaService.mediaFile.downloadState == DownloadState.ready &&
        widget.message.openedAt == null) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return MediaViewerView(
              widget.group,
              initialMessage: widget.message,
            );
          },
        ),
      );
    } else if (widget.mediaService.mediaFile.downloadState ==
        DownloadState.pending) {
      await received.startDownloadMedia(widget.mediaService.mediaFile, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getMessageColorFromType(
      widget.message,
      widget.mediaService.mediaFile,
      context,
    );

    return GestureDetector(
      key: reopenMediaFile,
      onDoubleTap: onDoubleTap,
      onTap: (widget.message.type == MessageType.media.name) ? onTap : null,
      child: SizedBox(
        width: (widget.minWidth > 150) ? widget.minWidth : 150,
        height: (widget.message.mediaStored &&
                widget.mediaService.imagePreviewAvailable)
            ? 271
            : null,
        child: Align(
          alignment: Alignment.centerRight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InChatMediaViewer(
              message: widget.message,
              group: widget.group,
              mediaService: widget.mediaService,
              color: color,
              galleryItems: widget.galleryItems,
              canBeReopened: _canBeReopened,
            ),
          ),
        ),
      ),
    );
  }
}
