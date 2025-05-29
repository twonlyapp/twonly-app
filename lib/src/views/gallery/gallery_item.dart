import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/media_send.dart' as send;
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';

class GalleryItem {
  GalleryItem({
    required this.id,
    required this.messages,
    required this.date,
    required this.mirrorVideo,
    this.imagePath,
    this.videoPath,
  });
  final String id;
  final bool mirrorVideo;
  final List<Message> messages;
  final DateTime date;
  final File? imagePath;
  final File? videoPath;

  static Future<Map<int, GalleryItem>> convertFromMessages(
      List<Message> messages) async {
    Map<int, GalleryItem> items = {};
    for (final message in messages) {
      bool isSend = message.messageOtherId == null;
      int id = message.mediaUploadId ?? message.messageId;
      final basePath = await send.getMediaFilePath(
        isSend ? message.mediaUploadId! : message.messageId,
        isSend ? "send" : "received",
      );
      File? imagePath;
      File? videoPath;
      if (await File("$basePath.mp4").exists()) {
        videoPath = File("$basePath.mp4");
      } else if (await File("$basePath.png").exists()) {
        imagePath = File("$basePath.png");
      } else {
        if (message.mediaStored) {
          /// media file was deleted, ... remove the file
          twonlyDatabase.messagesDao.updateMessageByMessageId(
              message.messageId, MessagesCompanion(mediaStored: Value(false)));
        }
        continue;
      }
      bool mirrorVideo = false;
      if (videoPath != null) {
        MediaMessageContent content =
            MediaMessageContent.fromJson(jsonDecode(message.contentJson!));
        mirrorVideo = content.mirrorVideo;
      }

      items
          .putIfAbsent(
              id,
              () => GalleryItem(
                  id: id.toString(),
                  messages: [],
                  date: message.sendAt,
                  mirrorVideo: mirrorVideo,
                  imagePath: imagePath,
                  videoPath: videoPath))
          .messages
          .add(message);
    }
    return items;
  }
}
