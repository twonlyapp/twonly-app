import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/core/bridge/callbacks.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/callbacks/legacy_signal.callbacks.dart';
import 'package:twonly/src/callbacks/logging.callbacks.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/model/protobuf/client/generated/push_notification.pb.dart'
    as push_pb;
import 'package:twonly/src/services/api/client2client/errors.c2c.dart';
import 'package:twonly/src/services/api/mediafiles/download.api.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/group.service.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/avatars.dart';

Future<Uint8List?> _apiCreatePushData(
  int contactId,
  String? messageId,
  Uint8List plaintext,
  int messageType,
) async {
  final notification = messageType == pb.Message_Type.TEST_NOTIFICATION.value
      ? push_pb.PushNotification(kind: push_pb.PushKind.TEST_NOTIFICATION)
      : await getPushNotificationFromEncryptedContent(
          contactId,
          messageId,
          pb.EncryptedContent.fromBuffer(plaintext),
        );
  if (notification == null) return null;
  return encryptPushNotification(contactId, notification);
}

Future<void> _apiMediaAction(
  String kind,
  String mediaId,
  int contactId,
  String messageId,
) async {
  if (kind == 'response') {
    await handleMediaRelatedResponseFromReceiver(messageId);
    return;
  }
  if (kind == 'delete') {
    final media = await MediaFileService.fromMediaId(mediaId);
    media?.fullMediaRemoval();
    return;
  }
  final media = await twonlyDB.mediaFilesDao.getMediaFileById(mediaId);
  if (media == null) return;
  switch (kind) {
    case 'download':
      await startDownloadMedia(media, false);
    case 'stored':
      await MediaFileService(media).storeMediaFile();
    case 'reupload':
      await reuploadMediaFile(contactId, media, messageId);
  }
}

Future<void> _apiGroupStateRefresh(String groupId, bool created) async {
  if (created) {
    await fetchGroupStatesForUnjoinedGroups();
    final group = await twonlyDB.groupsDao.getGroup(groupId);
    if (group?.myGroupPrivateKey == null) return;
    final key = IdentityKeyPair.fromSerialized(group!.myGroupPrivateKey!);
    await sendCipherTextToGroup(
      groupId,
      pb.EncryptedContent(
        groupJoin: pb.EncryptedContent_GroupJoin(
          groupPublicKey: key.getPublicKey().serialize(),
        ),
      ),
    );
    return;
  }
  final group = await twonlyDB.groupsDao.getGroup(groupId);
  if (group != null) await fetchGroupState(group);
}

Future<void> initFlutterCallbacksForRust() async {
  await initFlutterCallbacks(
    callbackId: isolateCallbackId,
    loggingGetStreamSink: LoggingCallbacks.getStreamSink,
    legacySignalDecrypt: LegacySignalCallbacks.decrypt,
    legacySignalEncrypt: LegacySignalCallbacks.encrypt,
    legacySignalGeneratePrekeys: LegacySignalCallbacks.generatePrekeys,
    apiResyncSignalSession: handleSessionResync,
    apiPushKeyRequested: (contactId) =>
        setupNotificationWithUsers(forceContact: contactId),
    apiGroupMembershipError: (contactId, groupId, relatedReceiptId) =>
        handleErrorMessage(
          contactId,
          pb.EncryptedContent_ErrorMessages(
            type: pb
                .EncryptedContent_ErrorMessages_Type
                .GROUP_NOT_FOUND_OR_NOT_A_MEMBER,
            relatedReceiptId: relatedReceiptId,
          ),
          relatedReceiptId,
          groupId: groupId,
        ),
    apiMediaAction: _apiMediaAction,
    apiVerificationProof: KeyVerificationService.handleVerificationProof,
    apiCreatePushData: _apiCreatePushData,
    apiCreatePushAvatars: (contactId) =>
        createPushAvatars(forceForUserId: contactId),
    apiRecoveryChanged: PasswordlessRecoveryService.performHeartbeat,
    apiMediaReceived: (groupId, timestamp) => incFlameCounter(
      groupId,
      true,
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    ),
    apiGroupStateRefresh: _apiGroupStateRefresh,
  );
}
