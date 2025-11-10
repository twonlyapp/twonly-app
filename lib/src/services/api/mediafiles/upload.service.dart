import 'dart:async';
import 'dart:convert';
import 'package:background_downloader/background_downloader.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/http/http_requests.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

Future<void> finishStartedPreprocessing() async {
  final mediaFiles =
      await twonlyDB.mediaFilesDao.getAllMediaFilesPendingUpload();

  for (final mediaFile in mediaFiles) {
    if (mediaFile.isDraftMedia) {
      continue;
    }
    try {
      final service = await MediaFileService.fromMedia(mediaFile);
      if (!service.originalPath.existsSync() &&
          !service.uploadRequestPath.existsSync()) {
        if (service.storedPath.existsSync()) {
          // media files was just stored..
          continue;
        }
        Log.info(
          'Deleted media files, as originalPath and uploadRequestPath both do not exists',
        );
        // the file does not exists anymore.
        await twonlyDB.mediaFilesDao.deleteMediaFile(mediaFile.mediaId);
        continue;
      }
      await startBackgroundMediaUpload(service);
    } catch (e) {
      Log.warn(e);
    }
  }
}

Future<MediaFileService?> initializeMediaUpload(
  MediaType type,
  int? displayLimitInMilliseconds, {
  bool isDraftMedia = false,
}) async {
  if (displayLimitInMilliseconds != null && displayLimitInMilliseconds < 1000) {
    // in case the time was set in seconds...
    // ignore: parameter_assignments
    displayLimitInMilliseconds = displayLimitInMilliseconds * 1000;
  }
  final chacha20 = FlutterChacha20.poly1305Aead();
  final encryptionKey = await (await chacha20.newSecretKey()).extract();
  final encryptionNonce = chacha20.newNonce();

  await twonlyDB.mediaFilesDao.updateAllMediaFiles(
    const MediaFilesCompanion(isDraftMedia: Value(false)),
  );

  final mediaFile = await twonlyDB.mediaFilesDao.insertMedia(
    MediaFilesCompanion(
      uploadState: const Value(UploadState.initialized),
      displayLimitInMilliseconds: Value(displayLimitInMilliseconds),
      encryptionKey: Value(Uint8List.fromList(encryptionKey.bytes)),
      encryptionNonce: Value(Uint8List.fromList(encryptionNonce)),
      isDraftMedia: Value(isDraftMedia),
      type: Value(type),
    ),
  );
  if (mediaFile == null) return null;
  return MediaFileService.fromMedia(mediaFile);
}

Future<void> insertMediaFileInMessagesTable(
  MediaFileService mediaService,
  List<String> groupIds,
) async {
  await twonlyDB.mediaFilesDao.updateAllMediaFiles(
    const MediaFilesCompanion(
      isDraftMedia: Value(false),
    ),
  );
  for (final groupId in groupIds) {
    final message = await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion(
        groupId: Value(groupId),
        mediaId: Value(mediaService.mediaFile.mediaId),
        type: const Value(MessageType.media),
      ),
    );
    await twonlyDB.groupsDao
        .increaseLastMessageExchange(groupId, DateTime.now());
    if (message != null) {
      // de-archive contact when sending a new message
      await twonlyDB.groupsDao.updateGroup(
        message.groupId,
        const GroupsCompanion(
          archived: Value(false),
          deletedContent: Value(false),
        ),
      );
    } else {
      Log.error('Error inserting media upload message in database.');
    }
  }

  unawaited(startBackgroundMediaUpload(mediaService));
}

Future<void> startBackgroundMediaUpload(MediaFileService mediaService) async {
  if (mediaService.mediaFile.uploadState == UploadState.initialized ||
      mediaService.mediaFile.uploadState == UploadState.preprocessing) {
    await mediaService.setUploadState(UploadState.preprocessing);

    if (!mediaService.tempPath.existsSync()) {
      await mediaService.compressMedia();
      if (!mediaService.tempPath.existsSync()) {
        return;
      }
    }

    if (!mediaService.encryptedPath.existsSync()) {
      await _encryptMediaFiles(mediaService);
      if (!mediaService.encryptedPath.existsSync()) {
        return;
      }
    }

    if (!mediaService.uploadRequestPath.existsSync()) {
      await _createUploadRequest(mediaService);
    }

    if (mediaService.uploadRequestPath.existsSync()) {
      await mediaService.setUploadState(UploadState.uploading);
      // at this point the original file is not used any more, so it can be deleted
      mediaService.originalPath.deleteSync();
    }
  }

  if (mediaService.mediaFile.uploadState == UploadState.uploading ||
      mediaService.mediaFile.uploadState == UploadState.uploadLimitReached) {
    await _uploadUploadRequest(mediaService);
  }
}

Future<void> _encryptMediaFiles(MediaFileService mediaService) async {
  /// if there is a video wait until it is finished with compression

  if (!mediaService.tempPath.existsSync()) {
    Log.error('Could not encrypted image as it does not exists');
    return;
  }

  final dataToEncrypt = await mediaService.tempPath.readAsBytes();

  final chacha20 = FlutterChacha20.poly1305Aead();

  final secretBox = await chacha20.encrypt(
    dataToEncrypt,
    secretKey: SecretKey(mediaService.mediaFile.encryptionKey!),
    nonce: mediaService.mediaFile.encryptionNonce,
  );

  await mediaService.setEncryptedMac(Uint8List.fromList(secretBox.mac.bytes));

  mediaService.encryptedPath
      .writeAsBytesSync(Uint8List.fromList(secretBox.cipherText));
}

