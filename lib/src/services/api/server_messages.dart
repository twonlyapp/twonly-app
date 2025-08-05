// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/media_uploads_table.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/services/api/media_download.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/thumbnail.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

final lockHandleServerMessage = Mutex();

Future<void> handleServerMessage(server.ServerToClient msg) async {
  return lockHandleServerMessage.protect(() async {
    client.Response? response;

    try {
      if (msg.v0.hasRequestNewPreKeys()) {
        response = await handleRequestNewPreKey();
      } else if (msg.v0.hasNewMessage()) {
        final body = Uint8List.fromList(msg.v0.newMessage.body);
        final fromUserId = msg.v0.newMessage.fromUserId.toInt();
        response = await handleNewMessage(fromUserId, body);
      } else {
        Log.error('Got a new message from the server: $msg');
        response = client.Response()..error = ErrorCode.InternalError;
      }
    } catch (e) {
      response = client.Response()..error = ErrorCode.InternalError;
    }

    final v0 = client.V0()
      ..seq = msg.v0.seq
      ..response = response;

    await apiService.sendResponse(ClientToServer()..v0 = v0);
  });
}

DateTime lastSignalDecryptMessage =
    DateTime.now().subtract(const Duration(hours: 1));
DateTime lastPushKeyRequest = DateTime.now().subtract(const Duration(hours: 1));

bool messageGetsAck(MessageKind kind) {
  return kind != MessageKind.pushKey && kind != MessageKind.ack;
}

