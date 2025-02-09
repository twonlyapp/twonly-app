import 'package:provider/provider.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/providers/download_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      apiProvider.connect();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // disable globalCallbacks to the flutter tree
    globalCallbackConnectionState = (a) {};
    globalCallBackOnDownloadChange = (a, b) {};
    globalCallBackOnContactChange = () {};
    globalCallBackOnMessageChange = (a) {};
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
