import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/views/contact/contact_components/avatar_preference.comp.dart';

import '../../helpers/native_database.dart';

class _AvatarApi extends NativeTestApi {
  late String photo;
  late String illustrated;
  int failures = 0;
  int renders = 0;
  bool returnNull = false;
  Completer<void>? renderGate;

  @override
  Future<String?> crateBridgeApiRustApiEnsureAvatarPng({
    required int contactId,
  }) async {
    renders++;
    if (failures > 0) {
      failures--;
      throw Exception('attempted to acquire a connection on a closed pool');
    }
    await renderGate?.future;
    if (returnNull) return null;
    final contact = await rust_contacts.getContact(
      id: contactId,
      transaction: currentDatabaseSession(),
    );
    return contact?.preferPhotoAvatar == false ? illustrated : photo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _AvatarApi();
  late Directory directory;
  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    api
      ..failures = 0
      ..renders = 0
      ..returnNull = false
      ..renderGate = null;
    await locator.reset();
    await TestDatabase.create();
    await testDatabase.insert(
      ContactPatch(
        userId: 7,
        username: 'peer',
        avatarSvgCompressed: NullableBytes(value: Uint8List.fromList([1])),
      ),
    );
    await testDatabase.customStatement(
      'INSERT INTO received_custom_avatars(contact_id, webp, sha256, width, height) VALUES (7, ?, ?, 1, 1)',
      [
        Uint8List.fromList([1]),
        Uint8List(32),
      ],
    );
    directory = await Directory.systemTemp.createTemp('twonly-avatar-test-');
    api
      ..photo = (await File(
        'assets/images/default_avatar.png',
      ).copy('${directory.path}/photo.png')).path
      ..illustrated = (await File(
        'assets/images/default_avatar.png',
      ).copy('${directory.path}/illustrated.png')).path;
  });
  tearDown(() async {
    await locator.reset();
    await directory.delete(recursive: true);
  });

  Widget app() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: StreamBuilder<Contact?>(
        stream: watchRustDatabase(
          (control) => rust_contacts.watchContacts(
            input: db_contacts.ContactQuery(
              filter: db_contacts.ContactFilter.ids,
              ids: Int64List.fromList([7].toList()),
            ),
            control: control,
          ),
        ).map((rows) => rows.isEmpty ? null : rows.single),
        builder: (context, snapshot) => snapshot.data == null
            ? const SizedBox()
            : Column(
                children: [
                  AvatarIcon(contacts: [snapshot.data!]),
                  AvatarPreferenceTile(contact: snapshot.data!),
                ],
              ),
      ),
    ),
  );

  testWidgets('an avatar storage failure can recover after resume', (
    tester,
  ) async {
    // Use a distinct counter so another test's positive cache is irrelevant.
    final contact = await runNative(tester, () async {
      await testDatabase.customStatement(
        'UPDATE contacts SET sender_profile_counter = 91 WHERE user_id = 7',
      );
      return (await rust_contacts.getContact(
        id: 7,
        transaction: currentDatabaseSession(),
      ))!;
    });
    api.failures = 1;
    await tester.pumpWidget(MaterialApp(home: AvatarIcon(contacts: [contact])));
    await tester.pump();
    expect(api.renders, 1);
    expect(find.byType(Image), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await pumpNative(
      tester,
      until: () => find.byType(Image).evaluate().isNotEmpty,
    );
    // A native table invalidation may also refresh the avatar after resume.
    expect(api.renders, greaterThanOrEqualTo(2));
    expect(
      (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
      api.photo,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  Future<Contact> contactWithCounter(WidgetTester tester, int counter) =>
      runNative(tester, () async {
        await testDatabase.customStatement(
          'UPDATE contacts SET sender_profile_counter = ? WHERE user_id = 7',
          [counter],
        );
        return (await rust_contacts.getContact(
          id: 7,
          transaction: currentDatabaseSession(),
        ))!;
      });

  testWidgets('a visible avatar retries a temporary database failure', (
    tester,
  ) async {
    final contact = await contactWithCounter(tester, 92);
    api.failures = 1;
    await tester.pumpWidget(MaterialApp(home: AvatarIcon(contacts: [contact])));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await pumpNative(
      tester,
      until: () => find.byType(Image).evaluate().isNotEmpty,
    );
    // Resume and storage invalidations may both request a refresh.
    expect(api.renders, greaterThanOrEqualTo(2));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a missing avatar is resolved when its data arrives at the same counter',
    (tester) async {
      final contact = await contactWithCounter(tester, 93);
      api.returnNull = true;
      await tester.pumpWidget(
        MaterialApp(home: AvatarIcon(contacts: [contact])),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      final changed = await runNative(tester, () async {
        await rust_contacts.updateContact(
          id: 7,
          patch: ContactPatch(
            avatarSvgCompressed: NullableBytes(value: Uint8List.fromList([2])),
          ),
          transaction: currentDatabaseSession(),
        );
        return (await rust_contacts.getContact(
          id: 7,
          transaction: currentDatabaseSession(),
        ))!;
      });
      api.returnNull = false;
      await tester.pumpWidget(
        MaterialApp(home: AvatarIcon(contacts: [changed])),
      );
      await pumpNative(
        tester,
        until: () => find.byType(Image).evaluate().isNotEmpty,
      );
      expect(api.renders, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'scrolling back shows the cached avatar while its database refresh waits',
    (tester) async {
      final contact = await contactWithCounter(tester, 94);
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: ListView.builder(
            controller: scroll,
            itemCount: 40,
            itemExtent: 100,
            itemBuilder: (_, index) => index == 0
                ? AvatarIcon(contacts: [contact])
                : Text('Row $index'),
          ),
        ),
      );
      await pumpNative(
        tester,
        until: () => find.byType(Image).evaluate().isNotEmpty,
      );
      scroll.jumpTo(2000);
      await tester.pump();
      expect(find.byType(AvatarIcon), findsNothing);
      final gate = Completer<void>();
      api.renderGate = gate;
      scroll.jumpTo(0);
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(gate.isCompleted, isFalse);
      expect(
        (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
        api.photo,
      );
      gate.complete();
      await pumpNative(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      scroll.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a received photo refreshes shared-contact avatars without a profile change',
    (tester) async {
      final contact = await contactWithCounter(tester, 95);
      api.returnNull = true;
      await tester.pumpWidget(
        MaterialApp(home: AvatarIcon(contacts: [contact])),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      api.returnNull = false;
      await runNative(
        tester,
        () => testDatabase.customStatement(
          'UPDATE received_custom_avatars SET applied_counter = applied_counter + 1 WHERE contact_id = 7',
        ),
      );
      await pumpNative(
        tester,
        until: () => find.byType(Image).evaluate().isNotEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a reused avatar switches its contact subscription', (
    tester,
  ) async {
    await runNative(
      tester,
      () => testDatabase.insert(
        const ContactPatch(
          userId: 8,
          username: 'other',
          preferPhotoAvatar: NullableInt(value: 0),
        ),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: AvatarIcon(contactId: 7)));
    await pumpNative(
      tester,
      until: () => find.byType(Image).evaluate().isNotEmpty,
    );
    await tester.pumpWidget(const MaterialApp(home: AvatarIcon(contactId: 8)));
    await pumpNative(
      tester,
      until: () => tester
          .widgetList<Image>(find.byType(Image))
          .any(
            (image) => (image.image as FileImage).file.path == api.illustrated,
          ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'choice is persisted and an already displayed avatar switches both ways',
    (tester) async {
      // Keep the app-wide path cache from reusing another fixture's temp files.
      await contactWithCounter(tester, 96);
      await tester.pumpWidget(app());
      await pumpNative(
        tester,
        until: () => find.byType(Image).evaluate().isNotEmpty,
      );
      expect(
        (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
        api.photo,
      );
      await pumpNative(
        tester,
        until: () => find.text('Avatar').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Avatar'));
      await tester.pumpAndSettle();
      final lang = AppLocalizations.of(
        tester.element(find.byType(AvatarPreferenceTile)),
      )!;
      await tester.tap(find.text(lang.customAvatarSvgTab));
      await pumpNative(tester);
      expect(
        (await runNative(
          tester,
          () => rust_contacts.getContact(
            id: 7,
            transaction: currentDatabaseSession(),
          ),
        ))!.preferPhotoAvatar,
        isFalse,
      );
      await pumpNative(
        tester,
        until: () {
          final images = tester.widgetList<Image>(find.byType(Image));
          return images.any(
            (image) =>
                image.image is FileImage &&
                (image.image as FileImage).file.path == api.illustrated,
          );
        },
      );
      expect(
        (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
        api.illustrated,
      );
      await pumpNative(
        tester,
        until: () => find.text('Avatar').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Avatar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(lang.customAvatarPhotoTab));
      await pumpNative(tester);
      expect(
        (await runNative(
          tester,
          () => rust_contacts.getContact(
            id: 7,
            transaction: currentDatabaseSession(),
          ),
        ))!.preferPhotoAvatar,
        isTrue,
      );
      await pumpNative(
        tester,
        until: () {
          final images = tester.widgetList<Image>(find.byType(Image));
          return images.any(
            (image) =>
                image.image is FileImage &&
                (image.image as FileImage).file.path == api.photo,
          );
        },
      );
      expect(
        (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
        api.photo,
      );
    },
  );

  testWidgets('choice is hidden when a photo is not shared', (tester) async {
    await runNative(
      tester,
      () => testDatabase.customStatement('DELETE FROM received_custom_avatars'),
    );
    await tester.pumpWidget(app());
    await pumpNative(tester);
    expect(find.text('Avatar'), findsNothing);
  });

  testWidgets('choice is hidden when an illustrated avatar is not shared', (
    tester,
  ) async {
    await runNative(
      tester,
      () => rust_contacts.updateContact(
        id: 7,
        patch: const ContactPatch(avatarSvgCompressed: NullableBytes()),
        transaction: currentDatabaseSession(),
      ),
    );
    await tester.pumpWidget(app());
    await pumpNative(tester);
    expect(find.text('Avatar'), findsNothing);
  });
}
