import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/connection_state.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/providers/download_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/tasks/websocket_foreground_task.dart';
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
Function globalCallBackOnContactChange = () {};
Future Function(int, int?) globalCallBackOnMessageChange = (a, b) async {};
Function(List<int>, bool) globalCallBackOnDownloadChange = (a, b) {};

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isConnected = false;
  bool wasPaused = false;

  @override
  void initState() {
    super.initState();
    globalIsAppInBackground = false;
    WidgetsBinding.instance.addObserver(this);

    // init change provider to load data from the database
    context.read<ContactChangeProvider>().update();
    context.read<MessagesChangeProvider>().init();

    // register global callbacks to the widget tree
    globalCallbackConnectionState = (isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    };

    globalCallBackOnContactChange = () {
      context.read<ContactChangeProvider>().update();
    };

    globalCallBackOnDownloadChange = (token, add) {
      context.read<DownloadChangeProvider>().update(token, add);
    };

    globalCallBackOnMessageChange = (userId, messageId) async {
      await context
          .read<MessagesChangeProvider>()
          .updateLastMessageFor(userId, messageId);
    };

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _requestPermissions();
    //   _initService();
    // });
    initAsync();
  }

  Future initAsync() async {
    // make sure the front end service will be killed
    // FlutterForegroundTask.sendDataToTask("");
    // await FlutterForegroundTask.stopService();
    // connect async to the backend api
    apiProvider.connect();
  }

  Future<void> _requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Use this utility only if you provide services that require long-term survival,
      // such as exact alarm service, healthcare service, or Bluetooth communication.
      //
      // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
      // Using this permission may make app distribution difficult due to Google policy.
      // if (!await FlutterForegroundTask.canScheduleExactAlarms) {
      // When you call this function, will be gone to the settings page.
      // So you need to explain to the user why set it.
      // await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      // }
    }
  }

  void _initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<ServiceRequestResult> _startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Staying connected to the server.',
        notificationText: 'Tap to return to the app',
        notificationIcon:
            NotificationIcon(metaDataName: "eu.twonly.service.TWONLY_LOGO"),
        notificationInitialRoute: '/chats',
        callback: startCallback,
      );
    }
  }

  Future _stopService() async {
    if (context.mounted) {
      context.read<MessagesChangeProvider>().init(afterPaused: true);
      context.read<ContactChangeProvider>().update();
    }
    FlutterForegroundTask.sendDataToTask("");
    await FlutterForegroundTask.stopService();
    if (!apiProvider.isAuthenticated) {
      apiProvider.connect();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (wasPaused) {
        globalIsAppInBackground = false;
        apiProvider.connect();
        // _stopService();
      }
    } else if (state == AppLifecycleState.paused) {
      wasPaused = true;
      globalIsAppInBackground = true;
      apiProvider.close(() {
        // use this only when uploading an image
        // _startService();
      });
    }
  }

  @override
  void dispose() {
    // apiProvider.close(() {});
    WidgetsBinding.instance.removeObserver(this);
    // disable globalCallbacks to the flutter tree
    globalCallbackConnectionState = (a) {};
    globalCallBackOnDownloadChange = (a, b) {};
    globalCallBackOnContactChange = () {};
    globalCallBackOnMessageChange = (a, b) async {};
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
                seedColor: const Color(0xFF57CC99)),
            inputDecorationTheme:
                const InputDecorationTheme(border: OutlineInputBorder()),
          ),
          themeMode: context.watch<SettingsChangeProvider>().themeMode,
          initialRoute: '/',
          routes: {
            "/": (context) =>
                MyAppMainWidget(isConnected: _isConnected, initialPage: 0),
            "/chats": (context) =>
                MyAppMainWidget(isConnected: _isConnected, initialPage: 1)
            // home: MyAppMainWidget(isConnected: _isConnected, initialPage: 0),
          },
        );
      },
    );
  }
}

class MyAppMainWidget extends StatefulWidget {
  const MyAppMainWidget(
      {super.key, required this.isConnected, required this.initialPage});

  final bool isConnected;
  final int initialPage;

  @override
  State<MyAppMainWidget> createState() => _MyAppMainWidgetState();
}

class _MyAppMainWidgetState extends State<MyAppMainWidget> {
  Future<bool> _isUserCreated =
      isUserCreated(); // Assume this is a function that checks if the user is created
  bool _showOnboarding = true; // Initial state for onboarding

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<bool>(
          future: _isUserCreated,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!) {
                return HomeView(initialPage: widget.initialPage);
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
        if (!widget.isConnected) ConnectionInfo()
      ],
    );
  }
}
