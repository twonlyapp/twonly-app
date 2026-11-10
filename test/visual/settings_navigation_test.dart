import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/core/user_config.dart' as config;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/pro_badge.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/settings/appearance.view.dart';
import 'package:twonly/src/visual/views/settings/backup/backup_settings.view.dart';
import 'package:twonly/src/visual/views/settings/backup/memories_backup_detail.view.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/status.passwordless_recovery.comp.dart';
import 'package:twonly/src/visual/views/settings/chat/chat_settings.view.dart';
import 'package:twonly/src/visual/views/settings/data_and_storage/storage_contents.view.dart';
import 'package:twonly/src/visual/views/settings/memories_settings.view.dart';
import 'package:twonly/src/visual/views/settings/notification.view.dart';
import 'package:twonly/src/visual/views/settings/privacy.view.dart';
import 'package:twonly/src/visual/views/settings/settings_main.view.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

class _SettingsApi extends NativeTestApi {
  Future<FrbMemoriesUsage> Function()? loadUsage;

  @override
  Future<FrbMemoriesUsage> crateBridgeApiRustApiGetMemoriesUsage() async =>
      loadUsage == null
      ? const FrbMemoriesUsage(currentBytes: 0, count: 0, maxBytes: 1000000)
      : await loadUsage!();
}