Future<void> _createUploadRequest(MediaFileService media) async {
  final downloadTokens = <Uint8List>[];

  final messagesOnSuccess = <TextMessage>[];

  final messages =
      await twonlyDB.messagesDao.getMessagesByMediaId(media.mediaFile.mediaId);

  if (messages.isEmpty) {
    // There where no user selected who should receive the image, so waiting with this step...
    return;
  }

  for (final message in messages) {
    final groupMembers =
        await twonlyDB.groupsDao.getGroupNonLeftMembers(message.groupId);

    if (media.mediaFile.reuploadRequestedBy == null) {
      await twonlyDB.groupsDao.incFlameCounter(
        message.groupId,
        false,
        message.createdAt,
      );
    }

    for (final groupMember in groupMembers) {
      /// only send the upload to the users
      if (media.mediaFile.reuploadRequestedBy != null) {
        if (!media.mediaFile.reuploadRequestedBy!
            .contains(groupMember.contactId)) {
          continue;
        }
      }

      final downloadToken = getRandomUint8List(32);

      late EncryptedContent_Media_Type type;
      switch (media.mediaFile.type) {
        case MediaType.audio:
          type = EncryptedContent_Media_Type.AUDIO;
        case MediaType.image:
          type = EncryptedContent_Media_Type.IMAGE;
        case MediaType.gif:
          type = EncryptedContent_Media_Type.GIF;
        case MediaType.video:
          type = EncryptedContent_Media_Type.VIDEO;
      }

      final notEncryptedContent = EncryptedContent(
        groupId: message.groupId,
        media: EncryptedContent_Media(
          senderMessageId: message.messageId,
          type: type,
          requiresAuthentication: media.mediaFile.requiresAuthentication,
          timestamp: Int64(message.createdAt.millisecondsSinceEpoch),
          downloadToken: downloadToken.toList(),
          encryptionKey: media.mediaFile.encryptionKey,
          encryptionNonce: media.mediaFile.encryptionNonce,
          encryptionMac: media.mediaFile.encryptionMac,
        ),
      );

      if (media.mediaFile.displayLimitInMilliseconds != null) {
        notEncryptedContent.media.displayLimitInMilliseconds =
            Int64(media.mediaFile.displayLimitInMilliseconds!);
      }

      final cipherText = await sendCipherText(
        groupMember.contactId,
        notEncryptedContent,
        onlyReturnEncryptedData: true,
      );

      if (cipherText == null) {
        Log.error(
          'Could not generate ciphertext message for ${groupMember.contactId}',
        );
      }

      final messageOnSuccess = TextMessage()
        ..body = cipherText!.$1
        ..userId = Int64(groupMember.contactId);

      if (cipherText.$2 != null) {
        messageOnSuccess.pushData = cipherText.$2!;
      }

      messagesOnSuccess.add(messageOnSuccess);
      downloadTokens.add(downloadToken);
    }
  }

  final bytesToUpload = await media.encryptedPath.readAsBytes();

  final uploadRequest = UploadRequest(
    messagesOnSuccess: messagesOnSuccess,
    downloadTokens: downloadTokens,
    encryptedData: bytesToUpload,
  );

  final uploadRequestBytes = uploadRequest.writeToBuffer();

  await media.uploadRequestPath.writeAsBytes(uploadRequestBytes);
}

Mutex protectUpload = Mutex();

Future<void> _uploadUploadRequest(MediaFileService media) async {
  await protectUpload.protect(() async {
    final currentMedia =
        await twonlyDB.mediaFilesDao.getMediaFileById(media.mediaFile.mediaId);

    if (currentMedia == null ||
        currentMedia.uploadState == UploadState.backgroundUploadTaskStarted) {
      Log.info('Download for ${media.mediaFile.mediaId} already started.');
      return null;
    }

    final apiAuthTokenRaw = await const FlutterSecureStorage()
        .read(key: SecureStorageKeys.apiAuthToken);

    if (apiAuthTokenRaw == null) {
      Log.error('api auth token not defined.');
      return null;
    }
    final apiAuthToken = uint8ListToHex(base64Decode(apiAuthTokenRaw));

    final apiUrl =
        'http${apiService.apiSecure}://${apiService.apiHost}/api/upload';

    // try {
    Log.info('Starting upload from ${media.mediaFile.mediaId}');

    final task = UploadTask.fromFile(
      taskId: 'upload_${media.mediaFile.mediaId}',
      displayName: media.mediaFile.type.name,
      file: media.uploadRequestPath,
      url: apiUrl,
      priority: 0,
      retries: 10,
      headers: {
        'x-twonly-auth-token': apiAuthToken,
      },
    );

    Log.info('Enqueue upload task: ${task.taskId}');

    await FileDownloader().enqueue(task);

    await media.setUploadState(UploadState.backgroundUploadTaskStarted);
  });
}
