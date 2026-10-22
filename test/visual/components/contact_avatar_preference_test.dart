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

  @override
  Future<String?> crateBridgeApiRustApiEnsureAvatarPng({
    required int contactId,
  }) async {
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

  testWidgets(
    'choice is persisted and an already displayed avatar switches both ways',
    (tester) async {
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
