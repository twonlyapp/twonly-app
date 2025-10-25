import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/database/twonly_database_old.dart'
    show TwonlyDatabaseOld;
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
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
    final oldMessages = await oldDatabase.messages.select().get();

    for (final oldContact in oldContacts) {
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion(
          userId: Value(oldContact.userId),
          username: Value(oldContact.username),
          displayName: Value(oldContact.displayName),
          nickName: Value(oldContact.nickName),
          avatarSvg: Value(oldContact.avatarSvg),
          senderProfileCounter: const Value(0),
          accepted: Value(oldContact.accepted),
          requested: Value(oldContact.requested),
          blocked: Value(oldContact.blocked),
          verified: Value(oldContact.verified),
          deleted: Value(oldContact.deleted),
          createdAt: Value(oldContact.createdAt),
        ),
      );
      setState(() {
        _contactsMigrated += 1;
      });
      if (!oldContact.deleted) {
        final group = await twonlyDB.groupsDao.createNewDirectChat(
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
          ),
        );
        if (group == null) continue;
        for (final oldMessage in oldMessages) {
          if (oldMessage.mediaUploadId == null &&
              oldMessage.mediaDownloadId == null) {
            /// only interested in media files...
            continue;
          }
          if (oldMessage.contactId != oldContact.userId) continue;
          if (!oldMessage.mediaStored) continue;

          var storedMediaPath =
              join((await getApplicationSupportDirectory()).path, 'media');
          if (oldMessage.mediaDownloadId != null) {
            storedMediaPath =
                '${join(storedMediaPath, 'received')}/${oldMessage.mediaDownloadId}';
          } else {
            storedMediaPath =
                '${join(storedMediaPath, 'send')}/${oldMessage.mediaDownloadId}';
          }

          var type = MediaType.image;
          if (File('$storedMediaPath.mp4').existsSync()) {
            type = MediaType.video;
            storedMediaPath = '$storedMediaPath.mp4';
          } else if (File('$storedMediaPath.png').existsSync()) {
            type = MediaType.image;
            storedMediaPath = '$storedMediaPath.png';
          } else if (File('$storedMediaPath.webp').existsSync()) {
            type = MediaType.image;
            storedMediaPath = '$storedMediaPath.webp';
          } else {
            continue;
          }

          final uniqueId = Value(
            getUUIDforDirectChat(
              oldMessage.messageOtherId ?? oldMessage.messageId,
              oldMessage.contactId ^ gUser.userId,
            ),
          );

          final mediaFile = await twonlyDB.mediaFilesDao.insertMedia(
            MediaFilesCompanion(
              mediaId: uniqueId,
              stored: const Value(true),
              type: Value(type),
              createdAt: Value(oldMessage.sendAt),
            ),
          );
          if (mediaFile == null) continue;

          final message = await twonlyDB.messagesDao.insertMessage(
            MessagesCompanion(
              messageId: uniqueId,
              groupId: Value(group.groupId),
              mediaId: uniqueId,
              type: const Value(MessageType.media),
            ),
          );
          if (message == null) continue;

          final mediaService = await MediaFileService.fromMedia(mediaFile);
          File(storedMediaPath).copySync(mediaService.storedPath.path);
          setState(() {
            _storedMediaFiles += 1;
          });
        }
      }
    }

    final memoriesPath = Directory(
      join((await getApplicationSupportDirectory()).path, 'media', 'memories'),
    );
    final files = memoriesPath.listSync();
    for (final file in files) {
      if (file.path.contains('thumbnail')) continue;
      final type =
          file.path.contains('mp4') ? MediaType.video : MediaType.image;
      final stat = FileStat.statSync(file.path);
      final mediaFile = await twonlyDB.mediaFilesDao.insertMedia(
        MediaFilesCompanion(
          type: Value(type),
          createdAt: Value(stat.modified),
        ),
      );
      final mediaService = await MediaFileService.fromMedia(mediaFile!);
      File(file.path).copySync(mediaService.storedPath.path);
      setState(() {
        _storedMediaFiles += 1;
      });
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
            SignalSessionStore.fromJson(oldSignalSessionStore.toJson()));
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
                  oldSignalIdentityKeyStore.toJson()),
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
                    '${_contactsMigrated} Kontakte',
                    '${_storedMediaFiles} gespeicherte Mediendateien',
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
                        '${_contactsMigrated} Kontakte',
                        '${_storedMediaFiles} gespeicherte Mediendateien',
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
                        'twonly. Jetzt besser als je zuvor.',
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
