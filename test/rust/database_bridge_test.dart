import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart'
    show AnyhowException;
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart' as rust_database;
import 'package:twonly/core/bridge/database/contact_groups.dart'
    as rust_contact_groups;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/diagnostics.dart'
    as rust_diagnostics;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/bridge/database/stickers.dart' as rust_stickers;
import 'package:twonly/core/database/app/contact_groups/table.dart'
    as db_contact_groups;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/diagnostics/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';

import '../helpers/native_database.dart';

void main() {
  final library = File('rust/target/debug/librust_lib_twonly.dylib');
  final available = Platform.isMacOS && library.existsSync();
  const database = testDatabase;

  setUpAll(() async {
    if (!available) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeNativeDatabase();
  });
  setUp(() async {
    if (available) await TestDatabase.create();
  });
  tearDownAll(() {
    if (available) RustLib.dispose();
  });

  group(
    'actual Rust bridge',
    () {
      test(
        'typed codecs preserve blobs, nullable flags and timestamp patches',
        () async {
          final id = int.parse('9007199254740993');
          final bytes = Uint8List.fromList([0, 128, 255]);
          final stamp = DateTime.utc(2026, 1, 2, 3, 4, 5, 987);
          await rust_contacts.upsertContact(
            patch: ContactPatch(
              userId: id,
              username: 'codec',
              avatarSvgCompressed: NullableBytes(value: bytes),
              preferPhotoAvatar: NullableInt(
                value: databaseNullableFlag(false),
              ),
              nickName: const NullableText(value: 'Before'),
              joinedAt: NullableInt(value: databaseNullableSeconds(stamp)),
            ),
            transaction: currentDatabaseSession(),
          );
          var contact = (await rust_contacts.getContact(
            id: id,
            transaction: currentDatabaseSession(),
          ))!;
          expect(contact.userId, id);
          expect(contact.avatarSvgCompressed, bytes);
          expect(contact.preferPhotoAvatar, isFalse);
          expect(
            contact.joinedAt!.millisecondsSinceEpoch,
            stamp.millisecondsSinceEpoch ~/ 1000 * 1000,
          );
          await rust_contacts.updateContact(
            id: id,
            patch: ContactPatch(
              nickName: const NullableText(),
              preferPhotoAvatar: NullableInt(value: databaseNullableFlag(null)),
            ),
            transaction: currentDatabaseSession(),
          );
          contact = (await rust_contacts.getContact(
            id: id,
            transaction: currentDatabaseSession(),
          ))!;
          expect(contact.nickName, isNull);
          expect(contact.preferPhotoAvatar, isNull);
          expect(contact.avatarSvgCompressed, bytes);
        },
      );

      test(
        'developer batches and encrypted-aware snapshot use typed bridge commands',
        () async {
          await TestDatabase.create();
          final session = currentDatabaseSession();
          await rust_database.refreshDatabaseWatches();
          final items = [
            for (var i = 0; i < 13; i++)
              MockGalleryItem(createdAt: 1700000000 + i, month: 'Januar 2024'),
          ];
          await rust_diagnostics.seedMockGallery(
            items: items,
            openedAt: 1700000100,
            transaction: session,
          );
          await rust_diagnostics.seedMockGallery(
            items: items,
            openedAt: 1700000100,
            transaction: session,
          );
          expect(
            (await rust_messages.getMessage(
              id: 'mock_msg_0',
              transaction: currentDatabaseSession(),
            ))!.senderId,
            9000000,
          );
          await database.customStatement(
            "INSERT INTO group_members(group_id,contact_id) VALUES ('mock_group_gallery',9000000)",
          );
          expect(
            await rust_diagnostics.seedMockMessages(
              group: 'mock_group_gallery',
              count: 3,
              now: 1700000200,
              prefix: 'frb-mock',
              transaction: session,
            ),
            3,
          );
          expect(
            (await rust_messages.getMessage(
              id: 'frb-mock_0',
              transaction: currentDatabaseSession(),
            ))!.senderId,
            9000000,
          );
          final directory = Directory.systemTemp.createTempSync(
            'twonly_debug_export_',
          );
          try {
            final path = "${directory.path}/inspect'copy.sqlite";
            await rust_diagnostics.exportDebugDatabase(path: path);
            final bytes = File(path).readAsBytesSync();
            expect(bytes.length, greaterThan(4096));
            expect(
              bytes.take(16),
              isNot(orderedEquals([...ascii.encode('SQLite format 3'), 0])),
            );
            await expectLater(
              rust_diagnostics.exportDebugDatabase(path: path),
              throwsA(anything),
            );
          } finally {
            directory.deleteSync(recursive: true);
          }
        },
      );

      test(
        'typed commands join their caller transaction and nested savepoints',
        () async {
          late int discarded;
          await expectLater(
            withDatabaseTransaction(() async {
              discarded = await rust_contact_groups.createContactGroup(
                transaction: currentDatabaseSession(),
                input: const db_contact_groups.ContactGroupInput(
                  name: 'Rolled back native group',
                  textColor: 0,
                  backgroundColor: 0,
                  showAsShortcut: false,
                  showAsLabel: false,
                  shareStories: false,
                ),
              );
              expect(
                await rust_contact_groups.getContactGroup(
                  id: discarded,
                  transaction: currentDatabaseSession(),
                ),
                isNotNull,
              );
              throw StateError('rollback');
            }),
            throwsStateError,
          );
          expect(
            await rust_contact_groups.getContactGroup(
              id: discarded,
              transaction: currentDatabaseSession(),
            ),
            isNull,
          );

          await withDatabaseTransaction(() async {
            await database.customStatement(
              "INSERT INTO app_metadata(key,value) VALUES ('mixed', 'keep')",
            );
            await expectLater(
              withDatabaseTransaction(() async {
                await rust_stickers.saveSticker(
                  webp: Uint8List.fromList([91]),
                  width: 1,
                  height: 1,
                  transaction: currentDatabaseSession(),
                );
                throw StateError('nested rollback');
              }),
              throwsStateError,
            );
            // The failed command is rolled back to its own savepoint even if
            // its caller catches the error and commits the outer transaction.
            await expectLater(
              rust_stickers.saveSticker(
                webp: Uint8List.fromList([92]),
                width: 0,
                height: 1,
                transaction: currentDatabaseSession(),
              ),
              throwsA(
                isA<AnyhowException>().having(
                  (error) => error.message,
                  'message',
                  'invalid sticker size or dimensions',
                ),
              ),
            );
            await rust_stickers.saveSticker(
              webp: Uint8List.fromList([93]),
              width: 1,
              height: 1,
              transaction: currentDatabaseSession(),
            );
          });
          final rows = await database
              .customSelect(
                "SELECT hex(webp) AS bytes FROM stickers WHERE hex(webp) IN ('5B','5C','5D') ORDER BY bytes",
              )
              .get();
          expect(rows.map((row) => row.read<String>('bytes')), ['5D']);
        },
      );

      test('caller rollback cannot absorb a concurrent native command', () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        final legacy = withDatabaseTransaction(() async {
          await database.customStatement(
            "INSERT INTO app_metadata(key, value) VALUES ('legacy-test', 'discard')",
          );
          entered.complete();
          await release.future;
          throw StateError('intentional rollback');
        });

        // Install the error handler before allowing the transaction to fail.
        final rolledBack = expectLater(legacy, throwsStateError);
        await entered.future;
        final native = rust_contact_groups.createContactGroup(
          transaction: currentDatabaseSession(),
          input: const db_contact_groups.ContactGroupInput(
            name: 'Native survives',
            textColor: 0xff000000,
            backgroundColor: 0,
            showAsShortcut: false,
            showAsLabel: true,
            shareStories: false,
          ),
        );
        release.complete();
        await rolledBack;
        final id = await native;
        expect(
          (await rust_contact_groups.getContactGroup(
            id: id,
            transaction: currentDatabaseSession(),
          ))!.name,
          'Native survives',
        );
        expect(
          await database
              .customSelect(
                "SELECT value FROM app_metadata WHERE key = 'legacy-test'",
              )
              .get(),
          isEmpty,
        );
      });

      test(
        'typed watch observes commits and cancels without another write',
        () async {
          final updates = StreamIterator(
            watchRustDatabase(
              (control) => rust_contact_groups.watchContactGroups(
                filter: db_contact_groups.ContactGroupFilter.all,
                control: control,
              ),
            ),
          );
          try {
            expect(await updates.moveNext(), isTrue);
            final id = await rust_contact_groups.createContactGroup(
              transaction: currentDatabaseSession(),
              input: const db_contact_groups.ContactGroupInput(
                name: 'Watched',
                textColor: 0xff112233,
                backgroundColor: 0,
                showAsShortcut: false,
                showAsLabel: true,
                shareStories: false,
              ),
            );
            expect(await updates.moveNext(), isTrue);
            expect(updates.current.any((group) => group.id == id), isTrue);
          } finally {
            await updates.cancel();
          }
        },
      );

      test(
        '64-bit membership identifiers survive scalar and list codecs',
        () async {
          final id = int.parse('9007199254740993');
          await database.customStatement(
            'INSERT INTO contacts(user_id, username) VALUES (?, ?)',
            [id, 'large-id'],
          );
          await database.customStatement(
            'INSERT INTO contact_groups(id, name, text_color, background_color) VALUES (?, ?, ?, ?)',
            [id, 'Large id', 0xff000000, 0],
          );
          await rust_contact_groups.replaceContactGroupMembers(
            transaction: currentDatabaseSession(),
            id: id,
            userIds: Int64List.fromList([id].toList()),
            groupIds: const <String>[],
          );
          expect(
            (await rust_contact_groups.getContactGroupMembers(
              id: id,
              transaction: currentDatabaseSession(),
            )).single.userId,
            id,
          );
          expect(
            await watchRustDatabase(
              (control) => rust_contact_groups
                  .watchContactGroupIds(userId: id, control: control)
                  .map((ids) => ids.map((id) => id.toInt()).toSet()),
            ).first,
            {id},
          );
        },
      );

      test('nested native savepoints keep the owning Rust transaction', () async {
        await withDatabaseTransaction(() async {
          await database.customStatement(
            "INSERT INTO app_metadata(key, value) VALUES ('outer-test', 'kept')",
          );
          await expectLater(
            withDatabaseTransaction(() async {
              await database.customStatement(
                "UPDATE app_metadata SET value = 'discard' WHERE key = 'outer-test'",
              );
              throw StateError('nested rollback');
            }),
            throwsStateError,
          );
        });
        final row = await database
            .customSelect(
              "SELECT value FROM app_metadata WHERE key = 'outer-test'",
            )
            .getSingle();
        expect(row.read<String>('value'), 'kept');
      });

      test(
        'transaction results and nested scopes survive the bridge',
        () async {
          final result = await withDatabaseTransaction(() async {
            final id = await rust_contact_groups.createContactGroup(
              transaction: currentDatabaseSession(),
              input: const db_contact_groups.ContactGroupInput(
                name: 'Typed transaction result',
                textColor: 0,
                backgroundColor: 0,
                showAsShortcut: false,
                showAsLabel: false,
                shareStories: false,
              ),
            );
            return withDatabaseTransaction(
              () async => (await rust_contact_groups.getContactGroup(
                id: id,
                transaction: currentDatabaseSession(),
              ))!,
            );
          });
          expect(result.name, 'Typed transaction result');
          expect(
            await rust_contact_groups.getContactGroup(
              id: result.id,
              transaction: currentDatabaseSession(),
            ),
            result,
          );
        },
      );

      test(
        'callbacks escaping a closed scope cannot write into the parent or a later transaction',
        () async {
          late Future<int> Function() escapedChild;
          late Future<int> Function() escapedRoot;
          Future<int> create() => rust_contact_groups.createContactGroup(
            transaction: currentDatabaseSession(),
            input: const db_contact_groups.ContactGroupInput(
              name: 'Escaped transaction callback',
              textColor: 0,
              backgroundColor: 0,
              showAsShortcut: false,
              showAsLabel: false,
              shareStories: false,
            ),
          );
          await withDatabaseTransaction(() async {
            escapedRoot = Zone.current.bindCallback(create);
            await withDatabaseTransaction(() async {
              escapedChild = Zone.current.bindCallback(create);
            });
            await expectLater(Future.sync(escapedChild), throwsStateError);
          });
          await expectLater(Future.sync(escapedRoot), throwsStateError);
          await withDatabaseTransaction(() async {
            await expectLater(Future.sync(escapedChild), throwsStateError);
            await expectLater(Future.sync(escapedRoot), throwsStateError);
            // The failed stale calls must not poison a fresh caller's scope.
            final id = await create();
            expect(
              await rust_contact_groups.getContactGroup(
                id: id,
                transaction: currentDatabaseSession(),
              ),
              isNotNull,
            );
          });
        },
      );

      test(
        'concurrent sibling scopes fail without entering each other',
        () async {
          await withDatabaseTransaction(() async {
            final entered = Completer<void>();
            final release = Completer<void>();
            final child = withDatabaseTransaction(() async {
              entered.complete();
              await release.future;
              throw StateError('discard child');
            });
            final rolledBack = expectLater(child, throwsStateError);
            await entered.future;
            var siblingEntered = false;
            try {
              await expectLater(
                withDatabaseTransaction(() async {
                  siblingEntered = true;
                }),
                throwsA(anything),
              );
              expect(siblingEntered, isFalse);
            } finally {
              release.complete();
              await rolledBack;
            }
            final id = await rust_contact_groups.createContactGroup(
              transaction: currentDatabaseSession(),
              input: const db_contact_groups.ContactGroupInput(
                name: 'Parent still usable',
                textColor: 0,
                backgroundColor: 0,
                showAsShortcut: false,
                showAsLabel: false,
                shareStories: false,
              ),
            );
            expect(
              await rust_contact_groups.getContactGroup(
                id: id,
                transaction: currentDatabaseSession(),
              ),
              isNotNull,
            );
          });
        },
      );
    },
    skip: available
        ? false
        : 'Build the macOS host library with cargo build --manifest-path rust/Cargo.toml --lib',
  );
}
