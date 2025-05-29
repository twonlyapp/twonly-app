import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/chats/chat_messages_components/in_chat_media_viewer.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/media_received.dart' as received;
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';

class ChatMediaEntry extends StatelessWidget {
  const ChatMediaEntry({
    super.key,
    required this.message,
    required this.contact,
    required this.content,
  });

  final Message message;
  final Contact contact;
  final MessageContent content;

  @override
  Widget build(BuildContext context) {
    Color color = getMessageColorFromType(
      content,
      context,
    );

    return GestureDetector(
      onDoubleTap: () async {
        if (message.openedAt == null && message.messageOtherId != null ||
            message.mediaStored) {
          return;
        }
        if (await received.existsMediaFile(message.messageId, "png")) {
          await encryptAndSendMessageAsync(
            null,
            contact.userId,
            MessageJson(
              kind: MessageKind.reopenedMedia,
              messageId: message.messageId,
              content: ReopenedMediaFileContent(
                messageId: message.messageOtherId!,
              ),
              timestamp: DateTime.now(),
            ),
            pushKind: PushKind.reopenedMedia,
          );
          await twonlyDatabase.messagesDao.updateMessageByMessageId(
            message.messageId,
            MessagesCompanion(openedAt: Value(null)),
          );
        }
      },
      onTap: () {
        if (message.kind == MessageKind.media) {
          if (message.downloadState == DownloadState.downloaded &&
              message.openedAt == null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return MediaViewerView(contact, initialMessage: message);
              }),
            );
          } else if (message.downloadState == DownloadState.pending) {
            received.startDownloadMedia(message, true);
          }
        }
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InChatMediaViewer(
              message: message,
              contact: contact,
            ),
          ),
        ),
      ),
    );
  }
}
