import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/themes/dark.dart';
import 'package:twonly/src/themes/light.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/pow.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/app_outdated.dart';
import 'package:twonly/src/views/home.view.dart';
import 'package:twonly/src/views/onboarding/onboarding.view.dart';
import 'package:twonly/src/views/onboarding/register.view.dart';
import 'package:twonly/src/views/settings/backup/setup_backup.view.dart';
import 'package:twonly/src/views/unlock_twonly.view.dart';

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
    AppState.isAppInBackground = false;
    WidgetsBinding.instance.addObserver(this);

    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    final user = await getUser();
    if (user != null && mounted) {
      context.read<PurchasesProvider>().updatePlan(
        planFromString(user.subscriptionPlan),
      );
    }
    await apiService.connect();
    await apiService.listenToNetworkChanges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (wasPaused) {
        AppState.isAppInBackground = false;
        twonlyDB.markUpdated();
        unawaited(apiService.connect());
      }
    } else if (state == AppLifecycleState.paused) {
      wasPaused = true;
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
      listenable: context.watch<SettingsChangeProvider>(),
      builder: (context, child) {
        return MaterialApp.router(
          routerConfig: routerProvider,
          scaffoldMessengerKey: AppGlobalKeys.scaffoldMessengerKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          supportedLocales: const [
            Locale('en', ''),
            Locale('de', ''),
          ],
          title: 'twonly',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: context.watch<SettingsChangeProvider>().themeMode,
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
  bool _skipBackup = false;
  bool _isTwonlyLocked = true;

  (Future<int>?, bool) _proofOfWork = (null, false);

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    _isUserCreated = await isUserCreated();

    if (_isUserCreated) {
      if (_isTwonlyLocked) {
        // do not change in case twonly was already unlocked at some point
        _isTwonlyLocked = gUser.screenLockEnabled;
      }
      if (gUser.appVersion < 62) {
        _showDatabaseMigration = true;
      }
    }

    if (!_isUserCreated && !_showDatabaseMigration) {
      // This means the user is in the onboarding screen, so start with the Proof of Work.

      final (proof, disabled) = await apiService.getProofOfWork();
      if (proof != null) {
        Log.info('Starting with proof of work calculation.');
        // Starting with the proof of work.
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

    if (_showDatabaseMigration) {
      child = const Center(child: Text('Please reinstall twonly.'));
    } else if (_isUserCreated) {
      if (_isTwonlyLocked) {
        child = UnlockTwonlyView(
          callbackOnSuccess: () => setState(() {
            _isTwonlyLocked = false;
          }),
        );
      } else if (gUser.twonlySafeBackup == null && !_skipBackup) {
        child = SetupBackupView(
          callBack: () {
            _skipBackup = true;
            setState(() {});
          },
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
        const AppOutdated(),
      ],
    );
  }
}
