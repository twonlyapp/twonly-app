import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:logging/logging.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/model/json/message.dart';

class DbMessage {
  DbMessage({
    required this.messageId,
    required this.messageOtherId,
    required this.otherUserId,
    required this.messageMessageKind,
    required this.messageContent,
    required this.messageOpenedAt,
    required this.messageAcknowledgeByUser,
    required this.messageAcknowledgeByServer,
    required this.sendOrReceivedAt,
  });

  int messageId;
  // is this null then the message was sent from the user itself
  int? messageOtherId;
  int otherUserId;
  MessageKind messageMessageKind;
  MessageContent? messageContent;
  DateTime? messageOpenedAt;
  bool messageAcknowledgeByUser;
  bool messageAcknowledgeByServer;
  DateTime sendOrReceivedAt;
}

class DbMessages extends CvModelBase {
  static const tableName = "messages";

  static const columnMessageId = "id";
  final messageId = CvField<int>(columnMessageId);

  static const columnMessageOtherId = "message_other_id";
  final messageOtherId = CvField<int?>(columnMessageOtherId);

  static const columnOtherUserId = "other_user_id";
  final otherUserId = CvField<int>(columnOtherUserId);

  static const columnMessageKind = "message_kind";
  final messageMessageKind = CvField<int>(columnMessageKind);

  static const columnMessageContentJson = "message_json";
  final messageContentJson = CvField<String?>(columnMessageContentJson);

  static const columnMessageOpenedAt = "message_opened_at";
  final messageOpenedAt = CvField<DateTime?>(columnMessageOpenedAt);

  static const columnMessageAcknowledgeByUser = "message_acknowledged_by_user";
  final messageAcknowledgeByUser = CvField<int>(columnMessageAcknowledgeByUser);

  static const columnMessageAcknowledgeByServer =
      "message_acknowledged_by_server";
  final messageAcknowledgeByServer =
      CvField<int>(columnMessageAcknowledgeByServer);

  static const columnSendOrReceivedAt = "message_send_or_received_at";
  final sendOrReceivedAt = CvField<DateTime>(columnSendOrReceivedAt);

  static const columnUpdatedAt = "updated_at";
  final updatedAt = CvField<DateTime>(columnUpdatedAt);

  static String getCreateTableString() {
    return """
      CREATE TABLE IF NOT EXISTS $tableName (
      $columnMessageId INTEGER NOT NULL PRIMARY KEY,
      $columnMessageOtherId INTEGER DEFAULT NULL,
      $columnOtherUserId INTEGER NOT NULL,
      $columnMessageKind INTEGER NOT NULL,
      $columnMessageAcknowledgeByUser INTEGER NOT NULL DEFAULT 0,
      $columnMessageAcknowledgeByServer INTEGER NOT NULL DEFAULT 0,
      $columnMessageContentJson TEXT DEFAULT NULL,
      $columnMessageOpenedAt DATETIME DEFAULT NULL,
      $columnSendOrReceivedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      $columnUpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """;
  }

