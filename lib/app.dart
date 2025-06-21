import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/onboarding/onboarding.view.dart';
import 'package:twonly/src/views/home.view.dart';
import 'package:twonly/src/views/onboarding/register.view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';

// these two callbacks are called on updated to the corresponding database

/// The Widget that configures your application.
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

    // register global callbacks to the widget tree
    globalCallbackConnectionState = (update) {
      context.read<CustomChangeProvider>().updateConnectionState(update);
      setUserPlan();
    };

    initAsync();
  }

  Future setUserPlan() async {
    final user = await getUser();
    globalBestFriendUserId = -1;
    if (user != null && mounted) {
      if (user.myBestFriendContactId != null) {
        final contact = await twonlyDB.contactsDao
            .getContactByUserId(user.myBestFriendContactId!)
            .getSingleOrNull();
        if (contact != null) {
          if (contact.alsoBestFriend) {
            globalBestFriendUserId = user.myBestFriendContactId ?? 0;
          }
        }
      }
      if (mounted) {
        context.read<CustomChangeProvider>().updatePlan(user.subscriptionPlan);
      }
    }
  }

  Future initAsync() async {
    setUserPlan();
    await apiService.connect(force: true);
    apiService.listenToNetworkChanges();
    // call this function so invalid media files are get purged
    retryMediaUpload(true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (wasPaused) {
        globalIsAppInBackground = false;
        twonlyDB.markUpdated();
        apiService.connect(force: true);
      }
    } else if (state == AppLifecycleState.paused) {
      wasPaused = true;
      globalIsAppInBackground = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    globalCallbackConnectionState = (a) {};
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
          onGenerateTitle: (BuildContext context) => "twonly",
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
            "/": (context) => AppMainWidget(initialPage: 1),
            "/chats": (context) => AppMainWidget(initialPage: 0)
          },
        );
      },
    );
  }
}

class AppMainWidget extends StatefulWidget {
  const AppMainWidget({super.key, required this.initialPage});
  final int initialPage;
  @override
  State<AppMainWidget> createState() => _AppMainWidgetState();
}

class _AppMainWidgetState extends State<AppMainWidget> {
  Future<bool> userCreated = isUserCreated();
  bool showOnboarding = kReleaseMode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<bool>(
          future: userCreated,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: Container());
            }

            if (snapshot.data!) {
              return HomeView(
                initialPage: widget.initialPage,
              );
            }

            return showOnboarding
                ? OnboardingView(
                    callbackOnSuccess: () {
                      setState(() {
                        showOnboarding = false;
                      });
                    },
                  )
                : RegisterView(
                    callbackOnSuccess: () {
                      setState(() {
                        userCreated = isUserCreated();
                      });
                    },
                  );
          },
        ),
      ],
    );
  }
}
