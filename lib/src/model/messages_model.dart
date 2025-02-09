import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';

class DbMessage {
  DbMessage({
    required this.messageId,
    required this.messageOtherId,
    required this.otherUserId,
    required this.messageContent,
    required this.messageOpenedAt,
    required this.messageAcknowledgeByUser,
    required this.isDownloaded,
    required this.messageAcknowledgeByServer,
    required this.sendAt,
  });

  int messageId;
  // is this null then the message was sent from the user itself
  int? messageOtherId;
  int otherUserId;
  MessageContent messageContent;
  DateTime? messageOpenedAt;
  bool messageAcknowledgeByUser;
  bool isDownloaded;
  bool messageAcknowledgeByServer;
  DateTime sendAt;

  bool containsOtherMedia() {
    if (messageOtherId == null) return false;
    return isMedia();
  }

  bool get messageReceived => messageOtherId != null;

  bool isMedia() {
    return messageContent is MediaMessageContent;
  }

  MessageSendState getSendState() {
    MessageSendState state;
    if (!messageAcknowledgeByServer) {
      state = MessageSendState.sending;
    } else {
      if (messageOtherId == null) {
        // message send
        if (messageOpenedAt == null) {
          state = MessageSendState.send;
        } else {
          state = MessageSendState.sendOpened;
        }
      } else {
        // message received
        if (messageOpenedAt == null) {
          state = MessageSendState.received;
        } else {
          state = MessageSendState.receivedOpened;
        }
      }
    }
    return state;
  }
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
  final messageKind = CvField<int>(columnMessageKind);

  static const columnMessageContentJson = "message_json";
  final messageContentJson = CvField<String>(columnMessageContentJson);

  static const columnMessageOpenedAt = "message_opened_at";
  final messageOpenedAt = CvField<DateTime?>(columnMessageOpenedAt);

  static const columnMessageAcknowledgeByUser = "message_acknowledged_by_user";
  final messageAcknowledgeByUser = CvField<int>(columnMessageAcknowledgeByUser);

  static const columnMessageAcknowledgeByServer =
      "message_acknowledged_by_server";
  final messageAcknowledgeByServer =
      CvField<int>(columnMessageAcknowledgeByServer);

  static const columnSendAt = "message_send_or_received_at";
  final sendAt = CvField<DateTime>(columnSendAt);

  static const columnUpdatedAt = "updated_at";
  final updatedAt = CvField<DateTime>(columnUpdatedAt);

  static Future setupDatabaseTable(Database db) async {
    String createTableString = """
      CREATE TABLE IF NOT EXISTS $tableName (
      $columnMessageId INTEGER NOT NULL PRIMARY KEY,
      $columnMessageOtherId INTEGER DEFAULT NULL,
      $columnOtherUserId INTEGER NOT NULL,
      $columnMessageKind INTEGER NOT NULL,
      $columnMessageAcknowledgeByUser INTEGER NOT NULL DEFAULT 0,
      $columnMessageAcknowledgeByServer INTEGER NOT NULL DEFAULT 0,
      $columnMessageContentJson TEXT NOT NULL,
      $columnMessageOpenedAt DATETIME DEFAULT NULL,
      $columnSendAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      $columnUpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """;
    await db.execute(createTableString);
  }

  static Future<List<(DateTime, int?)>> getMessageDates(int otherUserId) async {
    final List<Map<String, dynamic>> maps = await dbProvider.db!.rawQuery('''
      SELECT $columnSendAt, $columnMessageOtherId
      FROM $tableName
      WHERE $columnOtherUserId = ? AND ($columnMessageKind = ? OR $columnMessageKind = ?)
      ORDER BY $columnSendAt DESC;
    ''', [otherUserId, MessageKind.image.index, MessageKind.video.index]);

    try {
      return List.generate(maps.length, (i) {
        return (
          DateTime.tryParse(maps[i][columnSendAt])!,
          maps[i][columnMessageOtherId]
        );
      });
    } catch (e) {
      Logger("error parsing datetime: $e");
      return [];
    }
  }

  static Future<int?> deleteMessageById(int messageId) async {
    await dbProvider.db!.delete(
      tableName,
      where: '$columnMessageId = ?',
      whereArgs: [messageId],
    );
    int? fromUserId = await getFromUserIdByMessageId(messageId);
    if (fromUserId != null) {
      globalCallBackOnMessageChange(fromUserId);
    }
    return fromUserId;
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
      MessageContent content, DateTime messageSendAt) async {
    try {
      int messageId = await dbProvider.db!.insert(tableName, {
        columnMessageKind: kind.index,
        columnMessageContentJson: jsonEncode(content.toJson()),
        columnOtherUserId: userIdFrom,
        columnSendAt: messageSendAt.toIso8601String()
      });
      globalCallBackOnMessageChange(userIdFrom);
      return messageId;
    } catch (e) {
      Logger("messsage_model/insertMyMessage").shout("$e");
      return null;
    }
  }

  static Future<int?> insertOtherMessage(int userIdFrom, MessageKind kind,
      int messageOtherId, String jsonContent, DateTime messageSendAt) async {
    try {
      int messageId = await dbProvider.db!.insert(tableName, {
        columnMessageOtherId: messageOtherId,
        columnMessageKind: kind.index,
        columnMessageContentJson: jsonContent,
        columnMessageAcknowledgeByServer: 1,
        columnMessageAcknowledgeByUser:
            0, // ack in case of sending corresponds to the opened flag
        columnOtherUserId: userIdFrom,
        columnSendAt: messageSendAt.toIso8601String()
      });
      globalCallBackOnMessageChange(userIdFrom);
      return messageId;
    } catch (e) {
      Logger("messsage_model/insertOtherMessage").shout("$e");
      return null;
    }
  }

