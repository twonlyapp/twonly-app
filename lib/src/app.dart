import 'package:twonly/main.dart';
import 'views/home_view.dart';
import 'views/register_view.dart';
import 'utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'settings/settings_controller.dart';

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> _isUserCreated = isUserCreated();
  bool _isConnected = false;
  int redColorOpacity = 0; // Start with dark red
  bool redColorGoUp = true;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    // Start the color animation
    _startColorAnimation();
    apiProvider.setConnectionStateCallback((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });
    apiProvider.connect();
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
      listenable: widget.settingsController,
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
          themeMode: widget.settingsController.themeMode,
          home: Stack(
            children: [
              FutureBuilder<bool>(
                  future: _isUserCreated,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return snapshot.data!
                          ? HomeView(
                              settingsController: widget.settingsController)
                          : RegisterView(
                              callbackOnSuccess: () {
                                _isUserCreated = isUserCreated();
                                setState(() {});
                              },
                            ); // Show the red line if not connected
                    } else {
                      return Container();
                    }
                  }),
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
                          Radius.circular(10.0)), // Rounded top corners
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
