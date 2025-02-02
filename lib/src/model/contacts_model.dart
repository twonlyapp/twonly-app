import 'package:cv/cv.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/app.dart';

class Contact {
  Contact(
      {required this.userId,
      required this.displayName,
      required this.accepted,
      required this.flameCounter,
      required this.totalMediaCounter,
      required this.lastUpdateOfFlameCounter,
      required this.requested});
  final Int64 userId;
  final String displayName;
  final bool accepted;
  final bool requested;
  final int flameCounter;
  final int totalMediaCounter;
  final DateTime lastUpdateOfFlameCounter;
}

class DbContacts extends CvModelBase {
  static const tableName = "contacts";

  static const columnUserId = "contact_user_id";
  final userId = CvField<int>(columnUserId);

  static const columnDisplayName = "display_name";
  final displayName = CvField<String>(columnDisplayName);

  static const columnAccepted = "accepted";
  final accepted = CvField<int>(columnAccepted);

  static const columnRequested = "requested";
  final requested = CvField<int>(columnRequested);

  static const columnBlocked = "blocked";
  final blocked = CvField<int>(columnBlocked);

  static const columnFlameCounter = "flame_counter";
  final flameCounter = CvField<int>(columnFlameCounter);

  static const columnTotalMediaCounter = "total_media_counter";
  final totalMediaCounter = CvField<int>(columnTotalMediaCounter);

  static const columnLastUpdateOfFlameCounter = "last_update_flame_counter";
  final lastUpdateOfFlameCounter =
      CvField<DateTime>(columnLastUpdateOfFlameCounter);

  static const columnCreatedAt = "created_at";
  final createdAt = CvField<DateTime>(columnCreatedAt);

  static const nextFlameCounterInSeconds = kDebugMode ? 60 : 60 * 60 * 24;

  static String getCreateTableString() {
    return """
      CREATE TABLE IF NOT EXISTS $tableName (
      $columnUserId INTEGER NOT NULL PRIMARY KEY,
      $columnDisplayName TEXT,
      $columnAccepted INT NOT NULL DEFAULT 0,
      $columnRequested INT NOT NULL DEFAULT 0,
      $columnBlocked INT NOT NULL DEFAULT 0,
      $columnTotalMediaCounter INT NOT NULL DEFAULT 0,
      $columnFlameCounter INT NOT NULL DEFAULT 0,
      $columnLastUpdateOfFlameCounter DATETIME DEFAULT CURRENT_TIMESTAMP,
      $columnCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """;
  }

  @override
  List<CvField> get fields =>
      [userId, displayName, accepted, requested, blocked, createdAt];

  static Future<List<Contact>> getActiveUsers() async {
    return (await getUsers()).where((u) => u.accepted).toList();
  }

  static Future checkAndUpdateFlames(int userId, {DateTime? timestamp}) async {
    timestamp ??= DateTime.now();

    List<Map<String, dynamic>> result = await dbProvider.db!.query(
      tableName,
      columns: [
        columnLastUpdateOfFlameCounter,
        columnFlameCounter,
        columnTotalMediaCounter
      ],
      where: '$columnUserId = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      String lastUpdateString = result.first[columnLastUpdateOfFlameCounter];
      DateTime lastUpdate = DateTime.tryParse(lastUpdateString)!;

      if (timestamp.isAfter(lastUpdate)) {
        int currentCount = result.first.cast()[columnFlameCounter];
        int totalMediaCounter = result.first.cast()[columnTotalMediaCounter];
        if (lastUpdate.isAfter(DateTime.now()
            .subtract(Duration(seconds: nextFlameCounterInSeconds)))) {
          _updateFlameCounter(userId, currentCount,
              totalMediaCounter: totalMediaCounter + 1,
              timestamp: timestamp); // just update the time
        } else {
          _updateFlameCounter(userId, (currentCount + 1),
              totalMediaCounter: totalMediaCounter + 1, timestamp: timestamp);
        }
      }
    }
    globalCallBackOnContactChange();
  }

  static Future _updateFlameCounter(int userId, int newCount,
      {DateTime? timestamp, int? totalMediaCounter}) async {
    timestamp ??= DateTime.now();
    Map<String, dynamic> valuesToUpdate = {
      columnFlameCounter: newCount,
      columnLastUpdateOfFlameCounter: timestamp.toIso8601String()
    };
    if (totalMediaCounter != null) {
      valuesToUpdate[columnTotalMediaCounter] = totalMediaCounter;
    }
    await dbProvider.db!.update(
      tableName,
      valuesToUpdate,
      where: "$columnUserId = ?",
      whereArgs: [userId],
    );
  }

  static Future<List<Contact>> getUsers() async {
    try {
      var users = await dbProvider.db!.query(tableName,
          columns: [
            columnUserId,
            columnDisplayName,
            columnAccepted,
            columnRequested,
            columnFlameCounter,
            columnTotalMediaCounter,
            columnLastUpdateOfFlameCounter,
            columnCreatedAt
          ],
          where: "$columnBlocked = 0");
      if (users.isEmpty) return [];

      List<Contact> parsedUsers = [];
      for (int i = 0; i < users.length; i++) {
        DateTime lastUpdate =
            DateTime.tryParse(users.cast()[i][columnLastUpdateOfFlameCounter])!;

        int userId = users.cast()[i][columnUserId];

        int flameCounter = users.cast()[i][columnFlameCounter];

        // if (lastUpdate.isBefore(DateTime.now()
        //     .subtract(Duration(seconds: nextFlameCounterInSeconds * 2)))) {
        //   _updateFlameCounter(userId, 0);
        //   flameCounter = 0;
        // }

        parsedUsers.add(
          Contact(
            userId: Int64(userId),
            totalMediaCounter: users.cast()[i][columnTotalMediaCounter],
            displayName: users.cast()[i][columnDisplayName],
            accepted: users[i][columnAccepted] == 1,
            flameCounter: flameCounter,
            lastUpdateOfFlameCounter: lastUpdate,
            requested: users[i][columnRequested] == 1,
          ),
        );
      }
      return parsedUsers;
    } catch (e) {
      Logger("contacts_model/getUsers").shout("$e");
      return [];
    }
  }

  static Future blockUser(int userId) async {
    Map<String, dynamic> valuesToUpdate = {
      columnBlocked: 1,
    };
    await dbProvider.db!.update(
      tableName,
      valuesToUpdate,
      where: "$columnUserId = ?",
      whereArgs: [userId],
    );
    globalCallBackOnContactChange();
  }

  static Future acceptUser(int userId) async {
    Map<String, dynamic> valuesToUpdate = {
      columnAccepted: 1,
      columnRequested: 0,
    };
    await dbProvider.db!.update(
      tableName,
      valuesToUpdate,
      where: "$columnUserId = ?",
      whereArgs: [userId],
    );
    globalCallBackOnContactChange();
  }

  static Future deleteUser(int userId) async {
    await dbProvider.db!.delete(
      tableName,
      where: "$columnUserId = ?",
      whereArgs: [userId],
    );
    globalCallBackOnContactChange();
  }

  static Future<bool> insertNewContact(
      String username, int userId, bool requested) async {
    try {
      int a = requested ? 1 : 0;
      await dbProvider.db!.insert(DbContacts.tableName, {
        DbContacts.columnDisplayName: username,
        DbContacts.columnUserId: userId,
        DbContacts.columnRequested: a
      });
      globalCallBackOnContactChange();
      return true;
    } catch (e) {
      Logger("contacts_model/getUsers").shout("$e");
      return false;
    }
  }
}
