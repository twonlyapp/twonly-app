import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/developer/automated_testing.view.dart';
import 'package:twonly/src/views/settings/developer/retransmission_data.view.dart';

class DeveloperSettingsView extends StatefulWidget {
  const DeveloperSettingsView({super.key});

  @override
  State<DeveloperSettingsView> createState() => _DeveloperSettingsViewState();
}

class _DeveloperSettingsViewState extends State<DeveloperSettingsView> {
  bool isDeveloper = true;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    final user = await getUser();
    if (user == null) return;
    setState(() {
      isDeveloper = user.isDeveloper;
    });
  }

  Future<void> toggleDeveloperSettings() async {
    await updateUserdata((u) {
      u.isDeveloper = !u.isDeveloper;
      return u;
    });
    await initAsync();
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
              value: isDeveloper,
              onChanged: (a) => toggleDeveloperSettings(),
            ),
          ),
          ListTile(
            title: const Text('Show Retransmission Database'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const RetransmissionDataView();
                  },
                ),
              );
            },
          ),
          if (kDebugMode)
            ListTile(
              title: const Text('FlameSync Test'),
              onTap: () async {
                await twonlyDB.contactsDao.modifyFlameCounterForTesting();
                await syncFlameCounters();
              },
            ),
          if (kDebugMode)
            ListTile(
              title: const Text('Automated Testing'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const AutomatedTestingView();
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
