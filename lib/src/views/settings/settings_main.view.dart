import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/better_list_title.dart';

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
                      await context.push(Routes.settingsProfile);
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
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => context.push(Routes.settingsPublicProfile),
                    icon: const FaIcon(FontAwesomeIcons.qrcode),
                  ),
                ),
              ],
            ),
          ),
          BetterListTile(
            icon: FontAwesomeIcons.user,
            text: context.lang.settingsAccount,
            onTap: () => context.push(Routes.settingsAccount),
          ),
          BetterListTile(
            icon: FontAwesomeIcons.shieldHeart,
            text: context.lang.settingsSubscription,
            onTap: () => context.push(Routes.settingsSubscription),
          ),
          BetterListTile(
            icon: Icons.lock_clock_rounded,
            text: context.lang.settingsBackup,
            onTap: () => context.push(Routes.settingsBackup),
          ),
          const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.sun,
            text: context.lang.settingsAppearance,
            onTap: () => context.push(Routes.settingsAppearance),
          ),
          BetterListTile(
            icon: FontAwesomeIcons.comment,
            text: context.lang.settingsChats,
            onTap: () => context.push(Routes.settingsChats),
          ),
          BetterListTile(
            icon: FontAwesomeIcons.lock,
            text: context.lang.settingsPrivacy,
            onTap: () => context.push(Routes.settingsPrivacy),
          ),
          BetterListTile(
            icon: FontAwesomeIcons.bell,
            text: context.lang.settingsNotification,
            onTap: () => context.push(Routes.settingsNotification),
          ),
          BetterListTile(
            icon: FontAwesomeIcons.chartPie,
            iconSize: 15,
            text: context.lang.settingsStorageData,
            onTap: () => context.push(Routes.settingsStorage),
          ),
          const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.circleQuestion,
            text: context.lang.settingsHelp,
            onTap: () => context.push(Routes.settingsHelp),
          ),
          if (gUser.isDeveloper)
            BetterListTile(
              icon: FontAwesomeIcons.code,
              text: 'Developer Settings',
              onTap: () => context.push(Routes.settingsDeveloper),
            ),
          BetterListTile(
            icon: FontAwesomeIcons.shareFromSquare,
            text: context.lang.inviteFriends,
            onTap: () => context.push(Routes.settingsInvite),
          ),
        ],
      ),
    );
  }
}
