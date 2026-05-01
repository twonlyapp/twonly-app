import 'dart:async';

import 'package:drift/drift.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    hide Message;
import 'package:twonly/src/services/api/mediafiles/download.api.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/flame.service.dart';
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
        Log.warn(
          'Got reupload from $fromUserId for a message that either does not exists (${message == null}) or senderId = ${message?.senderId}',
        );
        return;
      }

      // in case there was already a downloaded file delete it...
      final mediaService = await MediaFileService.fromMediaId(message.mediaId!);
      if (mediaService != null && mediaService.tempPath.existsSync()) {
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

      final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(
        message.mediaId!,
      );

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
    case EncryptedContent_Media_Type.AUDIO:
      mediaType = MediaType.audio;
  }

  var mediaIdValue = const Value<String>.absent();

  final messageTmp = await twonlyDB.messagesDao
      .getMessageById(media.senderMessageId)
      .getSingleOrNull();
  if (messageTmp != null) {
    if (messageTmp.senderId != fromUserId) {
      Log.warn(
        '$fromUserId tried to modify the message from ${messageTmp.senderId}.',
      );
      return;
    }
    if (messageTmp.mediaId == null) {
      Log.warn(
        'This message already exit without a mediaId. Message is dropped.',
      );
      return;
    }
    final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(
      messageTmp.mediaId!,
    );
    if (mediaFile?.downloadState != DownloadState.reuploadRequested) {
      Log.warn(
        'This message and media file already exit and was not requested again. Dropping it.',
      );
      return;
    }

    if (mediaFile != null) {
      // media file is reuploaded use the same mediaId
      mediaIdValue = Value(mediaFile.mediaId);
    }
  }

  int? displayLimitInMilliseconds;
  if (media.hasDisplayLimitInMilliseconds()) {
    if (media.displayLimitInMilliseconds.toInt() < 1000) {
      displayLimitInMilliseconds =
          media.displayLimitInMilliseconds.toInt() * 1000;
    } else {
      displayLimitInMilliseconds = media.displayLimitInMilliseconds.toInt();
    }
  }

  MediaFile? mediaFile;
  Message? message;

  await twonlyDB.transaction(() async {
    mediaFile = await twonlyDB.mediaFilesDao.insertOrUpdateMedia(
      MediaFilesCompanion(
        mediaId: mediaIdValue,
        downloadState: const Value(DownloadState.pending),
        type: Value(mediaType),
        requiresAuthentication: Value(media.requiresAuthentication),
        displayLimitInMilliseconds: Value(
          displayLimitInMilliseconds,
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

    message = await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion(
        messageId: Value(media.senderMessageId),
        senderId: Value(fromUserId),
        groupId: Value(groupId),
        mediaId: Value(mediaFile!.mediaId),
        type: Value(MessageType.media.name),
        additionalMessageData: Value.absentIfNull(
          media.hasAdditionalMessageData()
              ? Uint8List.fromList(media.additionalMessageData)
              : null,
        ),
        quotesMessageId: Value(
          media.hasQuoteMessageId() ? media.quoteMessageId : null,
        ),
        createdAt: Value(fromTimestamp(media.timestamp)),
      ),
    );
  });

  if (message != null && mediaFile != null) {
    await twonlyDB.groupsDao.increaseLastMessageExchange(
      groupId,
      fromTimestamp(media.timestamp),
    );
    Log.info('Inserted a new media message with ID: ${message!.messageId}');
    await incFlameCounter(
      message!.groupId,
      true,
      fromTimestamp(media.timestamp),
    );

    unawaited(startDownloadMedia(mediaFile!, false));
  } else {
    if (mediaFile == null && message == null) {
      Log.error(
        'Could not insert new message as both the message and mediaFile are empty.',
      );
    } else if (mediaFile == null) {
      Log.error('Could not insert new message as the mediaFile is empty.');
    } else {
      Log.error('Could not insert new message as the message is empty.');
    }
  }
}

Future<void> handleMediaUpdate(
  int fromUserId,
  EncryptedContent_MediaUpdate mediaUpdate,
) async {
  final message = await twonlyDB.messagesDao
      .getMessageById(mediaUpdate.targetMessageId)
      .getSingleOrNull();
  if (message == null) {
    // this can happen, in case the message was already deleted.
    Log.info(
      'Got media update to message ${mediaUpdate.targetMessageId} but message not found.',
    );
    return;
  }
  if (message.mediaId == null) {
    // this can happen, in case the message was already deleted.
    Log.warn(
      'Got media update for message ${mediaUpdate.targetMessageId} which does not have a mediaId defined.',
    );
    return;
  }
  final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(
    message.mediaId!,
  );
  if (mediaFile == null) {
    Log.info(
      'Got media file update, but media file was not found ${message.mediaId}',
    );
    return;
  }

  switch (mediaUpdate.type) {
    case EncryptedContent_MediaUpdate_Type.REOPENED:
      Log.info('Got media file reopened ${mediaFile.mediaId}');
      await twonlyDB.messagesDao.updateMessageId(
        message.messageId,
        const MessagesCompanion(
          mediaReopened: Value(true),
        ),
      );
    case EncryptedContent_MediaUpdate_Type.STORED:
      Log.info('Got media file stored ${mediaFile.mediaId}');
      final mediaService = MediaFileService(mediaFile);
      await mediaService.storeMediaFile();
      await twonlyDB.messagesDao.updateMessageId(
        message.messageId,
        const MessagesCompanion(
          mediaStored: Value(true),
        ),
      );

    case EncryptedContent_MediaUpdate_Type.DECRYPTION_ERROR:
      Log.info('Got media file decryption error ${mediaFile.mediaId}');
      await reuploadMediaFile(fromUserId, mediaFile, message.messageId);
  }
}