  static Future deleteMessageById(int messageId) async {
    await dbProvider.db!.delete(
      tableName,
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
    int? fromUserId = await getFromUserIdByMessageId(messageId);
    if (fromUserId != null) {
      globalCallBackOnMessageChange(fromUserId);
    }
  }

  static Future<int?> getFromUserIdByMessageId(int messageId) async {
    List<Map<String, dynamic>> result = await dbProvider.db!.query(
      tableName,
      columns: [columnOtherUserId],
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
    if (result.isNotEmpty) {
      return result.first[columnOtherUserId] as int?;
    }
    return null;
  }

  static Future<int?> insertMyMessage(int userIdFrom, MessageKind kind,
      {String? jsonContent}) async {
    try {
      int messageId = await dbProvider.db!.insert(tableName, {
        columnMessageKind: kind.index,
        columnMessageContentJson: jsonContent,
        columnOtherUserId: userIdFrom,
        columnSendOrReceivedAt: DateTime.now().toIso8601String()
      });
      globalCallBackOnMessageChange(userIdFrom);
      return messageId;
    } catch (e) {
      Logger("contacts_model/getUsers").shout("$e");
      return null;
    }
  }

  static Future insertOtherMessage(int userIdFrom, MessageKind kind,
      int messageId, String jsonContent) async {
    try {
      await dbProvider.db!.insert(tableName, {
        columnMessageOtherId: messageId,
        columnMessageKind: kind.index,
        columnMessageContentJson: jsonContent,
        columnMessageAcknowledgeByServer: 1,
        columnMessageAcknowledgeByUser:
            0, // ack in case of sending corresponds to the opened flag
        columnOtherUserId: userIdFrom
      });
      globalCallBackOnMessageChange(userIdFrom);
      return true;
    } catch (e) {
      Logger("contacts_model/getUsers").shout("$e");
      return false;
    }
  }

  static Future<DbMessage?> getLastMessagesForPreviewForUser(
      int otherUserId) async {
    var rows = await dbProvider.db!.query(
      tableName,
      where: "$columnOtherUserId = ?",
      whereArgs: [otherUserId],
      orderBy: "$columnUpdatedAt DESC",
      limit: 10,
    );

    List<DbMessage> messages = convertToDbMessage(rows);

    // check if there is a message which was not ack by the server
    List<DbMessage> notAckByServer =
        messages.where((c) => !c.messageAcknowledgeByServer).toList();
    if (notAckByServer.isNotEmpty) return notAckByServer[0];

    // check if there is a message which was not ack by the user
    List<DbMessage> notAckByUser =
        messages.where((c) => !c.messageAcknowledgeByUser).toList();
    if (notAckByUser.isNotEmpty) return notAckByUser[0];

    if (messages.isEmpty) return null;
    return messages[0];
  }

  static Future acknowledgeMessageByServer(int messageId) async {
    Map<String, dynamic> valuesToUpdate = {
      columnMessageAcknowledgeByServer: 1,
    };
    await dbProvider.db!.update(
      tableName,
      valuesToUpdate,
      where: "$messageId = ?",
      whereArgs: [messageId],
    );
    int? fromUserId = await getFromUserIdByMessageId(messageId);
    if (fromUserId != null) {
      globalCallBackOnMessageChange(fromUserId);
    }
  }

  // check fromUserId to prevent spoofing
  static Future acknowledgeMessageByUser(int fromUserId, int messageId) async {
    Map<String, dynamic> valuesToUpdate = {
      columnMessageAcknowledgeByUser: 1,
    };
    await dbProvider.db!.update(
      tableName,
      valuesToUpdate,
      where: "$messageId = ? AND $columnOtherUserId = ?",
      whereArgs: [messageId, fromUserId],
    );
    globalCallBackOnMessageChange(fromUserId);
  }

  @override
  List<CvField> get fields => [
        messageId,
        messageMessageKind,
        messageContentJson,
        messageOpenedAt,
        sendOrReceivedAt
      ];

  static List<DbMessage> convertToDbMessage(List<dynamic> fromDb) {
    try {
      List<DbMessage> parsedUsers = [];
      for (int i = 0; i < fromDb.length; i++) {
        dynamic messageOpenedAt = fromDb[i][columnMessageOpenedAt];
        if (messageOpenedAt != null) {
          messageOpenedAt = DateTime.tryParse(fromDb[i][columnMessageOpenedAt]);
        }
        dynamic content = fromDb[i][columnMessageContentJson];
        if (content != null) {
          content = MessageContent.fromJson(
              jsonDecode(fromDb[i][columnMessageContentJson]));
        }
        parsedUsers.add(
          DbMessage(
            sendOrReceivedAt:
                DateTime.tryParse(fromDb[i][columnSendOrReceivedAt])!,
            messageId: fromDb[i][columnMessageId],
            messageOtherId: fromDb[i][columnMessageOtherId],
            otherUserId: fromDb[i][columnOtherUserId],
            messageMessageKind:
                MessageKindExtension.fromIndex(fromDb[i][columnMessageKind]),
            messageContent: content,
            messageOpenedAt: messageOpenedAt,
            messageAcknowledgeByUser:
                fromDb[i][columnMessageAcknowledgeByUser] == 1,
            messageAcknowledgeByServer:
                fromDb[i][columnMessageAcknowledgeByServer] == 1,
          ),
        );
      }
      return parsedUsers;
    } catch (e) {
      Logger("messages_model/convertToDbMessage").shout("$e");
      return [];
    }
  }
}
