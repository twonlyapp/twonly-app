import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

class PrivacyView extends StatefulWidget {
  const PrivacyView({super.key});

  @override
  State<PrivacyView> createState() => _PrivacyViewState();
}

class _PrivacyViewState extends State<PrivacyView> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> toggleAuthRequirementOnStartup() async {
    final isAuth = await authenticateUser(
      userService.currentUser.screenLockEnabled
          ? context.lang.settingsScreenLockAuthMessageDisable
          : context.lang.settingsScreenLockAuthMessageEnable,
    );
    if (!isAuth) return;
    await UserService.update((u) {
      u.screenLockEnabled = !u.screenLockEnabled;
    });
    setState(() {});
  }

  Future<void> toggleTypingIndicators() async {
    await UserService.update((u) {
      u.typingIndicators = !u.typingIndicators;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = TextStyle(
      fontSize: 13,
      color: context.color.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsPrivacy),
      ),
      body: SettingsList(
        children: [
          ListTile(
            title: Text(context.lang.publicProfilePrivacyTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.settingsPrivacyPublicProfile),
          ),
          ListTile(
            title: Text(context.lang.settingsPrivacyBlockUsers),
            trailing: const Icon(Icons.chevron_right),
            subtitle: StreamBuilder(
              stream: watchRustDatabase(
                (control) => rust_contacts.watchContactsCount(
                  metric: db_contacts.ContactCount.blocked,
                  control: control,
                ),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    context.lang.settingsPrivacyBlockUsersCount(snapshot.data!),
                  );
                } else {
                  return Text(
                    context.lang.settingsPrivacyBlockUsersCount(0),
                  );
                }
              },
            ),
            onTap: () => context.push(Routes.settingsPrivacyBlockUsers),
          ),
          ListTile(
            title: Text(context.lang.userDiscoverySettingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await context.push(Routes.settingsPrivacyUserDiscovery);
              setState(() {});
            },
          ),
          const SettingsDivider(),
          ListTile(
            title: Text(context.lang.settingsTypingIndication),
            subtitle: Text(
              context.lang.settingsTypingIndicationSubtitle,
              style: subtitleStyle,
            ),
            onTap: toggleTypingIndicators,
            trailing: Switch.adaptive(
              value: userService.currentUser.typingIndicators,
              onChanged: (a) => toggleTypingIndicators(),
            ),
          ),
          const SettingsDivider(),
          ListTile(
            title: Text(context.lang.settingsScreenLock),
            subtitle: Text(
              context.lang.settingsScreenLockSubtitle,
              style: subtitleStyle,
            ),
            onTap: toggleAuthRequirementOnStartup,
            trailing: Switch.adaptive(
              value: userService.currentUser.screenLockEnabled,
              onChanged: (a) => toggleAuthRequirementOnStartup(),
            ),
          ),
        ],
      ),
    );
  }
}
