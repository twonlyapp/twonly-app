import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart'
    hide Message;
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/signal/session.signal.dart';

class Result<T, E> {
  Result.error(this.error) : value = null;
  Result.success(this.value) : error = null;

  final T? value;
  final E? error;

  bool get isSuccess => value != null;
  bool get isError => error != null;
}

DateTime fromTimestamp(Int64 timeStamp) {
  return DateTime.fromMillisecondsSinceEpoch(timeStamp.toInt());
}

// ignore: strict_raw_type
Result asResult(server.ServerToClient? msg) {
  if (msg == null) {
    return Result.error(ErrorCode.InternalError);
  }
  if (msg.v0.response.hasOk()) {
    return Result.success(msg.v0.response.ok);
  } else {
    return Result.error(msg.v0.response.error);
  }
}

ClientToServer createClientToServerFromHandshake(Handshake handshake) {
  final v0 = client.V0()
    ..seq = Int64()
    ..handshake = handshake;
  return ClientToServer()..v0 = v0;
}

ClientToServer createClientToServerFromApplicationData(
  ApplicationData applicationData,
) {
  final v0 = client.V0()
    ..seq = Int64()
    ..applicationdata = applicationData;
  return ClientToServer()..v0 = v0;
}

Future<void> rejectAndDeleteContact(int contactId) async {
  await sendCipherText(
    contactId,
    EncryptedContent(
      contactRequest: EncryptedContent_ContactRequest(
        type: EncryptedContent_ContactRequest_Type.REJECT,
      ),
    ),
  );
  await twonlyDB.signalDao.deleteAllByContactId(contactId);
  await deleteSessionWithTarget(contactId);
  await twonlyDB.contactsDao.deleteContactByUserId(contactId);
}

Future<void> handleMediaError(MediaFile media) async {
  await twonlyDB.mediaFilesDao.updateMedia(
    media.mediaId,
    const MediaFilesCompanion(
      downloadState: Value(DownloadState.reuploadRequested),
    ),
  );
  final messages =
      await twonlyDB.messagesDao.getMessagesByMediaId(media.mediaId);
  if (messages.length != 1) return;
  final message = messages.first;
  if (message.senderId == null) return;
  await sendCipherText(
    message.senderId!,
    EncryptedContent(
      mediaUpdate: EncryptedContent_MediaUpdate(
        type: EncryptedContent_MediaUpdate_Type.DECRYPTION_ERROR,
        targetMessageId: message.messageId,
      ),
    ),
  );
}
