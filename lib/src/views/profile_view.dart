import 'package:provider/provider.dart';
import 'package:twonly/src/model/json/user_data.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/utils/storage.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  // final SettingsController settingsController;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final Future<UserData?> _userData = getUser();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: FutureBuilder(
            future: _userData,
            builder: (context, snap) {
              if (snap.hasData) {
                return Text("Settings");
                // return Text("Hello ${snap.data!.username}!");
              } else {
                return Container();
              }
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              // Glue the SettingsController to the theme selection DropdownButton.
              //
              // When a user selects a theme from the dropdown list, the
              // SettingsController is updated, which rebuilds the MaterialApp.
              child: DropdownButton<ThemeMode>(
                // Read the selected themeMode from the controller
                value: context.watch<SettingsChangeProvider>().themeMode,
                // Call the updateThemeMode method any time the user selects a theme.
                onChanged: (theme) {
                  context.read<SettingsChangeProvider>().updateThemeMode(theme);
                },
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System Theme'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light Theme'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark Theme'),
                  )
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                showLicensePage(context: context);
              },
              child: Text('Show Licenses'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await deleteLocalUserData();
                Restart.restartApp(
                  notificationTitle: 'Successfully logged out',
                  notificationBody: 'Click here to open the app again',
                );
              },
              label: Text("Logout"),
              icon: Icon(Icons.no_accounts),
            ),
          ],
        ));
  }
}
