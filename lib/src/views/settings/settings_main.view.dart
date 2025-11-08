import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/settings/account.view.dart';
import 'package:twonly/src/views/settings/appearance.view.dart';
import 'package:twonly/src/views/settings/backup/backup.view.dart';
import 'package:twonly/src/views/settings/chat/chat_settings.view.dart';
import 'package:twonly/src/views/settings/data_and_storage.view.dart';
import 'package:twonly/src/views/settings/developer/developer.view.dart';
import 'package:twonly/src/views/settings/help/help.view.dart';
import 'package:twonly/src/views/settings/notification.view.dart';
import 'package:twonly/src/views/settings/privacy.view.dart';
import 'package:twonly/src/views/settings/profile/profile.view.dart';
import 'package:twonly/src/views/settings/share_with_friends.view.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

class SettingsMainView extends StatefulWidget {
  const SettingsMainView({super.key});

  @override
  State<SettingsMainView> createState() => _SettingsMainViewState();
}

class _SettingsMainViewState extends State<SettingsMainView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsTitle),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(30),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const ProfileView();
                          },
                        ),
                      );
                      setState(() {});
                    },
                    child: ColoredBox(
                      color: context.color.surface.withAlpha(0),
                      child: Row(
                        children: [
                          const AvatarIcon(
                            myAvatar: true,
                            fontSize: 30,
                          ),
                          Container(width: 20, color: Colors.transparent),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                substringBy(gUser.displayName, 27),
                                style: const TextStyle(fontSize: 20),
                                textAlign: TextAlign.left,
                              ),
                              Text(
                                gUser.username,
                                style: const TextStyle(
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const AccountView();
                  },
                ),
              );
            },
          ),
          BetterListTile(
            icon: FontAwesomeIcons.shieldHeart,
            text: context.lang.settingsSubscription,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const SubscriptionView();
                  },
                ),
              );
            },
          ),
          BetterListTile(
            icon: Icons.lock_clock_rounded,
            text: context.lang.settingsBackup,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const BackupView();
                  },
                ),
              );
            },
          ),
          const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.sun,
            text: context.lang.settingsAppearance,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const AppearanceView();
                  },
                ),
              );
            },
          ),
          BetterListTile(
            icon: FontAwesomeIcons.comment,
            text: context.lang.settingsChats,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const ChatSettingsView();
                  },
                ),
              );
            },
          ),
          BetterListTile(
            icon: FontAwesomeIcons.lock,
            text: context.lang.settingsPrivacy,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const PrivacyView();
                  },
                ),
              );
            },
          ),
          BetterListTile(
            icon: FontAwesomeIcons.bell,
            text: context.lang.settingsNotification,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const NotificationView();
                  },
                ),
              );
            },
          ),
          BetterListTile(
            icon: FontAwesomeIcons.chartPie,
            iconSize: 15,
            text: context.lang.settingsStorageData,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const DataAndStorageView();
                  },
                ),
              );
            },
          ),
          const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.circleQuestion,
            text: context.lang.settingsHelp,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const HelpView();
                  },
                ),
              );
            },
          ),
          if (gUser.isDeveloper)
            BetterListTile(
              icon: FontAwesomeIcons.code,
              text: 'Developer Settings',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const DeveloperSettingsView();
                    },
                  ),
                );
              },
            ),
          BetterListTile(
            icon: FontAwesomeIcons.shareFromSquare,
            text: context.lang.inviteFriends,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const ShareWithFriendsView();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
