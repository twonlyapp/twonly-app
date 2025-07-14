import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
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
  var v0 = client.V0()
    ..seq = Int64(0)
    ..handshake = handshake;
  return ClientToServer()..v0 = v0;
}

ClientToServer createClientToServerFromApplicationData(
    ApplicationData applicationData) {
  final v0 = client.V0()
    ..seq = Int64(0)
    ..applicationdata = applicationData;
  return ClientToServer()..v0 = v0;
}

Future<void> deleteContact(int contactId) async {
  await twonlyDB.messagesDao.deleteAllMessagesByContactId(contactId);
  await twonlyDB.signalDao.deleteAllByContactId(contactId);
  await deleteSessionWithTarget(contactId);
  await twonlyDB.contactsDao.deleteContactByUserId(contactId);
}

Future<void> rejectUser(int contactId) async {
  await encryptAndSendMessageAsync(
    null,
    contactId,
    MessageJson(
      kind: MessageKind.rejectRequest,
      timestamp: DateTime.now(),
      content: MessageContent(),
    ),
  );
}

Future<void> handleMediaError(Message message) async {
  await twonlyDB.messagesDao.updateMessageByMessageId(
    message.messageId,
    const MessagesCompanion(
      errorWhileSending: Value(true),
      mediaRetransmissionState: Value(
        MediaRetransmitting.requested,
      ),
    ),
  );
  if (message.messageOtherId != null) {
    await encryptAndSendMessageAsync(
      null,
      message.contactId,
      MessageJson(
        kind: MessageKind.receiveMediaError,
        timestamp: DateTime.now(),
        content: MessageContent(),
        messageReceiverId: message.messageOtherId,
      ),
    );
  }
}
