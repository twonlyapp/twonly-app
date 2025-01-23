import 'package:cv/cv.dart';

class DbMessages extends CvModelBase {
  static const tableName = "messages";

  static const columnMessageId = "messageId";
  final messageId = CvField<int>(columnMessageId);

  static const columnBody = "body";
  final messageBody = CvField<int>(columnBody);

  static const columnCreatedAt = "created_at";
  final createdAt = CvField<DateTime>(columnCreatedAt);

  static String getCreateTableString() {
    return """
      CREATE TABLE $tableName (
      $columnMessageId INTEGER NOT NULL,
      $columnCreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY ($columnMessageId)
    )
    """;
  }

  @override
  List<CvField> get fields => [messageId, createdAt];
}
