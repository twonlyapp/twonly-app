import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/developer/automated_testing.view.dart';
import 'package:twonly/src/views/settings/developer/retransmission_data.view.dart';

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

  Future<void> toggleVideoCompression() async {
    await updateUserdata((u) {
      u.disableVideoCompression = !u.disableVideoCompression;
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
          ListTile(
            title: const Text('Disable ffmpeg'),
            subtitle: const Text(
              'If your smartphone crashes, you can disable ffmpeg. This will prevent your videos from being compressed and NO FILTER will be applied to the video! This is a workaround, until the root-cause in ffmpeg is found.',
            ),
            onTap: toggleVideoCompression,
            trailing: Switch(
              value: gUser.disableVideoCompression,
              onChanged: (a) => toggleVideoCompression(),
            ),
          ),
          if (!kReleaseMode)
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
