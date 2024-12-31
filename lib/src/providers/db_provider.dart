import 'dart:async';
import 'dart:math';
import 'package:connect/src/model/identity_key_store_model.dart';
import 'package:connect/src/model/model_constants.dart';
import 'package:connect/src/model/pre_key_model.dart';
import 'package:connect/src/model/sender_key_store_model.dart';
import 'package:connect/src/model/session_store_model.dart';
import 'package:connect/src/utils.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DbProvider {
  Database? db;

  Future openPath(String path) async {
    // Read the password for the database from the secure storage. If there is no, then create a
    // new cryptographically secure random password with 32 bytes and store them in the secure storage.
    // So if someone dumps the app for example using a tool like Cellebrite including the apps
    // content he is not able to access the databases content.
    // (https://signal.org/blog/cellebrite-and-clickbait/)
    //
    // CHECK: Does this actually improve the security or is this just security through obscurity and
    // can be removed as it does increase complexity?
    // Current thoughts: As the database password is at some point in the memory the attacker could
    // just dump it. Questions here: What capabilities must the attacker have to do that?

    final storage = getSecureStorage();
    var password = await storage.read(key: "sqflite_database_password");
    if (password == null) {
      var secureRandom = Random.secure();
      password = "";
      for (var i = 0; i < 32; i++) {
        password = "$password${String.fromCharCode(secureRandom.nextInt(256))}";
      }
      await storage.write(key: "sqflite_database_password", value: password);
    }

    db = await openDatabase(path, password: password, version: kVersion1,
        onCreate: (db, version) async {
      await _createDb(db);
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < kVersion1) {
        await _createDb(db);
      }
    });
  }

  Future<Database?> get ready async {
    if (db == null) {
      await open();
    }
    return db;
  }

  Future _createDb(Database db) async {
    await db.execute('DROP TABLE If EXISTS ${DbSignalSessionStore.tableName}');
    await db.execute(DbSignalSessionStore.getCreateTableString());

    await db.execute('DROP TABLE If EXISTS ${DbSignalPreKeyStore.tableName}');
    await db.execute(DbSignalPreKeyStore.getCreateTableString());

    await db
        .execute('DROP TABLE If EXISTS ${DbSignalSenderKeyStore.tableName}');
    await db.execute(DbSignalSenderKeyStore.getCreateTableString());

    await db
        .execute('DROP TABLE If EXISTS ${DbSignalIdentityKeyStore.tableName}');
    await db.execute(DbSignalIdentityKeyStore.getCreateTableString());
  }

  Future open() async {
    await openPath(await fixPath(dbName));
  }

  Future<String> fixPath(String path) async => path;

  Future close() async {
    await db!.close();
  }

  // Future deleteDb() async {
  //   await deleteDatabase(await fixPath(dbName));
  // }
}
