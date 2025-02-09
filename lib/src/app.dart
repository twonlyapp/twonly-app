import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
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

// these two callbacks are called on updated to the corresponding database
Function globalCallBackOnContactChange = () {};
Function(int) globalCallBackOnMessageChange = (a) {};
Function(List<int>, bool) globalCallBackOnDownloadChange = (a, b) {};

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Future<bool> _isUserCreated = isUserCreated();
  bool _showOnboarding = true;
  bool _isConnected = false;
  int redColorOpacity = 0; // Start with dark red
  bool redColorGoUp = true;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startColorAnimation();

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

    globalCallBackOnMessageChange = (userId) {
      context.read<MessagesChangeProvider>().updateLastMessageFor(userId);
    };

    // connect async to the backend api
    apiProvider.connect();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
      _initService();
    });
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

  void _onReceiveTaskData(Object data) {
    if (data is Map<String, dynamic>) {
      final dynamic timestampMillis = data["timestampMillis"];
      if (timestampMillis != null) {
        final DateTime timestamp =
            DateTime.fromMillisecondsSinceEpoch(timestampMillis, isUtc: true);
        print('timestamp: ${timestamp.toString()}');
      }
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
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        notificationIcon:
            NotificationIcon(metaDataName: "eu.twonly.service.TWONLY_LOGO"),
        notificationInitialRoute: '/',
        callback: startCallback,
      );
    }
  }

  Future _stopService() async {
    await FlutterForegroundTask.stopService();
    if (!apiProvider.isAuthenticated) {
      apiProvider.connect();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("STATE: $state");
    if (state == AppLifecycleState.resumed) {
      _stopService();
      //apiProvider.connect();
    } else if (state == AppLifecycleState.paused) {
      apiProvider.close(() {
        _startService();
      });
    }
  }

  @override
  void dispose() {
    print("STATE: dispose");
    // apiProvider.close(() {});
    WidgetsBinding.instance.removeObserver(this);
    // disable globalCallbacks to the flutter tree
    globalCallbackConnectionState = (a) {};
    globalCallBackOnDownloadChange = (a, b) {};
    globalCallBackOnContactChange = () {};
    globalCallBackOnMessageChange = (a) {};
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  void _startColorAnimation() {
    // Change the color every second
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        if (redColorOpacity <= 100) {
          redColorGoUp = true;
        }
        if (redColorOpacity >= 150) {
          redColorGoUp = false;
        }
        if (redColorGoUp) {
          redColorOpacity += 10;
        } else {
          redColorOpacity -= 10;
        }
      });
      _startColorAnimation(); // Repeat the animation
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
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
          home: Stack(
            children: [
              FutureBuilder<bool>(
                future: _isUserCreated,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!
                        ? HomeView()
                        : _showOnboarding
                            ? OnboardingView(
                                callbackOnSuccess: () {
                                  setState(() {
                                    _showOnboarding = false;
                                  });
                                },
                              )
                            : RegisterView(
                                callbackOnSuccess: () {
                                  _isUserCreated = isUserCreated();
                                  setState(() {});
                                },
                              );
                  } else {
                    return Container();
                  }
                },
              ),
              if (!_isConnected)
                Positioned(
                  top: 3, // Position it at the top
                  left: (screenWidth * 0.5) / 2, // Center it horizontally
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 100),
                    width: screenWidth * 0.5, // 50% of the screen width
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.red[600]!.withAlpha(redColorOpacity),
                          width: 2.0), // Red border
                      borderRadius: BorderRadius.all(
                        Radius.circular(10.0),
                      ), // Rounded top corners
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
