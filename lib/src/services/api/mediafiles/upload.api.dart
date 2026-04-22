import 'dart:async';
import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/http/http_requests.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/mediafiles/media_background.api.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:workmanager/workmanager.dart' hide TaskStatus;

final lockRetransmission = Mutex();

Future<void> reuploadMediaFiles() async {
  return lockRetransmission.protect(() async {
    final receipts = await twonlyDB.receiptsDao
        .getReceiptsForMediaRetransmissions();

    if (receipts.isEmpty) return;

    Log.info('Reuploading ${receipts.length} media files to the server.');

    final contacts = <int, Contact>{};

    for (final receipt in receipts) {
      if (receipt.retryCount > 1 && receipt.lastRetry != null) {
        final twentyFourHoursAgo = DateTime.now().subtract(
          const Duration(hours: 24),
        );
        if (receipt.lastRetry!.isAfter(twentyFourHoursAgo)) {
          Log.info(
            'Ignoring ${receipt.receiptId} as it was retried in the last 24h',
          );
          continue;
        }
      }
      var messageId = receipt.messageId;
      if (receipt.messageId == null) {
        Log.info('Message not in receipt. Loading it from the content.');
        try {
          final content = EncryptedContent.fromBuffer(receipt.message);
          if (content.hasMedia()) {
            messageId = content.media.senderMessageId;
            final messageExists = await twonlyDB.messagesDao
                .getMessageById(messageId)
                .getSingleOrNull();
            if (messageExists != null) {
              await twonlyDB.receiptsDao.updateReceipt(
                receipt.receiptId,
                ReceiptsCompanion(
                  messageId: Value(messageId),
                ),
              );
            } else {
              Log.info(
                'Message $messageId not found in DB for receipt recovery. Deleting stale receipt.',
              );
              await twonlyDB.receiptsDao.deleteReceipt(receipt.receiptId);
              continue;
            }
          }
        } catch (e) {
          Log.error(e);
        }
      }
      if (messageId == null) {
        Log.error('MessageId is empty for media file receipts');
        continue;
      }
      if (receipt.markForRetryAfterAccepted != null) {
        if (!contacts.containsKey(receipt.contactId)) {
          final contact = await twonlyDB.contactsDao
              .getContactByUserId(receipt.contactId)
              .getSingleOrNull();
          if (contact == null) {
            Log.error(
              'Contact does not exists, but has a record in receipts, this should not be possible, because of the DELETE CASCADE relation.',
            );
            continue;
          }
          contacts[receipt.contactId] = contact;
        }
        if (!(contacts[receipt.contactId]?.accepted ?? true)) {
          Log.warn(
            'Could not send message as contact has still not yet accepted.',
          );
          continue;
        }
      }

      if (receipt.ackByServerAt == null) {
        // media file must be reuploaded again in case the media files
        // was deleted by the server, the receiver will request a new media reupload

        final message = await twonlyDB.messagesDao
            .getMessageById(messageId)
            .getSingleOrNull();
        if (message == null || message.mediaId == null) {
          // The message or media file does not exists any more, so delete the receipt...
          if (message != null) {
            // The media file of the message does not exist anymore. Removing it...
            await twonlyDB.messagesDao.deleteMessagesById(messageId);
          }
          await twonlyDB.receiptsDao.deleteReceipt(receipt.receiptId);
          Log.warn(
            'Message not found for reupload of the receipt, likely deleted from sender (${message == null} - ${message?.mediaId}).',
          );
          continue;
        }

        final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(
          message.mediaId!,
        );
        if (mediaFile == null) {
          Log.error(
            'Mediafile not found for reupload of the receipt (${message.messageId} - ${message.mediaId}).',
          );
          continue;
        }
        await reuploadMediaFile(
          receipt.contactId,
          mediaFile,
          message.messageId,
        );
      } else {
        Log.info('Reuploading media file $messageId');
        // the media file should be still on the server, so it should be enough
        // to just resend the message containing the download token.
        await tryToSendCompleteMessage(receipt: receipt);
      }
    }
  });
}

Future<void> reuploadMediaFile(
  int contactId,
  MediaFile mediaFile,
  String messageId,
) async {
  Log.info('Reuploading media file: ${mediaFile.mediaId}');

  await twonlyDB.receiptsDao.updateReceiptByContactAndMessageId(
    contactId,
    messageId,
    const ReceiptsCompanion(
      markForRetry: Value(null),
      markForRetryAfterAccepted: Value(null),
    ),
  );

  final reuploadRequestedBy = (mediaFile.reuploadRequestedBy ?? [])
    ..add(contactId);
  await twonlyDB.mediaFilesDao.updateMedia(
    mediaFile.mediaId,
    MediaFilesCompanion(
      uploadState: const Value(UploadState.preprocessing),
      reuploadRequestedBy: Value(reuploadRequestedBy),
    ),
  );
  final mediaFileUpdated = await MediaFileService.fromMediaId(
    mediaFile.mediaId,
  );
  if (mediaFileUpdated != null) {
    if (mediaFileUpdated.uploadRequestPath.existsSync()) {
      mediaFileUpdated.uploadRequestPath.deleteSync();
    }
    unawaited(startBackgroundMediaUpload(mediaFileUpdated));
  }
}

