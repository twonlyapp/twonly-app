import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_setup.comp.dart';

class UserDiscoverySettingsView extends StatefulWidget {
  const UserDiscoverySettingsView({super.key});

  @override
  State<UserDiscoverySettingsView> createState() =>
      _UserDiscoverySettingsViewState();
}

class _UserDiscoverySettingsViewState extends State<UserDiscoverySettingsView> {
  late UserDiscoverySetupState state;

  @override
  void initState() {
    super.initState();
    final u = userService.currentUser;
    state = UserDiscoverySetupState(
      setState: setState,
      requiredSendImages: u.requiredSendImages,
      isUserDiscoveryEnabled: u.isUserDiscoveryEnabled,
      sharePromotion: u.userDiscoverySharePromotion,
      isManualApprovalEnabled: u.userDiscoveryRequiresManualApproval,
      threshold: u.userDiscoveryThreshold,
    );
  }

  Future<void> _saveChanges() async {
    await state.initializeOrUpdate();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            context.lang.avatarSaveChanges,
          ),
          actions: [
            FilledButton(
              child: Text(context.lang.avatarSaveChangesStore),
              onPressed: () async {
                await _saveChanges();
              },
            ),
            TextButton(
              child: Text(context.lang.avatarSaveChangesDiscard),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (state.wasChanged) {
          // there where changes
          final shouldPop = await _showBackDialog() ?? false;
          if (context.mounted && shouldPop) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.lang.userDiscoverySettingsTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 10, left: 24, right: 24),
          child: ListView(
            children: [
              const SizedBox(height: 30),
              UserDiscoverySetupComp(state: state),
              const SizedBox(height: 30),
              if (state.wasChanged)
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: FilledButton(
                    onPressed: _saveChanges,
                    style: primaryColorButtonStyle.merge(
                      FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                      ),
                    ),
                    child: Text(context.lang.userDiscoverySettingsApply),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
