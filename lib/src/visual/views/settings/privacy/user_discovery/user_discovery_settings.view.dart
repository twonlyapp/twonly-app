import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/themes/light.dart';

class UserDiscoverySettingsView extends StatefulWidget {
  const UserDiscoverySettingsView({super.key});

  @override
  State<UserDiscoverySettingsView> createState() =>
      _UserDiscoverySettingsViewState();
}

class _UserDiscoverySettingsViewState extends State<UserDiscoverySettingsView> {
  int _minimumRequiredImagesExchanged = 0;
  int _userDiscoveryThreshold = 0;

  @override
  void initState() {
    super.initState();
    _minimumRequiredImagesExchanged =
        userService.currentUser.minimumRequiredImagesExchanged;
    _userDiscoveryThreshold = userService.currentUser.userDiscoveryThreshold;
  }

  Future<void> _saveChanges() async {
    final requiresNewInitialization =
        userService.currentUser.userDiscoveryThreshold !=
        _userDiscoveryThreshold;

    await UserService.update((u) {
      u
        ..minimumRequiredImagesExchanged = _minimumRequiredImagesExchanged
        ..userDiscoveryThreshold = _userDiscoveryThreshold;
    });

    if (requiresNewInitialization) {
      await UserDiscoveryService.initializeOrUpdate(
        threshold: userService.currentUser.userDiscoveryThreshold,
        minimumRequiredImagesExchanged:
            userService.currentUser.minimumRequiredImagesExchanged,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.userDiscoverySettingsTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ListView(
          children: [
            ListTile(
              title: Text(context.lang.userDiscoverySettingsMinImagesTitle),
              subtitle: Text(
                context.lang.userDiscoverySettingsMinImages,
              ),
              trailing: SizedBox(
                width: 60,
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: _minimumRequiredImagesExchanged,
                  ),
                  onSelectedItemChanged: (selectedItem) {
                    _minimumRequiredImagesExchanged = selectedItem;
                    setState(() {});
                  },
                  children: List.generate(
                    9,
                    (index) => Center(child: Text('$index')),
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text(context.lang.userDiscoverySettingsMutualFriendsTitle),
              subtitle: Text(
                context.lang.userDiscoverySettingsMutualFriends,
              ),
              trailing: SizedBox(
                width: 60,
                child: CupertinoPicker(
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  scrollController: FixedExtentScrollController(
                    initialItem: _userDiscoveryThreshold - 2,
                  ),
                  onSelectedItemChanged: (selectedItem) {
                    _userDiscoveryThreshold = selectedItem + 2;
                    setState(() {});
                  },
                  children: List.generate(
                    9,
                    (index) => Center(child: Text('${index + 2}')),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            if (_minimumRequiredImagesExchanged !=
                    userService.currentUser.minimumRequiredImagesExchanged ||
                _userDiscoveryThreshold !=
                    userService.currentUser.userDiscoveryThreshold)
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
          ],
        ),
      ),
    );
  }
}
