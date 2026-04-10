import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

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
      gUser.screenLockEnabled
          ? context.lang.settingsScreenLockAuthMessageDisable
          : context.lang.settingsScreenLockAuthMessageEnable,
    );
    if (!isAuth) return;
    await updateUserdata((u) {
      u.screenLockEnabled = !u.screenLockEnabled;
      return u;
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
            title: Text(context.lang.settingsScreenLock),
            subtitle: Text(context.lang.settingsScreenLockSubtitle),
            onTap: toggleAuthRequirementOnStartup,
            trailing: Switch(
              value: gUser.screenLockEnabled,
              onChanged: (a) => toggleAuthRequirementOnStartup(),
            ),
          ),
          ListTile(
            title: Text(context.lang.contactVerifyNumberTitle),
            onTap: () async {
              await context.push(Routes.settingsPublicProfile);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
