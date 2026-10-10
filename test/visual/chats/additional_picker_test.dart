import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/bottom_sheets/share_additional.bottom_sheet.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_input.dart';
import 'package:twonly/src/visual/views/shared/select_contacts.view.dart';

import '../../mocks/user_config.dart';

class _PickerApi implements RustLibApi {
  @override
  Future<FlameState> crateBridgeGroupsFlameState({
    required String groupId,
  }) async =>
      const FlameState(counter: 0, isExpiring: false, isBestFriend: false);

  @override
  Future<List<String>> crateBridgeApiRustApiClearConversationNotifications({
    required String conversationId,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Group group;

  setUpAll(() {
    AppEnvironment.initTesting();
    RustLib.initMock(api: _PickerApi());
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('simform_audio_waveforms'),
      (_) async => null,
    );
  });
  tearDownAll(RustLib.dispose);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    locator
      ..registerSingleton<TwonlyDB>(
        TwonlyDB.forTesting(
          DatabaseConnection(
            NativeDatabase.memory(),
            closeStreamsSynchronously: true,
          ),
        ),
      )
      ..registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 180,
    )..typingIndicators = false;
    await twonlyDB.groupsDao.createNewGroup(
      GroupsCompanion.insert(
        groupId: 'chat',
        groupName: 'Chat',
        isDirectChat: const Value(true),
      ),
    );
    group = (await twonlyDB.groupsDao.getGroup('chat'))!;
  });

  tearDown(() async {
    await twonlyDB.close();
    await locator.reset();
  });

  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> openChat(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsChangeProvider>(
        create: (_) => SettingsChangeProvider()..loadSettings(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChatMessagesView('chat', initialGroup: group),
        ),
      ),
    );
    await flush(tester);
  }

  Finder icon(FaIconData icon) => find.byIcon(icon.data);

  Future<void> closeChat(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await flush(tester);
  }

  testWidgets('add toggles an inline panel below the composer', (tester) async {
    await openChat(tester);
    final originalInputTop = tester.getTopLeft(find.byType(TextField)).dy;
    await tester.tap(icon(FontAwesomeIcons.plus));
    await tester.pump();

    final panel = find.byType(ShareAdditionalView);
    expect(panel, findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.descendant(of: find.byType(MessageInput), matching: panel),
      findsOneWidget,
    );
    expect(icon(FontAwesomeIcons.plus), findsOneWidget);
    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(tester.getSize(panel).height, 180);
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      originalInputTop - 180,
    );
    expect(
      tester.getTopLeft(panel).dy,
      greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).resizeToAvoidBottomInset,
      isFalse,
    );

    // The layout stays stable while the system keyboard is disappearing.
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pump();
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      originalInputTop - 180,
    );
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();

    await tester.tap(icon(FontAwesomeIcons.plus));
    await tester.pump();
    expect(panel, findsNothing);
    expect(tester.getTopLeft(find.byType(TextField)).dy, originalInputTop);
    expect(tester.takeException(), isNull);
    await closeChat(tester);
  });

  testWidgets('additional panel swaps with emojis and returns to typing', (
    tester,
  ) async {
    await openChat(tester);
    await tester.tap(icon(FontAwesomeIcons.plus));
    await tester.pump();
    await tester.tap(icon(FontAwesomeIcons.faceSmile));
    await tester.pump();
    expect(find.byType(ShareAdditionalView), findsNothing);
    expect(find.byType(EmojiPicker), findsOneWidget);

    await tester.tap(icon(FontAwesomeIcons.plus));
    await tester.pump();
    expect(find.byType(ShareAdditionalView), findsOneWidget);
    expect(find.byType(EmojiPicker), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.byType(ShareAdditionalView), findsNothing);
    expect(
      tester.widget<MessageInput>(find.byType(MessageInput)).panel,
      ChatInputPanel.none,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await closeChat(tester);
  });

  testWidgets('cancelling contact sharing returns to the same chat', (
    tester,
  ) async {
    await openChat(tester);
    await tester.tap(icon(FontAwesomeIcons.plus));
    await tester.pump();
    await tester.tap(icon(FontAwesomeIcons.circleUser));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await flush(tester);
    expect(find.byType(SelectContactsView), findsOneWidget);

    Navigator.of(tester.element(find.byType(SelectContactsView))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(ChatMessagesView), findsOneWidget);
    expect(find.byType(ShareAdditionalView), findsNothing);
    expect(icon(FontAwesomeIcons.plus), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeChat(tester);
  });
}
