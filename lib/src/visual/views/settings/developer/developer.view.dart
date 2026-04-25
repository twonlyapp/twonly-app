import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/views/settings/developer/user_discovery_developer.view.dart';

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
    await UserService.update((u) => u.isDeveloper = !u.isDeveloper);
  }

  Future<void> toggleVideoStabilization() async {
    await UserService.update(
      (u) => u.videoStabilizationEnabled = !u.videoStabilizationEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Settings'),
      ),
      body: StreamBuilder<void>(
        stream: userService.onUserUpdated,
        builder: (context, _) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Show Developer Settings'),
                onTap: toggleDeveloperSettings,
                trailing: Switch(
                  value: userService.currentUser.isDeveloper,
                  onChanged: (_) => toggleDeveloperSettings(),
                ),
              ),
              ListTile(
                title: const Text('User ID'),
                subtitle: Text(userService.currentUser.userId.toString()),
              ),
              ListTile(
                title: const Text('Show Retransmission Database'),
                onTap: () => context.push(
                  Routes.settingsDeveloperRetransmissionDatabase,
                ),
              ),
              ListTile(
                title: const Text('Show User Discovery Database'),
                onTap: () =>
                    context.navPush(const UserDiscoveryDeveloperView()),
              ),
              ListTile(
                title: const Text('Toggle Video Stabilization'),
                onTap: toggleVideoStabilization,
                trailing: Switch(
                  value: userService.currentUser.videoStabilizationEnabled,
                  onChanged: (a) => toggleVideoStabilization(),
                ),
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
                      forceKill: true,
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Reduce flames'),
                onTap: () => context.push(Routes.settingsDeveloperReduceFlames),
              ),
              if (!kReleaseMode)
                ListTile(
                  title: const Text('Make it possible to reset flames'),
                  onTap: () async {
                    final chats = await twonlyDB.groupsDao.getAllDirectChats();

                    for (final chat in chats) {
                      await twonlyDB.groupsDao.updateGroup(
                        chat.groupId,
                        GroupsCompanion(
                          flameCounter: const Value(0),
                          maxFlameCounter: const Value(365),
                          lastFlameCounterChange: Value(clock.now()),
                          maxFlameCounterFrom: Value(
                            clock.now().subtract(const Duration(days: 1)),
                          ),
                        ),
                      );
                    }
                    await HapticFeedback.heavyImpact();
                  },
                ),
              if (!kReleaseMode)
                ListTile(
                  title: const Text('Automated Testing'),
                  onTap: () =>
                      context.push(Routes.settingsDeveloperAutomatedTesting),
                ),
            ],
          );
        },
      ),
    );
  }
}
