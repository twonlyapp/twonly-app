import 'dart:async';
import 'dart:math';
import 'package:twonly/src/model/identity_key_store_model.dart';
import 'package:twonly/src/model/pre_key_model.dart';
import 'package:twonly/src/model/sender_key_store_model.dart';
import 'package:twonly/src/model/session_store_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:twonly/src/utils/misc.dart';

class DbProvider {
  Database? db;

  static const String dbName = 'twonly.db';

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

    db = await openDatabase(path, password: password);
    if (db != null) {
      await setupDatabaseTable(db!);
    }
  }

  Future<Database?> get ready async {
    if (db == null) {
      await open();
    }
    return db;
  }

  Future setupDatabaseTable(Database db) async {
    await DbSignalSessionStore.setupDatabaseTable(db);
    await DbSignalPreKeyStore.setupDatabaseTable(db);
    await DbSignalSenderKeyStore.setupDatabaseTable(db);
    await DbSignalIdentityKeyStore.setupDatabaseTable(db);
  }

  Future open() async {
    await openPath(await fixPath(dbName));
  }

  Future remove() async {
    await deleteDatabase(await fixPath(dbName));
    // await _createDb(db!);
  }

  Future<String> fixPath(String path) async => path;

  Future close() async {
    await db!.close();
  }
}
