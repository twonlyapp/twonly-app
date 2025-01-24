import 'package:cv/cv.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/main.dart';

class Contact {
  Contact({required this.userId, required this.displayName});
  final Int64 userId;
  final String displayName;
}

class DbContacts extends CvModelBase {
  static const tableName = "contacts";

  static const columnUserId = "contact_user_id";
  final userId = CvField<int>(columnUserId);

  static const columnDisplayName = "display_name";
  final displayName = CvField<String>(columnDisplayName);

  static const columnCreatedAt = "created_at";
  final createdAt = CvField<DateTime>(columnCreatedAt);

  static String getCreateTableString() {
    return """
      CREATE TABLE $tableName (
      $columnUserId INTEGER NOT NULL PRIMARY KEY,
      $columnDisplayName TEXT,
      $columnCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
    )
    """;
  }

  static Future<List<Contact>> getUsers() async {
    var users = await dbProvider.db!.query(tableName,
        columns: [columnUserId, columnDisplayName, columnCreatedAt]);
    if (users.isEmpty) return [];

    List<Contact> parsedUsers = [];
    for (int i = 0; i < users.length; i++) {
      parsedUsers.add(Contact(
          userId: Int64(users.cast()[i][columnUserId]),
          displayName: users.cast()[i][columnDisplayName]));
    }
    return parsedUsers;
  }

  @override
  List<CvField> get fields => [userId, createdAt];
}