  static Future<List<DbMessage>> getAllMessagesForUserWithHigherMessageId(
      int otherUserId, int lastMessageId) async {
    var rows = await dbProvider.db!.query(
      tableName,
      where: "$columnOtherUserId = ? AND $columnMessageId > ?",
      whereArgs: [otherUserId, lastMessageId],
      orderBy: "$columnUpdatedAt DESC",
    );

    List<DbMessage> messages = await convertToDbMessage(rows);

    return messages;
  }

  static Future<List<DbMessage>> getAllMessagesForUser(int otherUserId) async {
    var rows = await dbProvider.db!.query(
      tableName,
      where: "$columnOtherUserId = ?",
      whereArgs: [otherUserId],
      orderBy: "$columnSendAt DESC",
    );

    List<DbMessage> messages = await convertToDbMessage(rows);

    return messages;
  }

  static Future<List<DbMessage>> getAllMessagesForRetransmitting() async {
    var rows = await dbProvider.db!.query(
      tableName,
      where: "$columnMessageAcknowledgeByServer = 0",
    );
    List<DbMessage> messages = await convertToDbMessage(rows);
    return messages;
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

    List<DbMessage> messages = await convertToDbMessage(rows);

    // check if you received a message which the user has not already opened
    List<DbMessage> receivedByOther = messages
        .where((c) => c.messageOtherId != null && c.messageOpenedAt == null)
        .toList();
    if (receivedByOther.isNotEmpty) {
      return receivedByOther[receivedByOther.length - 1];
    }

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

  static Future _updateByMessageId(int messageId, Map<String, dynamic> data,
      {bool notifyFlutterState = true}) async {
    await dbProvider.db!.update(
      tableName,
      data,
      where: "$columnMessageId = ?",
      whereArgs: [messageId],
    );
    if (notifyFlutterState) {
      int? fromUserId = await getFromUserIdByMessageId(messageId);
      if (fromUserId != null) {
        globalCallBackOnMessageChange(fromUserId);
      }
    }
  }

  static Future _updateByOtherMessageId(
      int fromUserId, int messageId, Map<String, dynamic> data) async {
    await dbProvider.db!.update(
      tableName,
      data,
      where: "$columnMessageOtherId = ?",
      whereArgs: [messageId],
    );
    globalCallBackOnMessageChange(fromUserId);
  }

  // this ensures that the message id can be spoofed by another person
  static Future _updateByMessageIdOther(
      int fromUserId, int messageId, Map<String, dynamic> data) async {
    await dbProvider.db!.update(
      tableName,
      data,
      where: "$columnMessageId = ? AND $columnOtherUserId = ?",
      whereArgs: [messageId, fromUserId],
    );
    globalCallBackOnMessageChange(fromUserId);
  }

  static Future userOpenedOtherMessage(
      int otherMessageId, int fromUserId) async {
    Map<String, dynamic> data = {
      columnMessageOpenedAt: DateTime.now().toIso8601String(),
    };
    await _updateByOtherMessageId(fromUserId, otherMessageId, data);
  }

  static Future otherUserOpenedMyMessage(
      int fromUserId, int messageId, DateTime openedAt) async {
    Map<String, dynamic> data = {
      columnMessageOpenedAt: openedAt.toIso8601String(),
    };
    await _updateByMessageIdOther(fromUserId, messageId, data);
  }

  static Future acknowledgeMessageByServer(int messageId) async {
    Map<String, dynamic> data = {
      columnMessageAcknowledgeByServer: 1,
    };
    await _updateByMessageId(messageId, data);
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
  List<CvField> get fields =>
      [messageId, messageKind, messageContentJson, messageOpenedAt, sendAt];

  // TODO: The message meta is needed to maintain the flame. Delete if not.
  // This function should calculate if this message is needed for the flame calculation and delete the message complete and not only
  // the message content.
  static Future deleteTextContent(
      int messageId, TextMessageContent oldMessage) async {
    oldMessage.text = "";
    Map<String, dynamic> data = {
      columnMessageContentJson: jsonEncode(oldMessage.toJson()),
    };
    await _updateByMessageId(messageId, data, notifyFlutterState: false);
  }

  static Future<List<DbMessage>> convertToDbMessage(
      List<dynamic> fromDb) async {
    try {
      List<DbMessage> parsedUsers = [];
      for (int i = 0; i < fromDb.length; i++) {
        dynamic messageOpenedAt = fromDb[i][columnMessageOpenedAt];

        MessageContent content = MessageContent.fromJson(
            jsonDecode(fromDb[i][columnMessageContentJson]));

        var tmp = content;
        if (messageOpenedAt != null) {
          messageOpenedAt = DateTime.tryParse(fromDb[i][columnMessageOpenedAt]);
          if (tmp is TextMessageContent && messageOpenedAt != null) {
            if ((DateTime.now()).difference(messageOpenedAt).inHours >= 24) {
              deleteTextContent(fromDb[i][columnMessageId], tmp);
            }
          }
        }
        int? messageOtherId = fromDb[i][columnMessageOtherId];

        bool isDownloaded = true;
        if (messageOtherId != null) {
          if (content is MediaMessageContent) {
            // when the media was send from the user itself the content is null
            isDownloaded = await isMediaDownloaded(content.downloadToken);
          }
        }
        parsedUsers.add(
          DbMessage(
            sendAt: DateTime.tryParse(fromDb[i][columnSendAt])!,
            messageId: fromDb[i][columnMessageId],
            messageOtherId: messageOtherId,
            otherUserId: fromDb[i][columnOtherUserId],
            messageContent: content,
            isDownloaded: isDownloaded,
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
