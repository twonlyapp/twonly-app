import '../settings/settings_controller.dart';
import '../settings/settings_view.dart';
import '../utils.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    // var user = await getUser();
    return Scaffold(
      appBar: AppBar(
          title: FutureBuilder(
              future: getUser(),
              builder: (context, snap) {
                if (snap.hasData) {
                  return Text("Hello ${snap.data!.username}!");
                } else {
                  return CircularProgressIndicator();
                }
              }),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to the settings page. If the user leaves and returns
                // to the app after it has been killed while running in the
                // background, the navigation stack is restored.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SettingsView(controller: widget.settingsController)),
                );
              },
            ),
          ]),
      body: FilledButton.icon(
          onPressed: () async {
            await deleteLocalUserData();
            Restart.restartApp(
              notificationTitle: 'Successfully logged out',
              notificationBody: 'Click here to open the app again',
            );
          },
          label: Text("Logout"),
          icon: Icon(Icons.no_accounts)),
    );
  }
}
