import 'dart:typed_data';
import 'package:cv/cv.dart';

class DbSignalSenderKeyStore extends CvModelBase {
  static const tableName = "signal_sender_key_store";

  static const columnSenderKeyName = "sender_key_name";
  final senderKeyName = CvField<String>(columnSenderKeyName);

  static const columnSenderKey = "sender_key";
  final senderKey = CvField<Uint8List>(columnSenderKey);

  static const columnCreatedAt = "created_at";
  final createdAt = CvField<DateTime>(columnCreatedAt);

  static String getCreateTableString() {
    return """
      CREATE TABLE $tableName (
      $columnSenderKeyName TEXT NOT NULL,
      $columnSenderKey BLOB NOT NULL,
      $columnCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ($columnSenderKeyName)
    )
    """;
  }

  @override
  List<CvField> get fields => [senderKeyName, senderKey, createdAt];
}
