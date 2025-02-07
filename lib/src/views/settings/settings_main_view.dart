import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/json/user_data.dart';
import 'package:restart_app/restart_app.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/utils/storage.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserData? userData;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    userData = await getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: (userData == null)
          ? null
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Row(
                    children: [
                      InitialsAvatar(
                        displayName: userData!.username,
                        fontSize: 30,
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData!.displayName,
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              userData!.username,
                              style: TextStyle(
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: () {},
                          icon: FaIcon(FontAwesomeIcons.qrcode),
                        ),
                      )
                    ],
                  ),
                ),
                SettingsListTile(
                  icon: FontAwesomeIcons.user,
                  text: "Konto",
                  onTap: () {},
                ),
                SettingsListTile(
                  icon: FontAwesomeIcons.shieldHeart,
                  text: "Subscription",
                  onTap: () {},
                ),
                const Divider(),
                SettingsListTile(
                  icon: FontAwesomeIcons.sun,
                  text: "Darstellung",
                  onTap: () {},
                ),
                SettingsListTile(
                  icon: FontAwesomeIcons.lock,
                  text: "Datenschutz",
                  onTap: () {},
                ),
                SettingsListTile(
                  icon: FontAwesomeIcons.bell,
                  text: "Benachrichtigungen",
                  onTap: () async {
                    const AndroidNotificationDetails
                        androidNotificationDetails = AndroidNotificationDetails(
                      '0',
                      'Messages',
                      channelDescription: 'Messages from other users.',
                      importance: Importance.max,
                      priority: Priority.high,
                      ticker: 'ticker',
                    );
                    const NotificationDetails notificationDetails =
                        NotificationDetails(
                            android: androidNotificationDetails);
                    await flutterLocalNotificationsPlugin.show(0, 'New message',
                        'You got a new message from XX', notificationDetails,
                        payload: 'item x');
                  },
                ),
                const Divider(),
                SettingsListTile(
                  icon: FontAwesomeIcons.circleQuestion,
                  text: "Help",
                  onTap: () {},
                ),
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   // Glue the SettingsController to the theme selection DropdownButton.
                //   //
                //   // When a user selects a theme from the dropdown list, the
                //   // SettingsController is updated, which rebuilds the MaterialApp.
                //   child: DropdownButton<ThemeMode>(
                //     // Read the selected themeMode from the controller
                //     value: context.watch<SettingsChangeProvider>().themeMode,
                //     // Call the updateThemeMode method any time the user selects a theme.
                //     onChanged: (theme) {
                //       context
                //           .read<SettingsChangeProvider>()
                //           .updateThemeMode(theme);
                //     },
                //     items: const [
                //       DropdownMenuItem(
                //         value: ThemeMode.system,
                //         child: Text('System Theme'),
                //       ),
                //       DropdownMenuItem(
                //         value: ThemeMode.light,
                //         child: Text('Light Theme'),
                //       ),
                //       DropdownMenuItem(
                //         value: ThemeMode.dark,
                //         child: Text('Dark Theme'),
                //       )
                //     ],
                //   ),
                // ),
                // ElevatedButton(
                //   onPressed: () {
                //     showLicensePage(context: context);
                //   },
                //   child: Text('Show Licenses'),
                // ),
                // FilledButton.icon(
                //   onPressed: () async {
                //     await deleteLocalUserData();
                //     Restart.restartApp(
                //       notificationTitle: 'Successfully logged out',
                //       notificationBody: 'Click here to open the app again',
                //     );
                //   },
                //   label: Text("Logout"),
                //   icon: Icon(Icons.no_accounts),
                // ),
              ],
            ),
    );
  }
}

class SettingsListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const SettingsListTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(
          right: 10,
          left: 19,
        ),
        child: FaIcon(
          icon,
          size: 20,
        ),
      ),
      title: Text(text),
      onTap: onTap,
    );
  }
}
