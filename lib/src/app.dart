import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/providers/connection_provider.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/onboarding/onboarding_view.dart';
import 'package:twonly/src/views/home_view.dart';
import 'package:twonly/src/views/onboarding/register_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';

// these global function can be called from anywhere to update
// the ui when something changed. The callbacks will be set by
// MyApp widget.

// this callback is called by the apiProvider
Function(bool) globalCallbackConnectionState = (a) {};
bool globalIsAppInBackground = true;

// these two callbacks are called on updated to the corresponding database

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool wasPaused = false;

  @override
  void initState() {
    super.initState();
    globalIsAppInBackground = false;
    WidgetsBinding.instance.addObserver(this);

    // register global callbacks to the widget tree
    globalCallbackConnectionState = (update) {
      context.read<ConnectionChangeProvider>().updateConnectionState(update);
      setupNotificationWithUsers();
    };

    initAsync();
  }

  Future initAsync() async {
    apiProvider.connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (wasPaused) {
        globalIsAppInBackground = false;
        twonlyDatabase.markUpdated();
        apiProvider.connect();
        // _stopService();
      }
    } else if (state == AppLifecycleState.paused) {
      wasPaused = true;
      globalIsAppInBackground = true;
    }
  }

  @override
  void dispose() {
    // apiProvider.close(() {});
    WidgetsBinding.instance.removeObserver(this);
    // disable globalCallbacks to the flutter tree
    globalCallbackConnectionState = (a) {};
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // var isConnected = context.watch<ApiProvider>().isConnected;
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
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
          onGenerateTitle: (BuildContext context) => "twonly",
          theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF57CC99)),
              inputDecorationTheme:
                  const InputDecorationTheme(border: OutlineInputBorder())),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark, // <-- the only line added
              seedColor: const Color(0xFF57CC99),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          themeMode: context.watch<SettingsChangeProvider>().themeMode,
          initialRoute: '/',
          routes: {
            "/": (context) => MyAppMainWidget(initialPage: 0),
            "/chats": (context) => MyAppMainWidget(initialPage: 1)
            // home: MyAppMainWidget(isConnected: isConnected, initialPage: 0),
          },
        );
      },
    );
  }
}

class MyAppMainWidget extends StatefulWidget {
  const MyAppMainWidget({super.key, required this.initialPage});

  final int initialPage;

  @override
  State<MyAppMainWidget> createState() => _MyAppMainWidgetState();
}

class _MyAppMainWidgetState extends State<MyAppMainWidget> {
  Future<bool> _isUserCreated = isUserCreated();
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<bool>(
          future: _isUserCreated,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!) {
                return HomeView(
                  initialPage: widget.initialPage,
                );
              }

              if (_showOnboarding) {
                return OnboardingView(
                  callbackOnSuccess: () {
                    setState(() {
                      _showOnboarding = false;
                    });
                  },
                );
              }

              return RegisterView(
                callbackOnSuccess: () {
                  setState(() {
                    _isUserCreated = isUserCreated();
                  });
                },
              );
            } else {
              return Center(child: Container());
            }
          },
        ),
      ],
    );
  }
}
