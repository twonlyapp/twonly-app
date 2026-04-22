import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';

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
    await updateUser((u) {
      u.screenLockEnabled = !u.screenLockEnabled;
    });
    setState(() {});
  }

  Future<void> toggleTypingIndicators() async {
    await updateUser((u) {
      u.typingIndicators = !u.typingIndicators;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsPrivacy),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.settingsPrivacyBlockUsers),
            subtitle: StreamBuilder(
              stream: twonlyDB.contactsDao.watchContactsBlocked(),
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
            title: Text(context.lang.contactVerifyNumberTitle),
            onTap: () async {
              await context.push(Routes.settingsPublicProfile);
              setState(() {});
            },
          ),
          ListTile(
            title: Text(context.lang.userDiscoverySettingsTitle),
            onTap: () async {
              await context.push(Routes.settingsPrivacyUserDiscovery);
              setState(() {});
            },
          ),
          const Divider(),
          ListTile(
            title: Text(context.lang.settingsTypingIndication),
            subtitle: Text(context.lang.settingsTypingIndicationSubtitle),
            onTap: toggleTypingIndicators,
            trailing: Switch(
              value: userService.currentUser.typingIndicators,
              onChanged: (a) => toggleTypingIndicators(),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(context.lang.settingsScreenLock),
            subtitle: Text(context.lang.settingsScreenLockSubtitle),
            onTap: toggleAuthRequirementOnStartup,
            trailing: Switch(
              value: userService.currentUser.screenLockEnabled,
              onChanged: (a) => toggleAuthRequirementOnStartup(),
            ),
          ),
        ],
      ),
    );
  }
}
