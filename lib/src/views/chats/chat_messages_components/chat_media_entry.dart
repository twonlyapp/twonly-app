import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/message_old.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pbserver.dart';
import 'package:twonly/src/services/api/mediafiles/download.service.dart'
    as received;
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';
import 'package:twonly/src/views/chats/chat_messages_components/in_chat_media_viewer.dart';
import 'package:twonly/src/views/chats/media_viewer.view.dart';
import 'package:twonly/src/views/tutorial/tutorials.dart';

class ChatMediaEntry extends StatefulWidget {
  const ChatMediaEntry({
    required this.message,
    required this.contact,
    required this.content,
    required this.galleryItems,
    super.key,
  });

  final Message message;
  final Contact contact;
  final MessageContent content;
  final List<MemoryItem> galleryItems;

  @override
  State<ChatMediaEntry> createState() => _ChatMediaEntryState();
}

class _ChatMediaEntryState extends State<ChatMediaEntry> {
  GlobalKey reopenMediaFile = GlobalKey();
  bool canBeReopened = false;

  @override
  void initState() {
    super.initState();
    unawaited(checkIfTutorialCanBeShown());
  }

  Future<void> checkIfTutorialCanBeShown() async {
    if (widget.message.openedAt == null &&
            widget.message.messageOtherId != null ||
        widget.message.mediaStored) {
      return;
    }
    final content = getMediaContent(widget.message);
    if (content == null ||
        content.isRealTwonly ||
        content.maxShowTime != gMediaShowInfinite) {
      return;
    }
    if (await received.existsMediaFile(widget.message.messageId, 'png')) {
      if (mounted) {
        setState(() {
          canBeReopened = true;
        });
      }
      Future.delayed(const Duration(seconds: 1), () async {
        if (!mounted) return;
        await showReopenMediaFilesTutorial(context, reopenMediaFile);
      });
    }
  }

  Future<void> onDoubleTap() async {
    if (widget.message.openedAt == null &&
            widget.message.messageOtherId != null ||
        widget.message.mediaStored) {
      return;
    }
    if (await received.existsMediaFile(widget.message.messageId, 'png')) {
      await encryptAndSendMessageAsync(
        null,
        widget.contact.userId,
        MessageJson(
          kind: MessageKind.reopenedMedia,
          messageSenderId: widget.message.messageId,
          content: ReopenedMediaFileContent(
            messageId: widget.message.messageOtherId!,
          ),
          timestamp: DateTime.now(),
        ),
        pushNotification: PushNotification(
          kind: PushKind.reopenedMedia,
        ),
      );
      await twonlyDB.messagesDao.updateMessageByMessageId(
        widget.message.messageId,
        const MessagesCompanion(openedAt: Value(null)),
      );
    }
  }

  Future<void> onTap() async {
    if (widget.message.downloadState == DownloadState.downloaded &&
        widget.message.openedAt == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return MediaViewerView(
              widget.contact,
              initialMessage: widget.message,
            );
          },
        ),
      );
      await checkIfTutorialCanBeShown();
    } else if (widget.message.downloadState == DownloadState.pending) {
      await received.startDownloadMedia(widget.message, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getMessageColorFromType(
      widget.content,
      context,
    );

    return GestureDetector(
      key: reopenMediaFile,
      onDoubleTap: onDoubleTap,
      onTap: widget.message.kind == MessageKind.media ? onTap : null,
      child: SizedBox(
        width: 150,
        height: widget.message.mediaStored ? 271 : null,
        child: Align(
          alignment: Alignment.centerRight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InChatMediaViewer(
              message: widget.message,
              contact: widget.contact,
              color: color,
              galleryItems: widget.galleryItems,
              canBeReopened: canBeReopened,
            ),
          ),
        ),
      ),
    );
  }
}