Future<client.Response> handleNewMessage(int fromUserId, Uint8List body) async {
  final message = await signalDecryptMessage(fromUserId, body);
  if (message == null) {
    final encryptedHash = (await Sha256().hash(body)).bytes;
    await encryptAndSendMessageAsync(
      null,
      fromUserId,
      MessageJson(
        kind: MessageKind.signalDecryptError,
        content: SignalDecryptErrorContent(encryptedHash: encryptedHash),
        timestamp: DateTime.now(),
      ),
    );

    Log.error('Could not decrypt others message!');

    // Message is not valid, so server can delete it
    final ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  Log.info('Got: ${message.kind} from $fromUserId');

  if (messageGetsAck(message.kind) && message.retransId != null) {
    Log.info('Sending ACK for ${message.kind}');

    /// ACK every message
    await encryptAndSendMessageAsync(
      null,
      fromUserId,
      MessageJson(
        kind: MessageKind.ack,
        content: AckContent(
          messageIdToAck: message.messageSenderId,
          retransIdToAck: message.retransId!,
        ),
        timestamp: DateTime.now(),
      ),
    );
  }

  switch (message.kind) {
    case MessageKind.ack:
      final content = message.content;
      if (content is AckContent) {
        if (content.messageIdToAck != null) {
          const update = MessagesCompanion(
            acknowledgeByUser: Value(true),
            errorWhileSending: Value(false),
          );
          await twonlyDB.messagesDao.updateMessageByOtherUser(
            fromUserId,
            content.messageIdToAck!,
            update,
          );
        }

        await twonlyDB.messageRetransmissionDao
            .deleteRetransmissionById(content.retransIdToAck);
      }
    case MessageKind.signalDecryptError:
      Log.error(
          'Got signal decrypt error from other user! Sending all non ACK messages again.');

      final content = message.content;
      if (content is SignalDecryptErrorContent) {
        final hash = Uint8List.fromList(content.encryptedHash);
        await twonlyDB.messageRetransmissionDao.resetAckStatusFor(
          fromUserId,
          hash,
        );
        final message = await twonlyDB.messageRetransmissionDao
            .getRetransmissionFromHash(fromUserId, hash);
        if (message != null) {
          unawaited(sendRetransmitMessage(message.retransmissionId));
        }
      }

    case MessageKind.contactRequest:
      return handleContactRequest(fromUserId, message);

    case MessageKind.flameSync:
      final contact = await twonlyDB.contactsDao
          .getContactByUserId(fromUserId)
          .getSingleOrNull();
      if (contact != null && contact.lastFlameCounterChange != null) {
        final content = message.content;
        if (content is FlameSyncContent) {
          var updates = ContactsCompanion(
            alsoBestFriend: Value(content.bestFriend),
          );
          if (isToday(contact.lastFlameCounterChange!) &&
              isToday(content.lastFlameCounterChange)) {
            if (content.flameCounter > contact.flameCounter) {
              updates = ContactsCompanion(
                alsoBestFriend: Value(content.bestFriend),
                flameCounter: Value(content.flameCounter),
              );
            }
          }
          await twonlyDB.contactsDao.updateContact(fromUserId, updates);
        }
      }

    case MessageKind.receiveMediaError:
      if (message.messageReceiverId != null) {
        final openedMessage = await twonlyDB.messagesDao
            .getMessageByIdAndContactId(fromUserId, message.messageReceiverId!)
            .getSingleOrNull();

        if (openedMessage != null) {
          /// message found

          /// checks if
          ///   1. this was a media upload
          ///   2. the media was not already retransmitted
          ///   3. the media was send in the last two days
          if (openedMessage.mediaUploadId != null &&
              openedMessage.mediaRetransmissionState ==
                  MediaRetransmitting.none &&
              openedMessage.sendAt
                  .isAfter(DateTime.now().subtract(const Duration(days: 2)))) {
            // reset the media upload state to pending,
            // this will cause the media to be re-encrypted again
            await twonlyDB.mediaUploadsDao.updateMediaUpload(
              openedMessage.mediaUploadId!,
              const MediaUploadsCompanion(
                state: Value(
                  UploadState.pending,
                ),
              ),
            );
            // reset the message upload so the upload will be done again
            await twonlyDB.messagesDao.updateMessageByOtherUser(
              fromUserId,
              message.messageReceiverId!,
              const MessagesCompanion(
                downloadState: Value(DownloadState.pending),
                mediaRetransmissionState:
                    Value(MediaRetransmitting.retransmitted),
              ),
            );
            unawaited(retryMediaUpload(false));
          } else {
            await twonlyDB.messagesDao.updateMessageByOtherUser(
              fromUserId,
              message.messageReceiverId!,
              const MessagesCompanion(
                errorWhileSending: Value(true),
              ),
            );
          }
        }
      }

    case MessageKind.opened:
      if (message.messageReceiverId != null) {
        final update = MessagesCompanion(
          openedAt: Value(message.timestamp),
          errorWhileSending: const Value(false),
        );
        await twonlyDB.messagesDao.updateMessageByOtherUser(
          fromUserId,
          message.messageReceiverId!,
          update,
        );
        final openedMessage = await twonlyDB.messagesDao
            .getMessageByMessageId(message.messageReceiverId!)
            .getSingleOrNull();
        if (openedMessage != null &&
            openedMessage.kind == MessageKind.textMessage) {
          await twonlyDB.messagesDao.openedAllNonMediaMessagesFromOtherUser(
            fromUserId,
          );
        }
      }

    case MessageKind.rejectRequest:
      await deleteContact(fromUserId);

    case MessageKind.acceptRequest:
      const update = ContactsCompanion(accepted: Value(true));
      await twonlyDB.contactsDao.updateContact(fromUserId, update);
      unawaited(notifyContactsAboutProfileChange());

    case MessageKind.profileChange:
      final content = message.content;
      if (content is ProfileContent) {
        final update = ContactsCompanion(
          avatarSvg: Value(content.avatarSvg),
          displayName: Value(content.displayName),
        );
        await twonlyDB.contactsDao.updateContact(fromUserId, update);
      }
      unawaited(createPushAvatars());

    case MessageKind.requestPushKey:
      if (lastPushKeyRequest
          .isBefore(DateTime.now().subtract(const Duration(seconds: 60)))) {
        lastPushKeyRequest = DateTime.now();
        unawaited(setupNotificationWithUsers(forceContact: fromUserId));
      }

    case MessageKind.pushKey:
      if (message.content != null) {
        final pushKey = message.content!;
        if (pushKey is PushKeyContent) {
          await handleNewPushKey(fromUserId, pushKey);
        }
      }

    // ignore: no_default_cases
    default:
      if (message.kind != MessageKind.textMessage &&
          message.kind != MessageKind.media &&
          message.kind != MessageKind.storedMediaFile &&
          message.kind != MessageKind.reopenedMedia) {
        Log.error('Got unknown MessageKind $message');
      } else if (message.messageSenderId == null) {
        Log.error('Messageid not defined $message');
      } else {
        if (message.kind == MessageKind.storedMediaFile) {
          if (message.messageReceiverId != null) {
            /// stored media file just updates the message
            await twonlyDB.messagesDao.updateMessageByOtherUser(
              fromUserId,
              message.messageReceiverId!,
              const MessagesCompanion(
                mediaStored: Value(true),
                errorWhileSending: Value(false),
              ),
            );
            final msg = await twonlyDB.messagesDao
                .getMessageByIdAndContactId(
                    fromUserId, message.messageReceiverId!)
                .getSingleOrNull();
            if (msg != null && msg.mediaUploadId != null) {
              final filePath =
                  await getMediaFilePath(msg.mediaUploadId, 'send');
              if (filePath.contains('mp4')) {
                unawaited(createThumbnailsForVideo(File(filePath)));
              } else {
                unawaited(createThumbnailsForImage(File(filePath)));
              }
            }
          }
        } else if (message.content != null) {
          final content = message.content!;
          // when a message is received doubled ignore it...

          final openedMessage = await twonlyDB.messagesDao
              .getMessageByOtherMessageId(fromUserId, message.messageSenderId!)
              .getSingleOrNull();

          if (openedMessage != null) {
            if (openedMessage.errorWhileSending) {
              await twonlyDB.messagesDao
                  .deleteMessagesByMessageId(openedMessage.messageId);
            } else {
              Log.error(
                  'Got a duplicated message from other user: ${message.messageSenderId!}');
              final ok = client.Response_Ok()..none = true;
              return client.Response()..ok = ok;
            }
          }

          int? responseToMessageId;
          int? responseToOtherMessageId;
          int? messageId;

          var acknowledgeByUser = false;
          DateTime? openedAt;

          if (message.kind == MessageKind.reopenedMedia) {
            acknowledgeByUser = true;
            openedAt = DateTime.now();
          }

          if (content is TextMessageContent) {
            responseToMessageId = content.responseToMessageId;
            responseToOtherMessageId = content.responseToOtherMessageId;

            if (responseToMessageId != null ||
                responseToOtherMessageId != null) {
              // reactions are shown in the notification directly...
              if (isEmoji(content.text)) {
                openedAt = DateTime.now();
              }
            }
          }
          if (content is ReopenedMediaFileContent) {
            responseToMessageId = content.messageId;
          }

          if (responseToMessageId != null) {
            await twonlyDB.messagesDao.updateMessageByOtherUser(
              fromUserId,
              responseToMessageId,
              MessagesCompanion(
                errorWhileSending: const Value(false),
                openedAt: Value(
                  DateTime.now(),
                ), // when a user reacted to the media file, it should be marked as opened
              ),
            );
          }

          final contentJson = jsonEncode(content.toJson());
          final update = MessagesCompanion(
            contactId: Value(fromUserId),
            kind: Value(message.kind),
            messageOtherId: Value(message.messageSenderId),
            contentJson: Value(contentJson),
            acknowledgeByServer: const Value(true),
            acknowledgeByUser: Value(acknowledgeByUser),
            responseToMessageId: Value(responseToMessageId),
            responseToOtherMessageId: Value(responseToOtherMessageId),
            openedAt: Value(openedAt),
            downloadState: Value(message.kind == MessageKind.media
                ? DownloadState.pending
                : DownloadState.downloaded),
            sendAt: Value(message.timestamp),
          );

          messageId = await twonlyDB.messagesDao.insertMessage(
            update,
          );

          if (messageId == null) {
            Log.error('could not insert message into db');
            return client.Response()..error = ErrorCode.InternalError;
          }

          Log.info('Inserted a new message with id: $messageId');

          if (message.kind == MessageKind.media) {
            await twonlyDB.contactsDao.incFlameCounter(
              fromUserId,
              true,
              message.timestamp,
            );

            final msg = await twonlyDB.messagesDao
                .getMessageByMessageId(messageId)
                .getSingleOrNull();
            if (msg != null) {
              unawaited(startDownloadMedia(msg, false));
            }
          }
        } else {
          Log.error('Content is not defined $message');
        }

        // unarchive contact when receiving a new message
        await twonlyDB.contactsDao.updateContact(
          fromUserId,
          const ContactsCompanion(
            archived: Value(false),
          ),
        );
      }
  }
  final ok = client.Response_Ok()..none = true;
  return client.Response()..ok = ok;
}

Future<client.Response> handleRequestNewPreKey() async {
  final localPreKeys = await signalGetPreKeys();

  final prekeysList = <client.Response_PreKey>[];
  for (var i = 0; i < localPreKeys.length; i++) {
    prekeysList.add(client.Response_PreKey()
      ..id = Int64(localPreKeys[i].id)
      ..prekey = localPreKeys[i].getKeyPair().publicKey.serialize());
  }
  final prekeys = client.Response_Prekeys(prekeys: prekeysList);
  final ok = client.Response_Ok()..prekeys = prekeys;
  return client.Response()..ok = ok;
}

Future<client.Response> handleContactRequest(
    int fromUserId, MessageJson message) async {
  // request the username by the server so an attacker can not
  // forge the displayed username in the contact request
  final username = await apiService.getUsername(fromUserId);
  if (username.isSuccess) {
    final name = username.value.userdata.username as Uint8List;
    await twonlyDB.contactsDao.insertContact(
      ContactsCompanion(
        username: Value(utf8.decode(name)),
        userId: Value(fromUserId),
        requested: const Value(true),
      ),
    );
  }
  await setupNotificationWithUsers();
  final ok = client.Response_Ok()..none = true;
  return client.Response()..ok = ok;
}