Future<void> finishStartedPreprocessing() async {
  final mediaFiles = await twonlyDB.mediaFilesDao
      .getAllMediaFilesPendingUpload();

  for (final mediaFile in mediaFiles) {
    if (mediaFile.isDraftMedia) {
      Log.info('Ignoring media files as it is a draft');
      continue;
    }
    try {
      final service = MediaFileService(mediaFile);
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
      Log.info(
        'Finishing started preprocessing of ${mediaFile.mediaId} in state ${mediaFile.uploadState}.',
      );
      await startBackgroundMediaUpload(service);
    } catch (e) {
      Log.warn(e);
    }
  }
}

/// It can happen, that a media files is uploaded but not yet marked for been uploaded.
/// For example because the background_downloader plugin has not yet reported the finished upload.
/// In case the message receipts or a reaction was received, mark the media file as been uploaded.
Future<void> handleMediaRelatedResponseFromReceiver(String messageId) async {
  final message = await twonlyDB.messagesDao
      .getMessageById(messageId)
      .getSingleOrNull();
  if (message == null || message.mediaId == null) return;
  final media = await twonlyDB.mediaFilesDao.getMediaFileById(message.mediaId!);
  if (media == null) return;

  if (media.uploadState != UploadState.uploaded) {
    Log.info('Media was not yet marked as uploaded. Doing it now.');
    await markUploadAsSuccessful(media);
  }
}

