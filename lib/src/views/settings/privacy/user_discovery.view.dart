import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/settings/privacy/user_discovery/user_discovery_disabled.component.dart';
import 'package:twonly/src/views/settings/privacy/user_discovery/user_discovery_enabled.component.dart';

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
        stream: AppSession.onUserUpdated,
        builder: (context, _) {
          return AppSession.currentUser.isUserDiscoveryEnabled
              ? const UserDiscoveryEnabledComponent()
              : const UserDiscoveryDisabledComponent();
        },
      ),
    );
  }
}
