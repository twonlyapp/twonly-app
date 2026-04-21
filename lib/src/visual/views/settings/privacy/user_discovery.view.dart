import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_disabled.comp.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_enabled.comp.dart';

class UserDiscoverySettingsView extends StatefulWidget {
  const UserDiscoverySettingsView({super.key});

  @override
  State<UserDiscoverySettingsView> createState() =>
      _UserDiscoverySettingsViewState();
}

class _UserDiscoverySettingsViewState extends State<UserDiscoverySettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freunde finden'),
      ),
      body: StreamBuilder<void>(
        stream: appSession.onUserUpdated,
        builder: (context, _) {
          return appSession.currentUser.isUserDiscoveryEnabled
              ? const UserDiscoveryEnabledComp()
              : const UserDiscoveryDisabledComp();
        },
      ),
    );
  }
}
