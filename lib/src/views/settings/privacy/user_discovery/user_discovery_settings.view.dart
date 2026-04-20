import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/themes/light.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

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
    _minimumRequiredImagesExchanged = gUser.minimumRequiredImagesExchanged;
    _userDiscoveryThreshold = gUser.userDiscoveryThreshold;
    super.initState();
  }

  Future<void> _saveChanges() async {
    final requiresNewInitialization =
        gUser.userDiscoveryThreshold != _userDiscoveryThreshold;

    await updateUserdata((u) {
      u
        ..minimumRequiredImagesExchanged = _minimumRequiredImagesExchanged
        ..userDiscoveryThreshold = _userDiscoveryThreshold;
      return u;
    });

    if (requiresNewInitialization) {
      await UserDiscoveryService.initializeOrUpdate(
        threshold: gUser.userDiscoveryThreshold,
        minimumRequiredImagesExchanged: gUser.minimumRequiredImagesExchanged,
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
                    gUser.minimumRequiredImagesExchanged ||
                _userDiscoveryThreshold != gUser.userDiscoveryThreshold)
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
