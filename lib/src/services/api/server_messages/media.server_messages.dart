import 'dart:async';
import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/mediafiles/download.service.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleMedia(
  int fromUserId,
  String groupId,
  EncryptedContent_Media media,
) async {
  Log.info(
    'Got a media message: ${media.senderMessageId} from $groupId with type ${media.type}',
  );

  late MediaType mediaType;
  switch (media.type) {
    case EncryptedContent_Media_Type.REUPLOAD:
      final message = await twonlyDB.messagesDao
          .getMessageById(media.senderMessageId)
          .getSingleOrNull();
      if (message == null ||
          message.senderId != fromUserId ||
          message.mediaId == null) {
        return;
      }

      // in case there was already a downloaded file delete it...
      final mediaService = await MediaFileService.fromMediaId(message.mediaId!);
      if (mediaService != null) {
        mediaService.tempPath.deleteSync();
      }

      await twonlyDB.mediaFilesDao.updateMedia(
        message.mediaId!,
        MediaFilesCompanion(
          downloadState: const Value(DownloadState.pending),
          downloadToken: Value(Uint8List.fromList(media.downloadToken)),
          encryptionKey: Value(Uint8List.fromList(media.encryptionKey)),
          encryptionMac: Value(Uint8List.fromList(media.encryptionMac)),
          encryptionNonce: Value(Uint8List.fromList(media.encryptionNonce)),
        ),
      );

      final mediaFile =
          await twonlyDB.mediaFilesDao.getMediaFileById(message.mediaId!);

      if (mediaFile != null) {
        unawaited(startDownloadMedia(mediaFile, false));
      }

      return;
    case EncryptedContent_Media_Type.IMAGE:
      mediaType = MediaType.image;
    case EncryptedContent_Media_Type.VIDEO:
      mediaType = MediaType.video;
    case EncryptedContent_Media_Type.GIF:
      mediaType = MediaType.gif;
  }

  final mediaFile = await twonlyDB.mediaFilesDao.insertMedia(
    MediaFilesCompanion(
      downloadState: const Value(DownloadState.pending),
      type: Value(mediaType),
      requiresAuthentication: Value(media.requiresAuthentication),
      displayLimitInMilliseconds: Value(
        media.hasDisplayLimitInMilliseconds()
            ? media.displayLimitInMilliseconds.toInt()
            : null,
      ),
      downloadToken: Value(Uint8List.fromList(media.downloadToken)),
      encryptionKey: Value(Uint8List.fromList(media.encryptionKey)),
      encryptionMac: Value(Uint8List.fromList(media.encryptionMac)),
      encryptionNonce: Value(Uint8List.fromList(media.encryptionNonce)),
      createdAt: Value(fromTimestamp(media.timestamp)),
    ),
  );

  if (mediaFile == null) {
    Log.error('Could not insert media file into database');
    return;
  }

  final message = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      messageId: Value(media.senderMessageId),
      senderId: Value(fromUserId),
      groupId: Value(groupId),
      mediaId: Value(mediaFile.mediaId),
      ackByServer: const Value(true),
      ackByUser: const Value(true),
      quotesMessageId: Value(
        media.hasQuoteMessageId() ? media.quoteMessageId : null,
      ),
      createdAt: Value(fromTimestamp(media.timestamp)),
    ),
  );
  if (message != null) {
    Log.info('Inserted a new media message with ID: ${message.messageId}');
    await twonlyDB.contactsDao.incFlameCounter(
      fromUserId,
      true,
      fromTimestamp(media.timestamp),
    );

    unawaited(startDownloadMedia(mediaFile, false));
  }
}

Future<void> handleMediaUpdate(
  int fromUserId,
  String groupId,
  EncryptedContent_MediaUpdate mediaUpdate,
) async {
  final message = await twonlyDB.messagesDao
      .getMessageById(mediaUpdate.targetMessageId)
      .getSingleOrNull();
  if (message == null || message.mediaId == null) return;
  final mediaFile =
      await twonlyDB.mediaFilesDao.getMediaFileById(message.mediaId!);
  if (mediaFile == null) {
    Log.info(
        'Got media file update, but media file was not found ${message.mediaId}');
    return;
  }

  switch (mediaUpdate.type) {
    case EncryptedContent_MediaUpdate_Type.REOPENED:
      Log.info('Got media file reopened ${mediaFile.mediaId}');
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(
          reopenByContact: Value(true),
        ),
      );
    case EncryptedContent_MediaUpdate_Type.STORED:
      Log.info('Got media file stored ${mediaFile.mediaId}');
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(
          stored: Value(true),
        ),
      );

      final mediaService = await MediaFileService.fromMedia(mediaFile);
      unawaited(mediaService.createThumbnail());

    case EncryptedContent_MediaUpdate_Type.DECRYPTION_ERROR:
      Log.info('Got media file decryption error ${mediaFile.mediaId}');
      final reuploadRequestedBy = mediaFile.reuploadRequestedBy ?? [];
      reuploadRequestedBy.add(fromUserId);
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        MediaFilesCompanion(
          uploadState: const Value(UploadState.uploading),
          reuploadRequestedBy: Value(reuploadRequestedBy),
        ),
      );
  }
}
