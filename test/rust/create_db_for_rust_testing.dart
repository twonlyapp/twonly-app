import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  if (!Platform.isMacOS) return;
  late TwonlyDB database;
  late File dbFile;

  setUp(() {
    dbFile = File('rust/core/tests/testing.db');
    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }
    database = TwonlyDB(NativeDatabase(dbFile));
  });

  tearDown(() async {
    await database.close();
  });

  test('Database successfully writes to the physical file system', () async {
    final users = [
      'alice',
      'bob',
      'charlie',
      'david',
      'frank',
    ];

    for (var i = 0; i < users.length; i++) {
      await database.contactsDao.insertContact(
        ContactsCompanion(userId: Value(i), username: Value(users[i])),
      );
    }

    expect(
      dbFile.existsSync(),
      isTrue,
      reason: 'The SQLite file was not created on disk.',
    );

    expect(
      dbFile.lengthSync(),
      greaterThan(0),
      reason: 'The SQLite file is completely empty.',
    );

    if (kDebugMode) {
      print('Test passed! Database written to: ${dbFile.absolute.path}');
    }
  });
}
