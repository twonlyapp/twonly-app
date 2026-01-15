import 'dart:collection' show HashSet;
import 'dart:convert';
import 'dart:io';
import 'package:clock/clock.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/database/twonly_database_old.dart'
    show TwonlyDatabaseOld;
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

class DatabaseMigrationView extends StatefulWidget {
  const DatabaseMigrationView({super.key});

  @override
  State<DatabaseMigrationView> createState() => _DatabaseMigrationViewState();
}

class _DatabaseMigrationViewState extends State<DatabaseMigrationView> {
  bool _isMigrating = false;
  bool _isMigratingFinished = false;
  int _contactsMigrated = 0;
  int _storedMediaFiles = 0;

  Future<void> startMigration() async {
    setState(() {
      _isMigrating = true;
    });

    final oldDatabase = TwonlyDatabaseOld();
    final oldContacts = await oldDatabase.contacts.select().get();

    for (final oldContact in oldContacts) {
      try {
        if (oldContact.deleted) continue;
        Uint8List? avatarSvg;
        if (oldContact.avatarSvg != null) {
          avatarSvg = Uint8List.fromList(
            gzip.encode(utf8.encode(oldContact.avatarSvg!)),
          );
        }
        await twonlyDB.contactsDao.insertContact(
          ContactsCompanion(
            userId: Value(oldContact.userId),
            username: Value(oldContact.username),
            displayName: Value(oldContact.displayName),
            nickName: Value(oldContact.nickName),
            avatarSvgCompressed: Value(avatarSvg),
            senderProfileCounter: const Value(0),
            accepted: Value(oldContact.accepted),
            requested: Value(oldContact.requested),
            blocked: Value(oldContact.blocked),
            verified: Value(oldContact.verified),
            createdAt: Value(oldContact.createdAt),
          ),
        );
        setState(() {
          _contactsMigrated += 1;
        });
        await twonlyDB.groupsDao.createNewDirectChat(
          oldContact.userId,
          GroupsCompanion(
            pinned: Value(oldContact.pinned),
            archived: Value(oldContact.archived),
            groupName: Value(getContactDisplayNameOld(oldContact)),
            totalMediaCounter: Value(oldContact.totalMediaCounter),
            alsoBestFriend: Value(oldContact.alsoBestFriend),
            createdAt: Value(oldContact.createdAt),
            lastFlameCounterChange: Value(oldContact.lastFlameCounterChange),
            lastFlameSync: Value(oldContact.lastFlameSync),
            lastMessageExchange: Value(oldContact.lastMessageExchange),
            lastMessageReceived: Value(oldContact.lastMessageReceived),
            lastMessageSend: Value(oldContact.lastMessageSend),
            flameCounter: Value(oldContact.flameCounter),
            maxFlameCounter: Value(oldContact.flameCounter),
            maxFlameCounterFrom: Value(clock.now()),
          ),
        );
      } catch (e) {
        Log.error(e);
      }
    }

    final folders = ['memories', 'send', 'received'];

    final alreadyCopied = HashSet();

    for (final folder in folders) {
      final memoriesPath = Directory(
        join(
          (await getApplicationSupportDirectory()).path,
          'media',
          folder,
        ),
      );
      if (memoriesPath.existsSync()) {
        final files = memoriesPath.listSync();
        for (final file in files) {
          try {
            if (file.path.contains('thumbnail')) continue;
            late MediaType type;
            if (file.path.contains('mp4')) {
              type = MediaType.video;
            } else if (file.path.contains('png')) {
              type = MediaType.image;
            } else {
              continue;
            }

            final bytes = File(file.path).readAsBytesSync();
            final digest = (await Sha256().hash(bytes)).bytes;
            if (alreadyCopied.contains(digest)) {
              continue;
            }
            alreadyCopied.add(digest);

            final stat = FileStat.statSync(file.path);
            final mediaFile = await twonlyDB.mediaFilesDao.insertMedia(
              MediaFilesCompanion(
                type: Value(type),
                createdAt: Value(stat.modified),
                stored: const Value(true),
              ),
            );
            final mediaService = MediaFileService(mediaFile!);
            File(file.path).copySync(mediaService.storedPath.path);
            setState(() {
              _storedMediaFiles += 1;
            });
          } catch (e) {
            Log.error(e);
          }
        }
      }
    }

    final oldContactPreKeys =
        await oldDatabase.signalContactPreKeys.select().get();
    for (final oldContactPreKey in oldContactPreKeys) {
      try {
        await twonlyDB
            .into(twonlyDB.signalContactPreKeys)
            .insert(SignalContactPreKey.fromJson(oldContactPreKey.toJson()));
      } catch (e) {
        Log.error(e);
      }
    }

    final oldSignalSessionStores =
        await oldDatabase.signalSessionStores.select().get();
    for (final oldSignalSessionStore in oldSignalSessionStores) {
      try {
        await twonlyDB.into(twonlyDB.signalSessionStores).insert(
              SignalSessionStore.fromJson(oldSignalSessionStore.toJson()),
            );
      } catch (e) {
        Log.error(e);
      }
    }

    final oldSignalSenderKeyStores =
        await oldDatabase.signalSenderKeyStores.select().get();
    for (final oldSignalSenderKeyStore in oldSignalSenderKeyStores) {
      try {
        await twonlyDB.into(twonlyDB.signalSenderKeyStores).insert(
              SignalSenderKeyStore.fromJson(oldSignalSenderKeyStore.toJson()),
            );
      } catch (e) {
        Log.error(e);
      }
    }

    final oldSignalPreyKeyStores =
        await oldDatabase.signalPreKeyStores.select().get();
    for (final oldSignalPreyKeyStore in oldSignalPreyKeyStores) {
      try {
        await twonlyDB
            .into(twonlyDB.signalPreKeyStores)
            .insert(SignalPreKeyStore.fromJson(oldSignalPreyKeyStore.toJson()));
      } catch (e) {
        Log.error(e);
      }
    }

    final oldSignalIdentityKeyStores =
        await oldDatabase.signalIdentityKeyStores.select().get();
    for (final oldSignalIdentityKeyStore in oldSignalIdentityKeyStores) {
      try {
        await twonlyDB.into(twonlyDB.signalIdentityKeyStores).insert(
              SignalIdentityKeyStore.fromJson(
                oldSignalIdentityKeyStore.toJson(),
              ),
            );
      } catch (e) {
        Log.error(e);
      }
    }

    final oldSignalContactSignedPreKeys =
        await oldDatabase.signalContactSignedPreKeys.select().get();
    for (final oldSignalContactSignedPreKey in oldSignalContactSignedPreKeys) {
      try {
        await twonlyDB.into(twonlyDB.signalContactSignedPreKeys).insert(
              SignalContactSignedPreKey.fromJson(
                oldSignalContactSignedPreKey.toJson(),
              ),
            );
      } catch (e) {
        Log.error(e);
      }
    }

    await updateUserdata((u) {
      u.appVersion = 62;
      return u;
    });

    setState(() {
      _isMigratingFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _isMigratingFinished
            ? ListView(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Deine Daten wurden migriert.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ...[
                    '$_contactsMigrated Kontakte',
                    '$_storedMediaFiles gespeicherte Mediendateien',
                  ].map(
                    (e) => Text(
                      e,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Sollte du feststellen, dass es bei der Migration Fehler gab, zum Beispiel, dass Bilder fehlen, dann melde dies bitte über das Feedback-Formular. Du hast dafür eine Woche Zeit, danach werden deine alte Daten unwiederruflich gelöscht.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 30),
                  FilledButton(
                    onPressed: () {
                      Restart.restartApp(
                        notificationTitle: 'Deine Daten wurden migriert.',
                        notificationBody: 'Click here to open the app again',
                      );
                    },
                    child: const Text(
                      'App neu starten',
                    ),
                  ),
                ],
              )
            : _isMigrating
                ? ListView(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Deine Daten werden migriert.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'twonly während der Migration NICHT schließen!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Colors.red),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Aktueller Status',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                      ...[
                        '$_contactsMigrated Kontakte',
                        '$_storedMediaFiles gespeicherte Mediendateien',
                      ].map(
                        (e) => Text(
                          e,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'twonly. Besser als je zuvor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Das sind die neuen Features.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      ...[
                        'Gruppen',
                        'Nachrichten bearbeiten & löschen',
                      ].map(
                        (e) => Text(
                          e,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                      const Text(
                        'Technische Neuerungen',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17),
                      ),
                      ...[
                        'Client-to-Client (C2C) Protokoll umgestellt auf ProtoBuf.',
                        'Verwendung von UUIDs in der Datenbank',
                        'Von Grund auf neues Datenbank-Schema',
                        'Verbesserung der Zuverlässigkeit von C2C Nachrichten',
                        'Verbesserung von Videos',
                      ].map(
                        (e) => Text(
                          e,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 50),
                      const Text(
                        'Was bedeutet das für dich?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                      const Text(
                        'Aufgrund der technischen Umstellung müssen wir deine alte Datenbank sowie deine gespeicherten Bilder migieren. Durch die Migration gehen einige Informationen verloren.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Was nach der Migration erhalten bleibt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                      ...[
                        'Gespeicherte Bilder',
                        'Kontakte',
                        'Flammen',
                      ].map(
                        (e) => Text(
                          e,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Was durch die Migration verloren geht.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.red),
                      ),
                      ...[
                        'Text-Nachrichten und Reaktionen',
                        'Alles, was gesendet wurde, aber noch nicht empfangen wurde, wie Nachrichten und Bilder.',
                      ].map(
                        (e) => Text(
                          e,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 30),
                      FilledButton(
                        onPressed: startMigration,
                        child: const Text(
                          'Jetzt starten',
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
