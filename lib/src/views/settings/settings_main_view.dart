import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/json/user_data.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/account_view.dart';
import 'package:twonly/src/views/settings/appearance_view.dart';
import 'package:twonly/src/views/settings/help_view.dart';
import 'package:twonly/src/views/settings/privacy_view.dart';

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
        title: Text(context.lang.settingsTitle),
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
                  text: context.lang.settingsAccount,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return AccountView();
                    }));
                  },
                ),
                SettingsListTile(
                  icon: FontAwesomeIcons.shieldHeart,
                  text: context.lang.settingsSubscription,
                  onTap: () {},
                ),
                const Divider(),
                SettingsListTile(
                  icon: FontAwesomeIcons.sun,
                  text: context.lang.settingsAppearance,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return AppearanceView();
                    }));
                  },
                ),
                SettingsListTile(
                  icon: FontAwesomeIcons.lock,
                  text: context.lang.settingsPrivacy,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return PrivacyView();
                    }));
                  },
                ),
                SettingsListTile(
                  icon: FontAwesomeIcons.bell,
                  text: context.lang.settingsNotification,
                  onTap: () async {
                    const AndroidNotificationDetails
                        androidNotificationDetails = AndroidNotificationDetails(
                      '0',
                      'Messages',
                      channelDescription: 'Messages from other users.',
                      importance: Importance.max,
                      priority: Priority.max,
                      ticker: 'You got a new message.',
                    );
                    const NotificationDetails notificationDetails =
                        NotificationDetails(
                            android: androidNotificationDetails);
                    await flutterLocalNotificationsPlugin.show(
                        0,
                        'New message from x',
                        'You got a new message from XX',
                        notificationDetails,
                        payload: 'test');
                  },
                ),
                const Divider(),
                SettingsListTile(
                  icon: FontAwesomeIcons.circleQuestion,
                  text: context.lang.settingsHelp,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return HelpView();
                      },
                    ));
                  },
                ),
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
