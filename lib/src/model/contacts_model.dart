import 'package:cv/cv.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/utils/misc.dart';

class Contact {
  Contact(
      {required this.userId,
      required this.displayName,
      required this.accepted,
      required this.blocked,
      required this.verified,
      required this.totalMediaCounter,
      required this.requested});
  final Int64 userId;
  final String displayName;
  final bool accepted;
  final bool requested;
  final bool blocked;
  final bool verified;
  final int totalMediaCounter;
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

  static const columnVerified = "verified";
  final verified = CvField<int>(columnVerified);

  static const columnTotalMediaCounter = "total_media_counter";
  final totalMediaCounter = CvField<int>(columnTotalMediaCounter);

  static const columnCreatedAt = "created_at";
  final createdAt = CvField<DateTime>(columnCreatedAt);

  static const nextFlameCounterInSeconds = kDebugMode ? 60 : 60 * 60 * 24;

  static Future setupDatabaseTable(Database db) async {
    String createTableString = """
      CREATE TABLE IF NOT EXISTS $tableName (
      $columnUserId INTEGER NOT NULL PRIMARY KEY,
      $columnDisplayName TEXT,
      $columnAccepted INT NOT NULL DEFAULT 0,
      $columnRequested INT NOT NULL DEFAULT 0,
      $columnBlocked INT NOT NULL DEFAULT 0,
      $columnVerified INTEGER NOT NULL DEFAULT 0,
      $columnTotalMediaCounter INT NOT NULL DEFAULT 0,
      $columnCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """;
    await db.execute(createTableString);

    if (!await columnExists(db, tableName, columnVerified)) {
      String alterTableString = """
      ALTER TABLE $tableName 
      ADD COLUMN $columnVerified INTEGER NOT NULL DEFAULT 0
    """;
      await db.execute(alterTableString);
    }
  }

  @override
  List<CvField> get fields =>
      [userId, displayName, accepted, requested, blocked, createdAt];

  static Future<List<Contact>> getActiveUsers() async {
    return (await _getAllUsers())
        .where((u) => u.accepted && !u.blocked)
        .toList();
  }

  static Future<List<Contact>> getBlockedUsers() async {
    return (await _getAllUsers()).where((u) => u.blocked).toList();
  }

  static Future<List<Contact>> getUsers() async {
    return (await _getAllUsers()).where((u) => !u.blocked).toList();
  }

  static Future<List<Contact>> getAllUsers() async {
    return await _getAllUsers();
  }

  static Future checkAndUpdateFlames(int userId, {DateTime? timestamp}) async {
    timestamp ??= DateTime.now();

    List<Map<String, dynamic>> result = await dbProvider.db!.query(
      tableName,
      columns: [columnTotalMediaCounter],
      where: '$columnUserId = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      int totalMediaCounter = result.first.cast()[columnTotalMediaCounter];
      _updateFlameCounter(userId, totalMediaCounter + 1);
      globalCallBackOnContactChange();
    }
  }

  static List<Contact> _parseContacts(List<dynamic> users) {
    List<Contact> parsedUsers = [];
    for (int i = 0; i < users.length; i++) {
      try {
        int userId = users.cast()[i][columnUserId];
        parsedUsers.add(
          Contact(
            userId: Int64(userId),
            totalMediaCounter: users.cast()[i][columnTotalMediaCounter],
            displayName: users.cast()[i][columnDisplayName],
            accepted: users[i][columnAccepted] == 1,
            blocked: users[i][columnBlocked] == 1,
            verified: users[i][columnVerified] == 1,
            requested: users[i][columnRequested] == 1,
          ),
        );
      } catch (e) {
        Logger("contacts_model/parse_single_user").shout("$e");
        return [];
      }
    }
    return parsedUsers;
  }

  static Future<Contact?> getUserById(int userId) async {
    try {
      var user = await dbProvider.db!.query(tableName,
          columns: [
            columnUserId,
            columnDisplayName,
            columnAccepted,
            columnRequested,
            columnBlocked,
            columnVerified,
            columnTotalMediaCounter,
            columnCreatedAt
          ],
          where: "$columnUserId = ?",
          whereArgs: [userId]);
      if (user.isEmpty) return null;
      return _parseContacts(user)[0];
    } catch (e) {
      Logger("contacts_model/getUserById").shout("$e");
      return null;
    }
  }

  static Future<List<Contact>> _getAllUsers() async {
    try {
      var users = await dbProvider.db!.query(tableName, columns: [
        columnUserId,
        columnDisplayName,
        columnAccepted,
        columnRequested,
        columnBlocked,
        columnVerified,
        columnTotalMediaCounter,
        columnCreatedAt
      ]);
      if (users.isEmpty) return [];
      return _parseContacts(users);
    } catch (e) {
      Logger("contacts_model/getUsers").shout("$e");
      return [];
    }
  }

  static Future _update(int userId, Map<String, dynamic> updates,
      {bool notifyFlutter = true}) async {
    await dbProvider.db!.update(
      tableName,
      updates,
      where: "$columnUserId = ?",
      whereArgs: [userId],
    );
    if (notifyFlutter) {
      globalCallBackOnContactChange();
    }
  }

  static Future changeDisplayName(int userId, String newDisplayName) async {
    if (newDisplayName == "") return;
    Map<String, dynamic> updates = {
      columnDisplayName: newDisplayName,
    };
    await _update(userId, updates);
  }

  static Future _updateFlameCounter(int userId, int totalMediaCounter) async {
    Map<String, dynamic> updates = {columnTotalMediaCounter: totalMediaCounter};
    await _update(userId, updates, notifyFlutter: false);
  }

  static Future blockUser(int userId, {bool unblock = false}) async {
    Map<String, dynamic> updates = {
      columnBlocked: unblock ? 0 : 1,
    };
    await _update(userId, updates);
  }

  static Future acceptUser(int userId) async {
    Map<String, dynamic> updates = {
      columnAccepted: 1,
      columnRequested: 0,
    };
    await _update(userId, updates);
  }

  static Future updateVerificationStatus(int userId, bool status) async {
    Map<String, dynamic> updates = {
      columnVerified: status ? 1 : 0,
    };
    await _update(userId, updates);
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