class _SettingsPurchases extends ChangeNotifier
    with DiagnosticableTreeMixin
    implements PurchasesProvider {
  @override
  SubscriptionPlan plan = SubscriptionPlan.Free;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _memoriesBackupDetail = '/settings/memories/backup';
const _storageContents = '/settings/memories/backup/contents';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var notificationPermission = 1;
  final api = _SettingsApi();
  late Directory directory;

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    directory = await Directory.systemTemp.createTemp('twonly-settings-');
    AppEnvironment.initTesting(customSupportDir: directory.path);
    api.loadUsage = null;
    locator.registerSingleton<UserService>(UserService());
    await UserService.save(
      testUserConfig(
        userId: 1,
        username: 'settings',
        displayName: 'Testprofil mit einem längeren Namen',
        subscriptionPlan: 'Free',
        currentSetupPage: null,
        appVersion: 1,
      ),
    );
    notificationPermission = 1;
    messenger.setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'checkPermissionStatus') return notificationPermission;
      if (call.method == 'openAppSettings') return true;
      return null;
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(permissions, null);
    await locator.reset();
    await directory.delete(recursive: true);
    AppEnvironment.initTesting();
  });

  Future<GoRouter> pumpSettings(
    WidgetTester tester, {
    String location = Routes.settings,
    double textScale = 1,
    String locale = 'de',
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final purchases = _SettingsPurchases();
    addTearDown(purchases.dispose);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: Routes.settings,
          builder: (_, _) => const SettingsMainView(),
        ),
        GoRoute(
          path: Routes.settingsChats,
          builder: (_, _) => const ChatSettingsView(),
        ),
        GoRoute(
          path: Routes.settingsBackup,
          builder: (_, _) => ChangeNotifierProvider<PurchasesProvider>.value(
            value: purchases,
            child: const BackupView(),
          ),
        ),
        GoRoute(
          path: Routes.settingsMemories,
          builder: (_, _) => ChangeNotifierProvider<PurchasesProvider>.value(
            value: purchases,
            child: const MemoriesSettingsView(),
          ),
        ),
        GoRoute(
          path: _memoriesBackupDetail,
          builder: (_, _) => const MemoriesBackupDetailView(),
        ),
        GoRoute(
          path: _storageContents,
          builder: (_, _) => const StorageContentsView(),
        ),
        GoRoute(
          path: Routes.settingsPrivacy,
          builder: (_, _) => const PrivacyView(),
        ),
        GoRoute(
          path: Routes.settingsAppearance,
          builder: (_, _) => const AppearanceView(),
        ),
        GoRoute(
          path: Routes.settingsNotification,
          builder: (_, _) => const NotificationView(),
        ),
      ],
    );
    addTearDown(router.dispose);
    final provider = SettingsChangeProvider()..loadSettings();
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp.router(
          routerConfig: router,
          theme: lightTheme,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    );
    await pumpNative(tester);
    return router;
  }

  testWidgets('moved camera preferences preserve and save their values', (
    tester,
  ) async {
    await pumpSettings(tester, location: Routes.settingsChats);
    expect(find.text('Mit geöffneter Kamera starten'), findsOneWidget);
    final camera = find.ancestor(
      of: find.text('Mit geöffneter Kamera starten'),
      matching: find.byType(SwitchListTile),
    );
    expect(tester.widget<SwitchListTile>(camera).value, isTrue);
    await tester.ensureVisible(camera);
    await tester.tap(camera);
    await pumpNative(
      tester,
      until: () => !userService.currentUser.startWithCameraOpen,
    );
    final saved = await runNative(tester, UserConfigApi.load);
    expect(saved!.startWithCameraOpen, isFalse);
  });

  testWidgets('chat settings are grouped into chats, flames and camera', (
    tester,
  ) async {
    await pumpSettings(tester, location: Routes.settingsChats);
    double top(String text) => tester.getTopLeft(find.text(text)).dy;

    final chats = top('Chats');
    final camera = top('Kamera');
    final flames = top('Flammen');
    expect(chats, lessThan(camera));
    expect(camera, lessThan(flames));

    final chatEntries = [
      'Schnellreaktionen',
      'Kontaktgruppen',
      'Im Urlaub',
      'Stories immer anzeigen',
      'Duplikate als geöffnet markieren',
    ];
    for (final (index, entry) in chatEntries.indexed) {
      expect(top(entry), inExclusiveRange(chats, camera), reason: entry);
      if (index > 0) {
        expect(top(entry), greaterThan(top(chatEntries[index - 1])));
      }
    }
    for (final entry in [
      'Mit geöffneter Kamera starten',
      'Bildvorschau bei der Auswahl von Empfängern anzeigen',
    ]) {
      expect(top(entry), inExclusiveRange(camera, flames), reason: entry);
    }
    expect(top('Wiederherstellung anbieten'), greaterThan(flames));

    // On Vacation is a Pro feature and says so.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Im Urlaub'),
          matching: find.byType(ListTile),
        ),
        matching: find.byType(ProBadge),
      ),
      findsOneWidget,
    );

    // Every subtitle on the page has the same size.
    double? size(String text) =>
        tester.widget<Text>(find.text(text)).style?.fontSize;
    expect(size('Friere deine Flammen ein, während du weg bist'), isNotNull);
    expect(
      size(
        'Wenn du die selbe Mediendatei in mehreren Chats erhältst, markiert '
        'das Öffnen einer Kopie alle anderen als geöffnet.',
      ),
      size('Friere deine Flammen ein, während du weg bist'),
    );
  });

  testWidgets(
    'design contains no camera controls and can always hide the news icon',
    (tester) async {
      await pumpSettings(tester, location: Routes.settingsAppearance);
      expect(find.text('Mit geöffneter Kamera starten'), findsNothing);
      final shortcut = find.ancestor(
        of: find.text('News-Symbol immer ausblenden'),
        matching: find.byType(SwitchListTile),
      );
      expect(tester.widget<SwitchListTile>(shortcut).value, isFalse);
      await tester.tap(shortcut);
      await pumpNative(
        tester,
        until: () => !userService.currentUser.showNewsShortcut,
      );
      final saved = await runNative(tester, UserConfigApi.load);
      expect(saved!.showNewsShortcut, isFalse);
    },
  );

  testWidgets(
    'notification permission refreshes after returning from system settings',
    (tester) async {
      notificationPermission = 0;
      await pumpSettings(tester, location: Routes.settingsNotification);
      expect(
        find.text('Benachrichtigungen im System ausgeschaltet'),
        findsOneWidget,
      );
      notificationPermission = 1;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.text('Benachrichtigungen im System ausgeschaltet'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'account backup status loads even while cloud usage is unavailable',
    (tester) async {
      final usage = Completer<FrbMemoriesUsage>();
      api.loadUsage = () => usage.future;
      await pumpSettings(
        tester,
        location: Routes.settingsBackup,
        textScale: 1.5,
      );
      await pumpNative(
        tester,
        until: () => find.text('Noch nicht gesichert').evaluate().isNotEmpty,
      );
      expect(
        find.text('Keine Kontowiederherstellung eingerichtet'),
        findsOneWidget,
      );
      expect(find.text('Noch nicht gesichert'), findsOneWidget);
      expect(find.text('Memories Backup'), findsOneWidget);
      expect(find.text('Upgrade erforderlich'), findsOneWidget);
      final save = tester.widget<MyButton>(find.byType(MyButton));
      expect(save.onPressed, isNull);
      expect(tester.takeException(), isNull);
      usage.complete(
        const FrbMemoriesUsage(currentBytes: 0, count: 0, maxBytes: 1000000),
      );
      await pumpNative(tester);
    },
  );

  testWidgets(
    'Memories settings hold backup, saving and import in one place',
    (tester) async {
      final usage = Completer<FrbMemoriesUsage>();
      api.loadUsage = () => usage.future;
      await pumpSettings(
        tester,
        location: Routes.settingsMemories,
        textScale: 1.5,
      );
      expect(find.text('Upgrade erforderlich'), findsOneWidget);
      for (final entry in [
        'Kopie in System-Galerie speichern',
        'Standort in Memories speichern',
        'Aus anderen Apps importieren',
      ]) {
        await tester.scrollUntilVisible(find.text(entry), 100);
        expect(find.text(entry), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      usage.complete(
        const FrbMemoriesUsage(currentBytes: 0, count: 0, maxBytes: 1000000),
      );
      await pumpNative(tester);
    },
  );

  testWidgets('Memories backup shows its usage and how to turn it off', (
    tester,
  ) async {
    api.loadUsage = () async => const FrbMemoriesUsage(
      currentBytes: 1200000000,
      count: 340,
      maxBytes: 5000000000,
    );
    await pumpSettings(tester, location: _memoriesBackupDetail);
    await pumpNative(
      tester,
      until: () => find.text('340 Memories in der Cloud').evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();
    expect(find.text('24 % belegt'), findsOneWidget);
    expect(find.text('Jetzt synchronisieren'), findsOneWidget);
    expect(find.text('Speicherplatz freigeben'), findsOneWidget);
    expect(find.text('Cloud-Backup deaktivieren'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('free up space shows an empty state without memories', (
    tester,
  ) async {
    await pumpSettings(tester, location: _storageContents);
    await pumpNative(
      tester,
      until: () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    );
    expect(find.text('Speicherplatz freigeben'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'configured friends are not reported as active until they confirm',
    (tester) async {
      final db = await runNative(tester, TestDatabase.create);
      await runNative(
        tester,
        () => db.customStatement(
          'INSERT INTO contacts(user_id, username, accepted, recovery_is_trusted_friend) '
          "VALUES (7, 'Alice', 1, 1), (8, 'Bob', 1, 1)",
        ),
      );
      userService.currentUser.passwordLessRecovery =
          config.PasswordlessRecoveryConfig(threshold: 2);
      await pumpSettings(tester, location: Routes.settingsBackup);
      await pumpNative(
        tester,
        until: () => find
            .textContaining('Noch zu wenige aktive Freunde')
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.text('Noch zu wenige aktive Freunde · 0 von 2 benötigt'),
        findsOneWidget,
      );
      await runNative(
        tester,
        () => db.customStatement(
          'UPDATE contacts SET recovery_last_heartbeat = ?',
          [DateTime.now().millisecondsSinceEpoch ~/ 1000],
        ),
      );
      await pumpNative(
        tester,
        until: () => find
            .textContaining('Genügend aktive Freunde')
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.text('Genügend aktive Freunde · 2 aktiv (mindestens 2 nötig)'),
        findsOneWidget,
      );
      expect(find.byType(PasswordLessRecoveryStatus), findsOneWidget);
    },
  );

  testWidgets(
    'main settings fit on a phone with large German and Arabic text',
    (tester) async {
      for (final locale in ['de', 'ar']) {
        await pumpSettings(tester, textScale: 2, locale: locale);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, -1800));
        await pumpNative(tester);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpNative(tester);
      }
    },
  );
}
