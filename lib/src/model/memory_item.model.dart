import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/media_upload.dart' as send;
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
    final items = <int, MemoryItem>{};
    for (final message in messages) {
      final isSend = message.messageOtherId == null;
      final id = message.mediaUploadId ?? message.messageId;
      final basePath = await send.getMediaFilePath(
        isSend ? message.mediaUploadId! : message.messageId,
        isSend ? 'send' : 'received',
      );
      File? imagePath;
      late File thumbnailFile;
      File? videoPath;
      if (File('$basePath.mp4').existsSync()) {
        videoPath = File('$basePath.mp4');
        thumbnailFile = getThumbnailPath(videoPath);
        if (!thumbnailFile.existsSync()) {
          await createThumbnailsForVideo(videoPath);
        }
      } else if (File('$basePath.png').existsSync()) {
        imagePath = File('$basePath.png');
        thumbnailFile = getThumbnailPath(imagePath);
        if (!thumbnailFile.existsSync()) {
          await createThumbnailsForImage(imagePath);
        }
      } else {
        if (message.mediaStored) {
          /// media file was deleted, ... remove the file
          await twonlyDB.messagesDao.updateMessageByMessageId(
            message.messageId,
            const MessagesCompanion(
              mediaStored: Value(false),
            ),
          );
        }
        continue;
      }
      var mirrorVideo = false;
      if (videoPath != null) {
        final content = MediaMessageContent.fromJson(
            jsonDecode(message.contentJson!) as Map);
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