Future<void> markUploadAsSuccessful(MediaFile media) async {
  await twonlyDB.mediaFilesDao.updateMedia(
    media.mediaId,
    const MediaFilesCompanion(
      uploadState: Value(UploadState.uploaded),
    ),
  );

  /// As the messages where send in a bulk acknowledge all messages.

  final messages = await twonlyDB.messagesDao.getMessagesByMediaId(
    media.mediaId,
  );
  for (final message in messages) {
    final contacts = await twonlyDB.groupsDao.getGroupNonLeftMembers(
      message.groupId,
    );
    for (final contact in contacts) {
      await twonlyDB.messagesDao.handleMessageAckByServer(
        contact.contactId,
        message.messageId,
        clock.now(),
      );
      await twonlyDB.receiptsDao.updateReceiptByContactAndMessageId(
        contact.contactId,
        message.messageId,
        ReceiptsCompanion(
          ackByServerAt: Value(clock.now()),
          retryCount: const Value(1),
          lastRetry: Value(clock.now()),
          markForRetry: const Value(null),
        ),
      );
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

  final mediaFile = await twonlyDB.mediaFilesDao.insertOrUpdateMedia(
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
  return MediaFileService(mediaFile);
}

Future<void> insertMediaFileInMessagesTable(
  MediaFileService mediaService,
  List<String> groupIds, {
  AdditionalMessageData? additionalData,
}) async {
  await twonlyDB.mediaFilesDao.updateAllMediaFiles(
    const MediaFilesCompanion(
      isDraftMedia: Value(false),
    ),
  );
  for (final groupId in groupIds) {
    final groupMembers = await twonlyDB.groupsDao.getGroupContact(groupId);
    if (groupMembers.length == 1) {
      if (groupMembers.first.accountDeleted) {
        Log.warn(
          'Did not send media file to $groupId because the only account has deleted his account.',
        );
        continue;
      }
    }

    final message = await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion(
        groupId: Value(groupId),
        mediaId: Value(mediaService.mediaFile.mediaId),
        type: Value(MessageType.media.name),
        additionalMessageData: Value.absentIfNull(
          additionalData?.writeToBuffer(),
        ),
      ),
    );
    await twonlyDB.groupsDao.increaseLastMessageExchange(groupId, clock.now());
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

    // if the user has enabled auto storing and the file
    // was send with unlimited counter not in twonly-Mode then store the file
    if (userService.currentUser.autoStoreAllSendUnlimitedMediaFiles &&
        !mediaService.mediaFile.requiresAuthentication &&
        !mediaService.storedPath.existsSync() &&
        mediaService.mediaFile.displayLimitInMilliseconds == null) {
      await mediaService.storeMediaFile();
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
      if (mediaService.originalPath.existsSync()) {
        mediaService.originalPath.deleteSync();
      }
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

  mediaService.encryptedPath.writeAsBytesSync(
    Uint8List.fromList(secretBox.cipherText),
  );
}

Future<void> _createUploadRequest(MediaFileService media) async {
  final downloadTokens = <Uint8List>[];

  final messagesOnSuccess = <TextMessage>[];

  final messages = await twonlyDB.messagesDao.getMessagesByMediaId(
    media.mediaFile.mediaId,
  );

  if (messages.isEmpty) {
    // There where no user selected who should receive the image, so waiting with this step...
    return;
  }

  for (final message in messages) {
    final groupMembers = await twonlyDB.groupsDao.getGroupNonLeftMembers(
      message.groupId,
    );

    if (media.mediaFile.reuploadRequestedBy == null) {
      await incFlameCounter(message.groupId, false, message.createdAt);
    }

    for (final groupMember in groupMembers) {
      /// only send the upload to the users
      if (media.mediaFile.reuploadRequestedBy != null) {
        if (!media.mediaFile.reuploadRequestedBy!.contains(
          groupMember.contactId,
        )) {
          continue;
        }
      }

      final contact = await twonlyDB.contactsDao.getContactById(
        groupMember.contactId,
      );

      if (contact == null || contact.accountDeleted) {
        continue;
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

      if (media.mediaFile.reuploadRequestedBy != null) {
        // not used any more... Receiver detects automatically if it is an reupload...
        // type = EncryptedContent_Media_Type.REUPLOAD;
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
          additionalMessageData: message.additionalMessageData,
        ),
      );

      if (media.mediaFile.displayLimitInMilliseconds != null) {
        notEncryptedContent.media.displayLimitInMilliseconds = Int64(
          media.mediaFile.displayLimitInMilliseconds!,
        );
      }

      final cipherText = await sendCipherText(
        groupMember.contactId,
        notEncryptedContent,
        messageId: message.messageId,
        onlyReturnEncryptedData: true,
      );

      if (cipherText == null) {
        Log.error(
          'Could not generate ciphertext message for ${groupMember.contactId}',
        );
        continue;
      }

      final messageOnSuccess = TextMessage()
        ..body = cipherText.$1
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

  if (uploadRequestBytes.length > 49_000_000) {
    await media.setUploadState(UploadState.fileLimitReached);

    await twonlyDB.messagesDao.updateMessagesByMediaId(
      media.mediaFile.mediaId,
      MessagesCompanion(
        openedAt: Value(DateTime.now()),
        ackByServer: Value(DateTime.now()),
      ),
    );
    return;
  }

  await media.uploadRequestPath.writeAsBytes(uploadRequestBytes);
}

Mutex protectUpload = Mutex();

Future<void> _uploadUploadRequest(MediaFileService media) async {
  await protectUpload.protect(() async {
    final currentMedia = await twonlyDB.mediaFilesDao.getMediaFileById(
      media.mediaFile.mediaId,
    );

    if (currentMedia == null ||
        currentMedia.uploadState == UploadState.backgroundUploadTaskStarted) {
      Log.info('Download for ${media.mediaFile.mediaId} already started.');
      return null;
    }

    final apiAuthTokenRaw = await const FlutterSecureStorage().read(
      key: SecureStorageKeys.apiAuthToken,
    );

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

    final connectivityResult = await Connectivity().checkConnectivity();

    if (AppState.isInBackgroundTask ||
        !connectivityResult.contains(ConnectivityResult.mobile) &&
            !connectivityResult.contains(ConnectivityResult.wifi)) {
      // no internet, directly put it into the background...
      await FileDownloader().enqueue(task);
      await media.setUploadState(UploadState.backgroundUploadTaskStarted);
      Log.info('Enqueue upload task: ${task.taskId}');
    } else {
      unawaited(uploadFileFastOrEnqueue(task, media));
    }
  });
}

Future<void> uploadFileFastOrEnqueue(
  UploadTask task,
  MediaFileService media,
) async {
  final requestMultipart = http.MultipartRequest(
    'POST',
    Uri.parse(task.url),
  );

  requestMultipart.headers.addAll(task.headers);

  requestMultipart.files.add(
    await http.MultipartFile.fromPath(
      'file',
      await task.filePath(),
      filename: 'upload',
    ),
  );

  try {
    final workmanagerUniqueName =
        'progressing_finish_uploads_${media.mediaFile.mediaId}';

    await Workmanager().registerOneOffTask(
      workmanagerUniqueName,
      'eu.twonly.processing_task',
      initialDelay: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    Log.info('Uploading fast: ${task.taskId}');

    final response = await requestMultipart.send();
    var status = TaskStatus.failed;
    if (response.statusCode == 200) {
      status = TaskStatus.complete;
    } else if (response.statusCode == 404) {
      status = TaskStatus.notFound;
    }

    await Workmanager().cancelByUniqueName(workmanagerUniqueName);

    await handleUploadStatusUpdate(
      TaskStatusUpdate(
        task,
        status,
        null,
        null,
        null,
        response.statusCode,
      ),
    );
  } catch (e) {
    Log.info('Upload failed enqueuing task...');
    await FileDownloader().enqueue(task);
    await media.setUploadState(UploadState.backgroundUploadTaskStarted);
  }
}
