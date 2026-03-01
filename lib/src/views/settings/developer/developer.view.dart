import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';

class DeveloperSettingsView extends StatefulWidget {
  const DeveloperSettingsView({super.key});

  @override
  State<DeveloperSettingsView> createState() => _DeveloperSettingsViewState();
}

class _DeveloperSettingsViewState extends State<DeveloperSettingsView> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> toggleDeveloperSettings() async {
    await updateUserdata((u) {
      u.isDeveloper = !u.isDeveloper;
      return u;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Show Developer Settings'),
            onTap: toggleDeveloperSettings,
            trailing: Switch(
              value: gUser.isDeveloper,
              onChanged: (a) => toggleDeveloperSettings(),
            ),
          ),
          ListTile(
            title: const Text('Show Retransmission Database'),
            onTap: () =>
                context.push(Routes.settingsDeveloperRetransmissionDatabase),
          ),
          ListTile(
            title: const Text('Delete all (!) app data'),
            onTap: () async {
              final ok = await showAlertDialog(
                context,
                'Sure?',
                'If you do not have a backup, you have to register with a new account.',
              );
              if (ok) {
                await deleteLocalUserData();
                await Restart.restartApp(
                  notificationTitle: 'Account successfully deleted',
                  notificationBody: 'Click here to open the app again',
                );
              }
            },
          ),
          if (!kReleaseMode)
            ListTile(
              title: const Text('Automated Testing'),
              onTap: () =>
                  context.push(Routes.settingsDeveloperAutomatedTesting),
            ),
        ],
      ),
    );
  }
}
