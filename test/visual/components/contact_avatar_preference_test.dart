import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/views/contact/contact_components/avatar_preference.comp.dart';

class _AvatarApi implements RustLibApi {
  late String photo;
  late String illustrated;

  @override
  Future<String?> crateBridgeApiRustApiEnsureAvatarPng({
    required int contactId,
  }) async {
    final contact = await twonlyDB.contactsDao.getContactById(contactId);
    return contact?.preferPhotoAvatar == false ? illustrated : photo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _AvatarApi();
  late Directory directory;
  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);
  setUp(() async {
    await locator.reset();
    locator.registerSingleton<TwonlyDB>(
      TwonlyDB.forTesting(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      ),
    );
    await twonlyDB.customStatement(
      'CREATE TABLE received_custom_avatars(contact_id INTEGER PRIMARY KEY, webp BLOB)',
    );
    await twonlyDB
        .into(twonlyDB.contacts)
        .insert(
          ContactsCompanion.insert(
            userId: const Value(7),
            username: 'peer',
            avatarSvgCompressed: Value(Uint8List.fromList([1])),
          ),
        );
    await twonlyDB.customStatement(
      'INSERT INTO received_custom_avatars VALUES (7, ?)',
      [
        Uint8List.fromList([1]),
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
    await twonlyDB.close();
    await locator.reset();
    await directory.delete(recursive: true);
  });

  Widget app() => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: StreamBuilder<Contact?>(
        stream: twonlyDB.contactsDao.watchContact(7),
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
      await tester.pumpAndSettle();
      expect(
        (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
        api.photo,
      );
      await tester.tap(find.text('Avatar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Illustrated avatar'));
      await tester.pumpAndSettle();
      expect(
        (await twonlyDB.contactsDao.getContactById(7))!.preferPhotoAvatar,
        isFalse,
      );
      expect(
        (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
        api.illustrated,
      );
      await tester.tap(find.text('Avatar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo avatar'));
      await tester.pumpAndSettle();
      expect(
        (await twonlyDB.contactsDao.getContactById(7))!.preferPhotoAvatar,
        isTrue,
      );
      expect(
        (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
        api.photo,
      );
    },
  );

  testWidgets('choice is hidden when a photo is not shared', (tester) async {
    await twonlyDB.customStatement('DELETE FROM received_custom_avatars');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Avatar'), findsNothing);
  });

  testWidgets('choice is hidden when an illustrated avatar is not shared', (
    tester,
  ) async {
    await twonlyDB.contactsDao.updateContact(
      7,
      const ContactsCompanion(avatarSvgCompressed: Value(null)),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Avatar'), findsNothing);
  });
}
