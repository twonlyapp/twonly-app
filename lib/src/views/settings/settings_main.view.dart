import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/account.view.dart';
import 'package:twonly/src/views/settings/appearance.view.dart';
import 'package:twonly/src/views/settings/backup/backup.view.dart';
import 'package:twonly/src/views/settings/chat/chat_settings.view.dart';
import 'package:twonly/src/views/settings/data_and_storage.view.dart';
import 'package:twonly/src/views/settings/notification.view.dart';
import 'package:twonly/src/views/settings/profile/profile.view.dart';
import 'package:twonly/src/views/settings/help/help.view.dart';
import 'package:twonly/src/views/settings/privacy.view.dart';
import 'package:twonly/src/views/settings/share_with_friends.view.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

class SettingsMainView extends StatefulWidget {
  const SettingsMainView({super.key});

  @override
  State<SettingsMainView> createState() => _SettingsMainViewState();
}

class _SettingsMainViewState extends State<SettingsMainView> {
  UserData? userData;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    userData = await getUser();
    setState(() {});
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ProfileView();
                            }));
                            initAsync();
                          },
                          child: Container(
                            color: context.color.surface.withAlpha(0),
                            child: Row(
                              children: [
                                ContactAvatar(
                                  userData: userData!,
                                  fontSize: 30,
                                ),
                                Container(width: 20, color: Colors.transparent),
                                Column(
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: IconButton(
                      //     onPressed: () {},
                      //     icon: FaIcon(FontAwesomeIcons.qrcode),
                      //   ),
                      // )
                    ],
                  ),
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.user,
                  text: context.lang.settingsAccount,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return AccountView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.shieldHeart,
                  text: context.lang.settingsSubscription,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SubscriptionView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: Icons.lock_clock_rounded,
                  text: context.lang.settingsBackup,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return BackupView();
                    }));
                  },
                ),
                const Divider(),
                BetterListTile(
                  icon: FontAwesomeIcons.sun,
                  text: context.lang.settingsAppearance,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return AppearanceView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.comment,
                  text: context.lang.settingsChats,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return ChatSettingsView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.lock,
                  text: context.lang.settingsPrivacy,
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return PrivacyView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.bell,
                  text: context.lang.settingsNotification,
                  onTap: () async {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return NotificationView();
                    }));
                  },
                ),
                BetterListTile(
                  icon: FontAwesomeIcons.chartPie,
                  iconSize: 15,
                  text: context.lang.settingsStorageData,
                  onTap: () async {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return DataAndStorageView();
                    }));
                  },
                ),
                const Divider(),
                BetterListTile(
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
                BetterListTile(
                  icon: FontAwesomeIcons.shareFromSquare,
                  text: context.lang.inviteFriends,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return ShareWithFriendsView();
                      },
                    ));
                  },
                ),
              ],
            ),
    );
  }
}
