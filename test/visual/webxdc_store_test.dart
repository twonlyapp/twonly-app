import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/webxdc.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/webxdc_store.bottom_sheet.dart';

class _StoreApi implements RustLibApi {
  @override
  Future<List<WebxdcStoreApp>> crateBridgeWebxdcCatalog({
    required String groupId,
    required List<String> languages,
  }) async => [];

  @override
  Future<void> crateBridgeWebxdcRefreshCatalog() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => RustLib.initMock(api: _StoreApi()));
  tearDownAll(RustLib.dispose);

  for (final direct in [false, true]) {
    testWidgets(
      'direct-chat hint in an empty ${direct ? 'direct' : 'group'} drawer',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: WebxdcStoreView(
                group: Group(
                  groupId: 'chat',
                  groupName: 'Chat',
                  isDirectChat: direct,
                  isGroupAdmin: false,
                  joinedGroup: true,
                  leftGroup: false,
                  stateVersionId: 0,
                  flameCounter: 0,
                  maxFlameCounter: 0,
                  totalMediaCounter: 0,
                  alsoBestFriend: false,
                  deleteMessagesAfterMilliseconds: 86400000,
                  archived: false,
                  pinned: false,
                  deletedContent: false,
                  createdAtSeconds: databaseSeconds(DateTime(2026)),
                  lastMessageExchangeSeconds: databaseSeconds(DateTime(2026)),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No apps are available yet.'), findsOneWidget);
        expect(
          find.text('Some games can only be played in direct chats.'),
          direct ? findsNothing : findsOneWidget,
        );
      },
    );
  }
}
