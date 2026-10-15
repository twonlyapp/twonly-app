import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_context_menu.dart';

void main() {
  for (final removeRow in [false, true]) {
    testWidgets(
      removeRow
          ? 'dismissing a stale message menu skips its action'
          : 'a message menu opens the editor after dismissing the popup',
      (tester) async {
        final showRow = ValueNotifier(true);
        addTearDown(showRow.dispose);
        final navigator = GlobalKey<NavigatorState>();
        final now = DateTime(2026);
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: showRow,
                builder: (context, visible, child) => visible
                    ? MessageContextMenu(
                        message: Message(
                          groupId: 'chat',
                          messageId: 'message',
                          type: 'text',
                          content: 'Edit this message',
                          mediaStored: false,
                          mediaReopened: false,
                          isDeletedFromSender: false,
                          isWidgetMedia: false,
                          isStory: false,
                          createdAt: now,
                        ),
                        group: Group(
                          groupId: 'chat',
                          groupName: 'Chat',
                          isGroupAdmin: true,
                          isDirectChat: true,
                          pinned: false,
                          archived: false,
                          joinedGroup: true,
                          leftGroup: false,
                          deletedContent: false,
                          stateVersionId: 0,
                          totalMediaCounter: 0,
                          alsoBestFriend: false,
                          deleteMessagesAfterMilliseconds: 0,
                          createdAt: now,
                          flameCounter: 0,
                          maxFlameCounter: 0,
                          lastMessageExchange: now,
                        ),
                        onResponseTriggered: () {},
                        galleryItems: const [],
                        mediaFileService: null,
                        child: const Text('Message row'),
                      )
                    : const Text('Row removed'),
              ),
            ),
          ),
        );

        await tester.longPress(find.text('Message row'));
        await tester.pumpAndSettle();
        expect(find.text('Edit'), findsOneWidget);

        if (removeRow) {
          showRow.value = false;
          await tester.pumpAndSettle();
          expect(find.byType(MessageContextMenu), findsNothing);
        }

        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.byWidgetPredicate((widget) => widget is PopupMenuEntry),
          findsNothing,
        );
        if (removeRow) {
          expect(find.byType(TextField), findsNothing);
          expect(find.text('Row removed'), findsOneWidget);
          expect(navigator.currentState!.canPop(), isFalse);
        } else {
          expect(find.byType(TextField), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'Edit this message',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
