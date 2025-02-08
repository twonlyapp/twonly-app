import 'dart:typed_data';

import 'package:cv/cv.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DbSignalIdentityKeyStore extends CvModelBase {
  static const tableName = "signal_identity_key_store";

  static const columnDeviceId = "device_id";
  final deviceId = CvField<int>(columnDeviceId);

  static const columnName = "name";
  final name = CvField<String>(columnName);

  static const columnIdentityKey = "identity_key";
  final identityKey = CvField<Uint8List>(columnIdentityKey);

  static const columnCreatedAt = "created_at";
  final createdAt = CvField<DateTime>(columnCreatedAt);

  static Future setupDatabaseTable(Database db) async {
    String createTableString = """
      CREATE TABLE IF NOT EXISTS $tableName (
      $columnDeviceId INTEGER NOT NULL,
      $columnName TEXT NOT NULL,
      $columnIdentityKey BLOB NOT NULL,
      $columnCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ($columnDeviceId, $columnName)
    )
    """;
    await db.execute(createTableString);
  }

  @override
  List<CvField> get fields => [deviceId, name, identityKey, createdAt];
}
