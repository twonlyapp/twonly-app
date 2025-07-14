import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pbserver.dart';
import 'package:twonly/src/views/chats/chat_messages_components/in_chat_media_viewer.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/media_download.dart' as received;

import 'package:twonly/src/views/chats/media_viewer.view.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/views/tutorial/tutorials.dart';

class ChatMediaEntry extends StatefulWidget {
  const ChatMediaEntry({
    super.key,
    required this.message,
    required this.contact,
    required this.content,
    required this.galleryItems,
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
    checkIfTutorialCanBeShown();
  }

  Future<void> checkIfTutorialCanBeShown() async {
    if (widget.message.openedAt == null &&
            widget.message.messageOtherId != null ||
        widget.message.mediaStored) {
      return;
    }
    if (await received.existsMediaFile(widget.message.messageId, "png")) {
      if (mounted) {
        setState(() {
          canBeReopened = true;
        });
      }
      Future.delayed(Duration(seconds: 1), () {
        if (!mounted) return;
        showReopenMediaFilesTutorial(context, reopenMediaFile);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = getMessageColorFromType(
      widget.content,
      context,
    );

    return GestureDetector(
      key: reopenMediaFile,
      onDoubleTap: () async {
        if (widget.message.openedAt == null &&
                widget.message.messageOtherId != null ||
            widget.message.mediaStored) {
          return;
        }
        if (await received.existsMediaFile(widget.message.messageId, "png")) {
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
            MessagesCompanion(openedAt: Value(null)),
          );
        }
      },
      onTap: () async {
        if (widget.message.kind == MessageKind.media) {
          if (widget.message.downloadState == DownloadState.downloaded &&
              widget.message.openedAt == null) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return MediaViewerView(widget.contact,
                    initialMessage: widget.message);
              }),
            );
            checkIfTutorialCanBeShown();
          } else if (widget.message.downloadState == DownloadState.pending) {
            received.startDownloadMedia(widget.message, true);
          }
        }
      },
      child: SizedBox(
        width: 150,
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
