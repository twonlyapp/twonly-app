import 'dart:typed_data';
import 'package:cv/cv.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DbSignalPreKeyStore extends CvModelBase {
  static const tableName = "signal_pre_key_store";

  static const columnPreKeyId = "pre_key_id";
  final preKeyId = CvField<int>(columnPreKeyId);

  static const columnPreKey = "pre_key";
  final preKey = CvField<Uint8List>(columnPreKey);

  static const columnCreatedAt = "created_at";
  final createdAt = CvField<DateTime>(columnCreatedAt);

  static Future setupDatabaseTable(Database db) async {
    String createTableString = """
      CREATE TABLE IF NOT EXISTS $tableName (
      $columnPreKeyId INTEGER NOT NULL,
      $columnPreKey BLOB NOT NULL,
      $columnCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ($columnPreKeyId)
    )
    """;
    await db.execute(createTableString);
  }

  @override
  List<CvField> get fields => [preKeyId, preKey, createdAt];
}
