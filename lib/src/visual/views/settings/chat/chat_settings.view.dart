import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/pro_badge.element.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

class ChatSettingsView extends StatelessWidget {
  const ChatSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    // One size for every subtitle here, whatever tile carries it.
    final subtitleStyle = TextStyle(
      fontSize: 13,
      color: context.color.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: Text(lang.settingsChats)),
      body: StreamBuilder<void>(
        stream: userService.onUserUpdated,
        builder: (context, snapshot) {
          final user = userService.currentUser;
          return SettingsList(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              SettingsSectionTitle(lang.settingsChatsSectionChats),
              ListTile(
                title: Text(lang.settingsPreSelectedReactions),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.settingsChatsReactions),
              ),
              ListTile(
                title: Text(lang.contactGroupsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.settingsChatsContactGroups),
              ),
              ListTile(
                title: Row(
                  children: [
                    Flexible(child: Text(lang.settingsOnVacationTitle)),
                    const SizedBox(width: 8),
                    const ProBadge(),
                  ],
                ),
                subtitle: Text(
                  lang.settingsOnVacationSubtitle,
                  style: subtitleStyle,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.settingsChatsOnVacation),
              ),
              SwitchListTile.adaptive(
                title: Text(lang.alwaysShowStories),
                value: user.alwaysShowStories,
                onChanged: (value) => UserService.update(
                  (user) => user.alwaysShowStories = value,
                ),
              ),
              SwitchListTile.adaptive(
                title: Text(
                  lang.settingsAutomaticallyMarkEqualMediaFilesAsOpenedTitle,
                ),
                subtitle: Text(
                  lang.settingsAutomaticallyMarkEqualMediaFilesAsOpenedSubtitle,
                  style: subtitleStyle,
                ),
                value: user.automaticallyMarkEqualMediaFilesAsOpened,
                onChanged: (value) => UserService.update(
                  (user) =>
                      user.automaticallyMarkEqualMediaFilesAsOpened = value,
                ),
              ),
              const SettingsDivider(),
              SettingsSectionTitle(lang.settingsChatsSectionCamera),
              SwitchListTile.adaptive(
                title: Text(lang.startWithCameraOpen),
                value: user.startWithCameraOpen,
                onChanged: (value) => UserService.update(
                  (user) => user.startWithCameraOpen = value,
                ),
              ),
              SwitchListTile.adaptive(
                title: Text(lang.showImagePreviewWhenSending),
                value: user.showShowImagePreviewWhenSending,
                onChanged: (value) => UserService.update(
                  (user) => user.showShowImagePreviewWhenSending = value,
                ),
              ),
              const SettingsDivider(),
              SettingsSectionTitle(lang.settingsChatsSectionFlames),
              SwitchListTile.adaptive(
                title: Text(lang.settingsShowRestoreFlameTitle),
                value: user.showRestoreFlame,
                onChanged: (value) => UserService.update(
                  (user) => user.showRestoreFlame = value,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
