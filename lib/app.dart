import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/pow.dart';
import 'package:twonly/src/visual/components/app_outdated.comp.dart';
import 'package:twonly/src/visual/themes/dark.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/critical_error.view.dart';
import 'package:twonly/src/visual/views/home.view.dart';
import 'package:twonly/src/visual/views/onboarding/onboarding.view.dart';
import 'package:twonly/src/visual/views/onboarding/register.view.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';
import 'package:twonly/src/visual/views/unlock_twonly.view.dart';

class App extends StatefulWidget {
  const App({required this.storageError, super.key});
  final bool storageError;
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    AppState.isAppInBackground = false;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_wasPaused) {
        AppState.isAppInBackground = false;
        twonlyDB.markUpdated();
        unawaited(apiService.connect());
      }
    } else if (state == AppLifecycleState.paused) {
      _wasPaused = true;
      AppState.isAppInBackground = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.read<SettingsChangeProvider>(),
      builder: (context, child) {
        const localizationsDelegates = [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ];

        const supportedLocales = [
          Locale('en', ''),
          Locale('de', ''),
        ];

        if (widget.storageError) {
          return MaterialApp(
            scaffoldMessengerKey: AppGlobalKeys.scaffoldMessengerKey,
            localizationsDelegates: localizationsDelegates,
            debugShowCheckedModeBanner: false,
            supportedLocales: supportedLocales,
            title: 'twonly',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: context.read<SettingsChangeProvider>().themeMode,
            home: const CriticalErrorView(),
          );
        }

        return MaterialApp.router(
          routerConfig: routerProvider,
          scaffoldMessengerKey: AppGlobalKeys.scaffoldMessengerKey,
          localizationsDelegates: localizationsDelegates,
          debugShowCheckedModeBanner: false,
          supportedLocales: supportedLocales,
          title: 'twonly',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: context.read<SettingsChangeProvider>().themeMode,
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
  bool _showOnboarding = true;
  bool _isLoaded = false;
  bool _isTwonlyLocked = true;

  (Future<int>?, bool) _proofOfWork = (null, false);

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    if (userService.isUserCreated) {
      if (_isTwonlyLocked) {
        // do not change in case twonly was already unlocked at some point
        _isTwonlyLocked = userService.currentUser.screenLockEnabled;
      }
    } else {
      // This means the user is in the onboarding screen, so start with the Proof of Work.

      final (proof, disabled) = await apiService.getProofOfWork();
      if (proof != null) {
        Log.info('Starting with proof of work calculation.');
        _proofOfWork = (
          calculatePoW(proof.prefix, proof.difficulty.toInt()),
          false,
        );
      } else {
        _proofOfWork = (null, disabled);
      }
    }

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

    if (userService.isUserCreated) {
      if (_isTwonlyLocked) {
        child = UnlockTwonlyView(
          callbackOnSuccess: () => setState(() {
            _isTwonlyLocked = false;
          }),
        );
      } else if (!userService.currentUser.skipSetupPages &&
          userService.currentUser.currentSetupPage != null) {
        // This will only be shown in case the user have not skipped
        child = SetupView(
          onUpdate: () => setState(() {
            // userService.currentUser has updated...
          }),
        );
      } else {
        child = HomeView(
          initialPage: widget.initialPage,
        );
      }
    } else if (_showOnboarding) {
      child = OnboardingView(
        callbackOnSuccess: () => setState(() {
          _showOnboarding = false;
        }),
      );
    } else {
      child = RegisterView(
        callbackOnSuccess: initAsync,
        proofOfWork: _proofOfWork,
      );
    }

    return Stack(
      children: [
        child,
        const AppOutdatedComp(),
      ],
    );
  }
}
