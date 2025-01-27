import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:logging/logging.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/json/message.dart';

class DbMessage {
  DbMessage({
    required this.messageId,
    required this.messageOtherId,
    required this.otherUserId,
    required this.messageMessageKind,
    required this.messageContent,
    required this.messageOpenedAt,
    required this.messageAcknowledge,
    required this.sendOrReceivedAt,
  });

  int messageId;
  // is this null then the message was sent from the user itself
  int? messageOtherId;
  int otherUserId;
  MessageKind messageMessageKind;
  MessageContent messageContent;
  DateTime? messageOpenedAt;
  bool messageAcknowledge;
  DateTime sendOrReceivedAt;
}

class DbMessages extends CvModelBase {
  static const tableName = "messages";

  static const columnMessageId = "id";
  final messageId = CvField<int>(columnMessageId);

  static const columnMessageOtherId = "message_other_id";
  final messageOtherId = CvField<int?>(columnMessageOtherId);

  static const columnOtherUserId = "other_user_id";
  final otherUserId = CvField<int?>(columnOtherUserId);

  static const columnMessageKind = "message_kind";
  final messageMessageKind = CvField<int>(columnMessageKind);

  static const columnMessageContentJson = "message_json";
  final messageContentJson = CvField<String>(columnMessageContentJson);

  static const columnMessageOpenedAt = "message_opened_at";
  final messageOpenedAt = CvField<DateTime?>(columnMessageOpenedAt);

  static const columnMessageAcknowledge = "message_acknowledged";
  final messageAcknowledge = CvField<int>(columnMessageAcknowledge);

  static const columnSendOrReceivedAt = "message_send_or_received_at";
  final sendOrReceivedAt = CvField<DateTime>(columnSendOrReceivedAt);

  static const columnUpdatedAt = "updated_at";
  final updatedAt = CvField<DateTime>(columnUpdatedAt);

  static String getCreateTableString() {
    return """
      CREATE TABLE IF NOT EXISTS $tableName (
      $columnMessageId INTEGER NOT NULL PRIMARY KEY,
      $columnMessageOtherId INTEGER DEFAULT NULL,
      $columnOtherUserId INTEGER DEFAULT NULL,
      $columnMessageKind INTEGER NOT NULL,
      $columnMessageAcknowledge INTEGER NOT NULL DEFAULT 0,
      $columnMessageContentJson TEXT NOT NULL,
      $columnMessageOpenedAt DATETIME DEFAULT NULL,
      $columnSendOrReceivedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      $columnUpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """;
  }

  static Future<int?> insertMyMessage(
      int userIdFrom, MessageKind kind, String jsonContent) async {
    try {
      int messageId = await dbProvider.db!.insert(tableName, {
        columnMessageKind: kind.index,
        columnMessageContentJson: jsonContent,
        columnOtherUserId: userIdFrom,
        columnSendOrReceivedAt: DateTime.now().toIso8601String()
      });
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
        columnOtherUserId: userIdFrom
      });
      return true;
    } catch (e) {
      Logger("contacts_model/getUsers").shout("$e");
      return false;
    }
  }

  static List<DbMessage> convertToDbMessage(List<dynamic> fromDb) {
    try {
      List<DbMessage> parsedUsers = [];
      for (int i = 0; i < fromDb.length; i++) {
        dynamic messageOpenedAt = fromDb[i][columnMessageOpenedAt];
        if (messageOpenedAt != null) {
          messageOpenedAt = DateTime.tryParse(fromDb[i][columnMessageOpenedAt]);
        }
        print("Datetime: ${fromDb[i][columnSendOrReceivedAt]}");
        print(
            "Datetime parsed: ${DateTime.tryParse(fromDb[i][columnSendOrReceivedAt])}");
        parsedUsers.add(
          DbMessage(
            sendOrReceivedAt:
                DateTime.tryParse(fromDb[i][columnSendOrReceivedAt])!,
            messageId: fromDb[i][columnMessageId],
            messageOtherId: fromDb[i][columnMessageOtherId],
            otherUserId: fromDb[i][columnOtherUserId],
            messageMessageKind:
                MessageKindExtension.fromIndex(fromDb[i][columnMessageKind]),
            messageContent: MessageContent.fromJson(
                jsonDecode(fromDb[i][columnMessageContentJson])),
            messageOpenedAt: messageOpenedAt,
            messageAcknowledge: fromDb[i][columnMessageAcknowledge] == 1,
          ),
        );
      }
      return parsedUsers;
    } catch (e) {
      Logger("messages_model/convertToDbMessage").shout("$e");
      return [];
    }
  }

  static Future<DbMessage?> getLastMessagesForPreviewForUser(
      int otherUserId) async {
    var rows = await dbProvider.db!.query(tableName,
        where: "$columnOtherUserId = ?",
        whereArgs: [otherUserId],
        orderBy: "$columnUpdatedAt DESC",
        limit: 1);

    List<DbMessage> messages = convertToDbMessage(rows);
    if (messages.isEmpty) return null;
    return messages[0];
  }

  static Future acknowledgeMessage(int fromUserId, int messageId) async {
    Map<String, dynamic> valuesToUpdate = {
      columnMessageAcknowledge: 1,
    };
    await dbProvider.db!.update(
      tableName,
      valuesToUpdate,
      where: "$messageId = ? AND $columnOtherUserId = ?",
      whereArgs: [messageId, fromUserId],
    );
  }

  @override
  List<CvField> get fields => [
        messageId,
        messageMessageKind,
        messageContentJson,
        messageOpenedAt,
        sendOrReceivedAt
      ];
}
