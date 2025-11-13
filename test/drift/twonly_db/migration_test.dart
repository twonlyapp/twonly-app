// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:twonly/src/database/twonly.db.dart';
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
            final db = TwonlyDB(schema.newConnection());
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
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldContactsData = <v1.ContactsData>[];
    final expectedNewContactsData = <v2.ContactsData>[];

    final oldGroupsData = <v1.GroupsData>[];
    final expectedNewGroupsData = <v2.GroupsData>[];

    final oldMediaFilesData = <v1.MediaFilesData>[];
    final expectedNewMediaFilesData = <v2.MediaFilesData>[];

    final oldMessagesData = <v1.MessagesData>[];
    final expectedNewMessagesData = <v2.MessagesData>[];

    final oldMessageHistoriesData = <v1.MessageHistoriesData>[];
    final expectedNewMessageHistoriesData = <v2.MessageHistoriesData>[];

    final oldReactionsData = <v1.ReactionsData>[];
    final expectedNewReactionsData = <v2.ReactionsData>[];

    final oldGroupMembersData = <v1.GroupMembersData>[];
    final expectedNewGroupMembersData = <v2.GroupMembersData>[];

    final oldReceiptsData = <v1.ReceiptsData>[];
    final expectedNewReceiptsData = <v2.ReceiptsData>[];

    final oldReceivedReceiptsData = <v1.ReceivedReceiptsData>[];
    final expectedNewReceivedReceiptsData = <v2.ReceivedReceiptsData>[];

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

    final oldSignalContactPreKeysData = <v1.SignalContactPreKeysData>[];
    final expectedNewSignalContactPreKeysData = <v2.SignalContactPreKeysData>[];

    final oldSignalContactSignedPreKeysData =
        <v1.SignalContactSignedPreKeysData>[];
    final expectedNewSignalContactSignedPreKeysData =
        <v2.SignalContactSignedPreKeysData>[];

    final oldMessageActionsData = <v1.MessageActionsData>[];
    final expectedNewMessageActionsData = <v2.MessageActionsData>[];

    final oldGroupHistoriesData = <v1.GroupHistoriesData>[];
    final expectedNewGroupHistoriesData = <v2.GroupHistoriesData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: TwonlyDB.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.contacts, oldContactsData);
        batch.insertAll(oldDb.groups, oldGroupsData);
        batch.insertAll(oldDb.mediaFiles, oldMediaFilesData);
        batch.insertAll(oldDb.messages, oldMessagesData);
        batch.insertAll(oldDb.messageHistories, oldMessageHistoriesData);
        batch.insertAll(oldDb.reactions, oldReactionsData);
        batch.insertAll(oldDb.groupMembers, oldGroupMembersData);
        batch.insertAll(oldDb.receipts, oldReceiptsData);
        batch.insertAll(oldDb.receivedReceipts, oldReceivedReceiptsData);
        batch.insertAll(
            oldDb.signalIdentityKeyStores, oldSignalIdentityKeyStoresData);
        batch.insertAll(oldDb.signalPreKeyStores, oldSignalPreKeyStoresData);
        batch.insertAll(
            oldDb.signalSenderKeyStores, oldSignalSenderKeyStoresData);
        batch.insertAll(oldDb.signalSessionStores, oldSignalSessionStoresData);
        batch.insertAll(
            oldDb.signalContactPreKeys, oldSignalContactPreKeysData);
        batch.insertAll(oldDb.signalContactSignedPreKeys,
            oldSignalContactSignedPreKeysData);
        batch.insertAll(oldDb.messageActions, oldMessageActionsData);
        batch.insertAll(oldDb.groupHistories, oldGroupHistoriesData);
      },
      validateItems: (newDb) async {
        expect(
            expectedNewContactsData, await newDb.select(newDb.contacts).get());
        expect(expectedNewGroupsData, await newDb.select(newDb.groups).get());
        expect(expectedNewMediaFilesData,
            await newDb.select(newDb.mediaFiles).get());
        expect(
            expectedNewMessagesData, await newDb.select(newDb.messages).get());
        expect(expectedNewMessageHistoriesData,
            await newDb.select(newDb.messageHistories).get());
        expect(expectedNewReactionsData,
            await newDb.select(newDb.reactions).get());
        expect(expectedNewGroupMembersData,
            await newDb.select(newDb.groupMembers).get());
        expect(
            expectedNewReceiptsData, await newDb.select(newDb.receipts).get());
        expect(expectedNewReceivedReceiptsData,
            await newDb.select(newDb.receivedReceipts).get());
        expect(expectedNewSignalIdentityKeyStoresData,
            await newDb.select(newDb.signalIdentityKeyStores).get());
        expect(expectedNewSignalPreKeyStoresData,
            await newDb.select(newDb.signalPreKeyStores).get());
        expect(expectedNewSignalSenderKeyStoresData,
            await newDb.select(newDb.signalSenderKeyStores).get());
        expect(expectedNewSignalSessionStoresData,
            await newDb.select(newDb.signalSessionStores).get());
        expect(expectedNewSignalContactPreKeysData,
            await newDb.select(newDb.signalContactPreKeys).get());
        expect(expectedNewSignalContactSignedPreKeysData,
            await newDb.select(newDb.signalContactSignedPreKeys).get());
        expect(expectedNewMessageActionsData,
            await newDb.select(newDb.messageActions).get());
        expect(expectedNewGroupHistoriesData,
            await newDb.select(newDb.groupHistories).get());
      },
    );
  });
}
