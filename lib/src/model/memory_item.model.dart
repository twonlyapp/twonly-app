import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/media_upload.dart' as send;
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/thumbnail.service.dart';

class MemoryItem {
  MemoryItem({
    required this.id,
    required this.messages,
    required this.date,
    required this.mirrorVideo,
    required this.thumbnailPath,
    this.imagePath,
    this.videoPath,
  });
  final int id;
  final bool mirrorVideo;
  final List<Message> messages;
  final DateTime date;
  final File thumbnailPath;
  final File? imagePath;
  final File? videoPath;

  static Future<Map<int, MemoryItem>> convertFromMessages(
    List<Message> messages,
  ) async {
    Map<int, MemoryItem> items = {};
    for (final message in messages) {
      bool isSend = message.messageOtherId == null;
      int id = message.mediaUploadId ?? message.messageId;
      final basePath = await send.getMediaFilePath(
        isSend ? message.mediaUploadId! : message.messageId,
        isSend ? "send" : "received",
      );
      File? imagePath;
      late File thumbnailFile;
      File? videoPath;
      if (await File("$basePath.mp4").exists()) {
        videoPath = File("$basePath.mp4");
        thumbnailFile = getThumbnailPath(videoPath);
        if (!await thumbnailFile.exists()) {
          await createThumbnailsForVideo(videoPath);
        }
      } else if (await File("$basePath.png").exists()) {
        imagePath = File("$basePath.png");
        thumbnailFile = getThumbnailPath(imagePath);
        if (!await thumbnailFile.exists()) {
          await createThumbnailsForImage(imagePath);
        }
      } else {
        if (message.mediaStored) {
          /// media file was deleted, ... remove the file
          twonlyDB.messagesDao.updateMessageByMessageId(
            message.messageId,
            MessagesCompanion(
              mediaStored: Value(false),
            ),
          );
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
              () => MemoryItem(
                  id: id,
                  messages: [],
                  date: message.sendAt,
                  mirrorVideo: mirrorVideo,
                  thumbnailPath: thumbnailFile,
                  imagePath: imagePath,
                  videoPath: videoPath))
          .messages
          .add(message);
    }
    return items;
  }
}
