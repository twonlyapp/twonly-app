import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as contacts;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/elements/svg_icon.element.dart';
import 'package:twonly/src/visual/themes/light.dart';

import '../../helpers/native_database.dart';

void main() {
  setUpAll(initializeNativeDatabase);
  tearDownAll(RustLib.dispose);
  setUp(TestDatabase.create);

  testWidgets('counts distinct trusted attesters and loses trust on revocation', (
    tester,
  ) async {
    await runNative(tester, () async {
      await testDatabase.customStatement(
        "INSERT INTO contacts(user_id, username, verified) VALUES (1,'a',0),(2,'target',1),(3,'b',0)",
      );
      await testDatabase.customStatement(
        'INSERT INTO key_verifications(contact_id,type,verified_by) VALUES '
        "(1,'manual',NULL),(3,'qrScanned',NULL),"
        "(2,'contactSharedByVerified',1),(2,'contactSharedByVerified',1),"
        "(2,'contactSharedByVerified',3)",
      );
      await testDatabase.customStatement(
        "INSERT INTO user_discovery_announced_users(announced_user_id,announced_public_key,public_id,session_identity_key) VALUES (2,X'01',2,X'01')",
      );
      await testDatabase.customStatement(
        'INSERT INTO user_discovery_user_relations(announced_user_id,from_contact_id,public_key_verified_timestamp) VALUES (2,1,123)',
      );
    });
    final contact = await runNative(
      tester,
      () => contacts.getContact(
        id: 2,
        transaction: currentDatabaseSession(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: VerificationBadgeComp(contact: contact, clickable: false),
        ),
      ),
    );
    String asset() => tester.widget<SvgIcon>(find.byType(SvgIcon)).assetPath;
    await pumpNative(
      tester,
      until: () => asset() == SvgIcons.verifiedNumeric(2),
    );
    expect(asset(), SvgIcons.verifiedNumeric(2));

    await runNative(
      tester,
      () => testDatabase.customStatement(
        "DELETE FROM key_verifications WHERE type IN ('manual','qrScanned')",
      ),
    );
    await pumpNative(tester, until: () => asset() == SvgIcons.verifiedRed);
    expect(asset(), SvgIcons.verifiedRed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a mismatched session removes the inherited badge only', (
    tester,
  ) async {
    await runNative(tester, () async {
      await testDatabase.customStatement(
        "INSERT INTO contacts(user_id, username, accepted) VALUES (7,'carol',1),(8,'bob',1)",
      );
      await testDatabase.customStatement(
        "INSERT INTO key_verifications(contact_id,type) VALUES (8,'manual')",
      );
      await testDatabase.customStatement(
        "INSERT INTO user_discovery_announced_users(announced_user_id,announced_public_key,public_id,session_identity_key) VALUES (7,X'01',70,X'01')",
      );
      await testDatabase.customStatement(
        'INSERT INTO user_discovery_user_relations(announced_user_id,from_contact_id,public_key_verified_timestamp) VALUES (7,8,123)',
      );
    });
    final contact = await runNative(
      tester,
      () => contacts.getContact(id: 7, transaction: currentDatabaseSession()),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: VerificationBadgeComp(
            contact: contact,
            showOnlyIfVerified: true,
            clickable: false,
          ),
        ),
      ),
    );
    await pumpNative(
      tester,
      until: () => find.byType(SvgIcon).evaluate().isNotEmpty,
    );
    await runNative(
      tester,
      () => testDatabase.customStatement(
        "UPDATE user_discovery_announced_users SET session_identity_key = X'02' WHERE announced_user_id = 7",
      ),
    );
    await pumpNative(
      tester,
      until: () => find.byType(SvgIcon).evaluate().isEmpty,
    );
    expect(find.byType(SvgIcon), findsNothing);
    final saved = await runNative(
      tester,
      () => contacts.getContact(id: 7, transaction: currentDatabaseSession()),
    );
    expect(saved!.acceptedFlag, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
