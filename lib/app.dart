import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/app_outdated.dart';
import 'package:twonly/src/views/home.view.dart';
import 'package:twonly/src/views/onboarding/onboarding.view.dart';
import 'package:twonly/src/views/onboarding/register.view.dart';
import 'package:twonly/src/views/updates/62_database_migration.view.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  bool wasPaused = false;

  @override
  void initState() {
    super.initState();
    globalIsAppInBackground = false;
    WidgetsBinding.instance.addObserver(this);

    globalCallbackConnectionState = ({required bool isConnected}) async {
      await context
          .read<CustomChangeProvider>()
          .updateConnectionState(isConnected);
      await setUserPlan();
    };

    globalCallbackUpdatePlan = (String planId) async {
      await context.read<CustomChangeProvider>().updatePlan(planId);
    };

    unawaited(initAsync());
  }

  Future<void> setUserPlan() async {
    final user = await getUser();
    if (user != null && mounted) {
      if (mounted) {
        await context
            .read<CustomChangeProvider>()
            .updatePlan(user.subscriptionPlan);
      }
    }
  }

  Future<void> initAsync() async {
    await setUserPlan();
    await apiService.connect(force: true);
    await apiService.listenToNetworkChanges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (wasPaused) {
        globalIsAppInBackground = false;
        twonlyDB.markUpdated();
        unawaited(apiService.connect(force: true));
      }
    } else if (state == AppLifecycleState.paused) {
      wasPaused = true;
      globalIsAppInBackground = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    globalCallbackConnectionState = ({required bool isConnected}) {};
    globalCallbackUpdatePlan = (String planId) {};
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.watch<SettingsChangeProvider>(),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('de', ''),
          ],
          onGenerateTitle: (BuildContext context) => 'twonly',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF57CC99),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              },
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF57CC99),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          themeMode: context.watch<SettingsChangeProvider>().themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const AppMainWidget(initialPage: 1),
            '/chats': (context) => const AppMainWidget(initialPage: 0),
          },
        );
      },
    );
  }
}

class AppMainWidget extends StatefulWidget {
  const AppMainWidget({
    required this.initialPage,
    super.key,
  });
  final int initialPage;
  @override
  State<AppMainWidget> createState() => _AppMainWidgetState();
}

class _AppMainWidgetState extends State<AppMainWidget> {
  bool _isUserCreated = false;
  bool _showDatabaseMigration = false;
  bool _showOnboarding = true;
  bool _isLoaded = false;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    _showDatabaseMigration = File(
      join(
        (await getApplicationSupportDirectory()).path,
        'twonly_database.sqlite',
      ),
    ).existsSync();

    _isUserCreated = await isUserCreated();
    setState(() {
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return Center(child: Container());
    }

    late Widget child;

    if (_showDatabaseMigration) {
      child = const DatabaseMigrationView();
    } else if (_isUserCreated) {
      child = HomeView(
        initialPage: widget.initialPage,
      );
    } else if (_showOnboarding) {
      child = OnboardingView(
        callbackOnSuccess: () => setState(() {
          _showOnboarding = false;
        }),
      );
    } else {
      child = RegisterView(
        callbackOnSuccess: initAsync,
      );
    }

    return Stack(
      children: [
        child,
        const AppOutdated(),
      ],
    );
  }
}
