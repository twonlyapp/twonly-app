import 'package:camera/camera.dart';
import 'views/home_view.dart';
import 'views/register_view.dart';
import 'utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';

import 'settings/settings_controller.dart';

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  const MyApp(
      {super.key, required this.settingsController, required this.cameras});

  final SettingsController settingsController;
  final List<CameraDescription> cameras;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> _isUserCreated = isUserCreated();

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          // localizationsDelegates: const [
          //   AppLocalizations.delegate,
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          //   GlobalCupertinoLocalizations.delegate,
          // ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],
          onGenerateTitle: (BuildContext context) => "Connect!",
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
          home: FutureBuilder<bool>(
              future: _isUserCreated,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data!
                      ? HomeView(
                          settingsController: widget.settingsController,
                          cameras: widget.cameras)
                      : RegisterView(callbackOnSuccess: () {
                          _isUserCreated = isUserCreated();
                          setState(() {});
                        });
                } else {
                  return Center(
                      child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(),
                  ));
                }
              }),
        );
      },
    );
  }
}
