import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart' show SharedFile;
import 'package:provider/provider.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/home_widget.service.dart';
import 'package:twonly/src/services/intent/links.intent.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/pow.dart';
import 'package:twonly/src/visual/components/app_outdated.comp.dart';
import 'package:twonly/src/visual/components/mailbox_sync.comp.dart';
import 'package:twonly/src/visual/themes/dark.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/critical_error.view.dart';
import 'package:twonly/src/visual/views/home.view.dart';
import 'package:twonly/src/visual/views/onboarding/onboarding.view.dart';
import 'package:twonly/src/visual/views/onboarding/register.view.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';
import 'package:twonly/src/visual/views/recovery_from_secure_storage.view.dart';
import 'package:twonly/src/visual/views/unlock_twonly.view.dart';

class App extends StatefulWidget {
  const App({
    required this.storageError,
    required this.recoveryPossible,
    super.key,
  });
  final bool storageError;
  final bool recoveryPossible;
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  StreamSubscription<Uri>? _widgetLinkSub;

  @override
  void initState() {
    super.initState();
    AppState.isAppInBackground =
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    unawaited(NativeNotificationService.refreshBadgeCount());
    // This stays subscribed on routes that do not contain a home view, such
    // as settings. The home view consumes the sender after navigation/unlock.
    _widgetLinkSub = AppLinks().uriLinkStream.listen((uri) {
      if (!HomeWidgetService.handleLink(uri)) return;
      if (widget.storageError || widget.recoveryPossible) return;
      if (!HomeWidgetService.hasTapListener) routerProvider.go(Routes.chats);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      AppState.isAppInBackground = false;
      unawaited(_resumeDatabaseServices());
    } else if (state == AppLifecycleState.paused) {
      AppState.isAppInBackground = true;
      unawaited(
        apiService.setBackground(true),
      );
    } else if (state == AppLifecycleState.detached) {
      AppState.isAppInBackground = true;
      unawaited(apiService.setBackground(true));
    }
  }

  Future<void> _resumeDatabaseServices() async {
    // Native resume reopens both pools and rebinds Signal before any badge,
    // snapshot, widget or expiry query is allowed to run.
    await apiService.setBackground(false);
    if (AppState.isAppInBackground) return;
    unawaited(BackupService.resumePendingBackup());
    refreshDatabaseSubscriptions();
    unawaited(NativeNotificationService.refreshBadgeCount());
    if (userService.isUserCreated) {
      unawaited(HomeWidgetService.syncPermissions());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetLinkSub?.cancel();
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

        final settings = context.watch<SettingsChangeProvider>();

        if (widget.storageError) {
          return MaterialApp(
            localizationsDelegates: localizationsDelegates,
            debugShowCheckedModeBanner: false,
            supportedLocales: supportedLocales,
            locale: settings.locale,
            title: 'twonly',
            theme: getLightTheme(settings.primaryColor),
            darkTheme: getDarkTheme(settings.primaryColor),
            themeMode: settings.themeMode,
            home: const CriticalErrorView(),
          );
        }

        if (widget.recoveryPossible) {
          return MaterialApp(
            localizationsDelegates: localizationsDelegates,
            debugShowCheckedModeBanner: false,
            supportedLocales: supportedLocales,
            locale: settings.locale,
            title: 'twonly',
            theme: getLightTheme(settings.primaryColor),
            darkTheme: getDarkTheme(settings.primaryColor),
            themeMode: settings.themeMode,
            home: const RecoveryView(),
          );
        }

        return MaterialApp.router(
          routerConfig: routerProvider,
          localizationsDelegates: localizationsDelegates,
          debugShowCheckedModeBanner: false,
          supportedLocales: supportedLocales,
          locale: settings.locale,
          title: 'twonly',
          theme: getLightTheme(settings.primaryColor),
          darkTheme: getDarkTheme(settings.primaryColor),
          themeMode: settings.themeMode,
          // Above the navigator, so a catch-up covers whichever screen is open.
          builder: (context, child) => Stack(
            children: [
              ?child,
              const MailboxSyncOverlay(),
            ],
          ),
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
  bool _initializationFailed = false;
  bool _isTwonlyLocked = true;
  int _initializationAttempt = 0;
  late int _initialPage;

  StreamSubscription<Uri>? _deepLinkSub;
  StreamSubscription<List<SharedFile>>? _intentStreamSub;
  StreamSubscription<String>? _emailTokenSub;

  (Future<int>?, bool) _proofOfWork = (null, false);

  @override
  void initState() {
    super.initState();
    _initialPage = widget.initialPage;
    Log.info('AppWidgetState: initState started');
    initAsync();

    void handleShareLink(Uri uri) {
      HomeViewState.pendingSharedLink = uri;
      routerProvider.go(Routes.home);
      HomeViewState.streamHomeViewPageIndex.add(1);
      HomeViewState.streamSharedLink.add(uri);
    }

    Future<void> handleIncomingUrl(Uri uri) async {
      if (!mounted) return;
      Log.info('Handling incoming link: ${uri.scheme}://${uri.host}');
      if (!await handleIntentUrl(context, uri)) {
        if (uri.scheme.startsWith('http')) {
          handleShareLink(uri);
        }
      }
    }

    // Subscribe to all events (initial link and further)
    _deepLinkSub = AppLinks().uriLinkStream.listen(handleIncomingUrl);

    void handleShareMedia(String path, MediaType type) {
      HomeViewState.pendingSharedMedia = (path, type);
      routerProvider.go(Routes.home);
      HomeViewState.streamHomeViewPageIndex.add(0);
      HomeViewState.streamSharedMedia.add((path, type));
    }

    _intentStreamSub = initIntentStreams(
      context,
      handleIncomingUrl,
      handleShareMedia,
    );
  }

  Future<void> initAsync() async {
    final attempt = ++_initializationAttempt;
    setState(() {
      _isLoaded = false;
      _initializationFailed = false;
    });
    Log.info('AppWidgetState: initAsync started');
    try {
      await _initializeRoute();
      if (!mounted || attempt != _initializationAttempt) return;
      setState(() => _isLoaded = true);
      Log.info('AppWidgetState: initAsync finished');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && attempt == _initializationAttempt) {
          Log.info('AppWidgetState: first loaded frame rendered');
        }
      });
    } catch (error, stackTrace) {
      Log.error(
        'Could not initialize the app screen',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted || attempt != _initializationAttempt) return;
      setState(() => _initializationFailed = true);
    }
  }

  Future<void> _initializeRoute() async {
    final onboardingState = await KeyValueStore.getModel<OnboardingState>(
      KeyValueKeys.onboardingState,
    ).timeout(const Duration(seconds: 10));
    if (!mounted) return;
    _showOnboarding = !onboardingState.hasOnboardingFinished;
    if (userService.isUserCreated) {
      if (_initialPage != 0) {
        final count = await rust_contacts
            .countContacts(
              metric: db_contacts.ContactCount.all,
              transaction: currentDatabaseSession(),
            )
            .timeout(const Duration(seconds: 10));
        if (!mounted) return;
        if (count == 0) {
          _initialPage = 0;
        }
      }
      unawaited(() async {
        try {
          await FirebaseMessaging.instance.requestPermission();
        } catch (error) {
          Log.error(error);
        }
      }());
      if (_isTwonlyLocked) {
        // do not change in case twonly was already unlocked at some point
        _isTwonlyLocked = userService.currentUser.screenLockEnabled;
      }
    } else {
      // This means the user is in the onboarding screen, so start with the Proof of Work.

      final proofResult = await rustApiResult(
        RustApi.getProofOfWork(),
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      final proof = proofResult.value;
      final disabled = proofResult.error == ErrorCode.RegistrationDisabled;
      if (proof != null) {
        Log.info('Starting with proof of work calculation.');
        _proofOfWork = (
          calculatePoW(proof.prefix, proof.difficulty),
          false,
        );
      } else {
        _proofOfWork = (null, disabled);
      }

      if (onboardingState.hasStartedPasswordlessRecovery ||
          onboardingState.emailRecoveryRequested) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          routerProvider.push(Routes.recoverPasswordless);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationFailed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.lang.recoverErrorUnknown,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: initAsync,
                  child: Text(context.lang.unlockTwonlyTryAgain),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
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
          initialPage: _initialPage,
        );
      }
    } else if (_showOnboarding) {
      child = OnboardingView(
        callbackOnSuccess: () async {
          await KeyValueStore.update<OnboardingState>(
            key: KeyValueKeys.onboardingState,
            update: (state) => state.hasOnboardingFinished = true,
          );
          if (mounted) setState(() => _showOnboarding = false);
        },
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

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _intentStreamSub?.cancel();
    _emailTokenSub?.cancel();
    super.dispose();
  }
}
