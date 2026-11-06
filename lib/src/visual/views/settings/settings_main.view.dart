import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

class SettingsMainView extends StatelessWidget {
  const SettingsMainView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;

    void open(String location) => context.push<void>(location);

    Widget category(
      Object icon,
      String title,
      String route, {
      double iconSize = 20,
    }) {
      return BetterListTile(
        icon: icon,
        iconSize: iconSize,
        text: title,
        onTap: () => open(route),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(lang.settingsTitle)),
      body: SafeArea(
        top: false,
        child: StreamBuilder<void>(
          stream: userService.onUserUpdated,
          builder: (context, _) {
            final user = userService.currentUser;
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                InkWell(
                  onTap: () => open(Routes.settingsProfile),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Row(
                      children: [
                        const AvatarIcon(
                          myAvatar: true,
                          fontSize: 30,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                user.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                category(
                  FontAwesomeIcons.shieldHeart,
                  lang.settingsSubscription,
                  Routes.settingsSubscription,
                ),
                const SettingsDivider(),
                category(
                  FontAwesomeIcons.comment,
                  lang.settingsChats,
                  Routes.settingsChats,
                ),
                category(
                  FontAwesomeIcons.bell,
                  lang.settingsNotification,
                  Routes.settingsNotification,
                ),
                category(
                  FontAwesomeIcons.sun,
                  lang.settingsAppearance,
                  Routes.settingsAppearance,
                ),
                const SettingsDivider(),
                category(
                  FontAwesomeIcons.lock,
                  lang.settingsPrivacy,
                  Routes.settingsPrivacy,
                ),
                category(
                  Icons.lock_clock_rounded,
                  lang.settingsBackup,
                  Routes.settingsBackup,
                ),
                category(
                  FontAwesomeIcons.chartPie,
                  lang.settingsStorageData,
                  Routes.settingsStorage,
                  iconSize: 15,
                ),
                const SettingsDivider(),
                category(
                  FontAwesomeIcons.circleQuestion,
                  lang.settingsHelp,
                  Routes.settingsHelp,
                ),
                if (user.isDeveloper)
                  category(
                    FontAwesomeIcons.code,
                    'Developer Settings',
                    Routes.settingsDeveloper,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
