// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = TwonlyDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    final oldContactsData = <v1.ContactsData>[];
    final expectedNewContactsData = <v2.ContactsData>[];

    final oldMessagesData = <v1.MessagesData>[];
    final expectedNewMessagesData = <v2.MessagesData>[];

    final oldSignalIdentityKeyStoresData = <v1.SignalIdentityKeyStoresData>[];
    final expectedNewSignalIdentityKeyStoresData =
        <v2.SignalIdentityKeyStoresData>[];

    final oldSignalPreKeyStoresData = <v1.SignalPreKeyStoresData>[];
    final expectedNewSignalPreKeyStoresData = <v2.SignalPreKeyStoresData>[];

    final oldSignalSenderKeyStoresData = <v1.SignalSenderKeyStoresData>[];
    final expectedNewSignalSenderKeyStoresData =
        <v2.SignalSenderKeyStoresData>[];

    final oldSignalSessionStoresData = <v1.SignalSessionStoresData>[];
    final expectedNewSignalSessionStoresData = <v2.SignalSessionStoresData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: TwonlyDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.contacts, oldContactsData);
        batch.insertAll(oldDb.messages, oldMessagesData);
        batch.insertAll(
            oldDb.signalIdentityKeyStores, oldSignalIdentityKeyStoresData);
        batch.insertAll(oldDb.signalPreKeyStores, oldSignalPreKeyStoresData);
        batch.insertAll(
            oldDb.signalSenderKeyStores, oldSignalSenderKeyStoresData);
        batch.insertAll(oldDb.signalSessionStores, oldSignalSessionStoresData);
      },
      validateItems: (newDb) async {
        expect(
            expectedNewContactsData, await newDb.select(newDb.contacts).get());
        expect(
            expectedNewMessagesData, await newDb.select(newDb.messages).get());
        expect(expectedNewSignalIdentityKeyStoresData,
            await newDb.select(newDb.signalIdentityKeyStores).get());
        expect(expectedNewSignalPreKeyStoresData,
            await newDb.select(newDb.signalPreKeyStores).get());
        expect(expectedNewSignalSenderKeyStoresData,
            await newDb.select(newDb.signalSenderKeyStores).get());
        expect(expectedNewSignalSessionStoresData,
            await newDb.select(newDb.signalSessionStores).get());
      },
    );
  });
}
