import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/radio_button.element.dart';

class AppearanceView extends StatefulWidget {
  const AppearanceView({super.key});

  @override
  State<AppearanceView> createState() => _AppearanceViewState();
}

class _AppearanceViewState extends State<AppearanceView> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _showSelectThemeMode(BuildContext context) async {
    ThemeMode? selectedValue = context.read<SettingsChangeProvider>().themeMode;

    // ignore: inference_failure_on_function_invocation
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.lang.settingsAppearanceTheme),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioButton<ThemeMode>(
                value: ThemeMode.system,
                groupValue: selectedValue,
                label: 'System default',
                onChanged: (value) {
                  selectedValue = value;
                  Navigator.of(context).pop();
                },
              ),
              RadioButton<ThemeMode>(
                value: ThemeMode.light,
                groupValue: selectedValue,
                label: 'Light',
                onChanged: (value) {
                  selectedValue = value;
                  Navigator.of(context).pop();
                },
              ),
              RadioButton<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: selectedValue,
                label: 'Dark',
                onChanged: (value) {
                  selectedValue = value;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
    if (selectedValue != null && context.mounted) {
      await context.read<SettingsChangeProvider>().updateThemeMode(
        selectedValue,
      );
    }
  }

  Future<void> toggleShowFeedbackIcon() async {
    await UserService.update((u) {
      u.showFeedbackShortcut = !u.showFeedbackShortcut;
    });
  }

  Future<void> toggleStartWithCameraOpen() async {
    await UserService.update((u) {
      u.startWithCameraOpen = !u.startWithCameraOpen;
    });
  }

  Future<void> toggleShowImagePreviewWhenSending() async {
    await UserService.update((u) {
      u.showShowImagePreviewWhenSending = !u.showShowImagePreviewWhenSending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = context.watch<SettingsChangeProvider>().themeMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsAppearance),
      ),
      body: StreamBuilder<void>(
        stream: userService.onUserUpdated,
        builder: (context, snapshot) {
          return ListView(
            children: [
              ListTile(
                title: Text(context.lang.settingsAppearanceTheme),
                subtitle: Text(
                  selectedTheme.name,
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () async {
                  await _showSelectThemeMode(context);
                },
              ),
              ListTile(
                title: Text(context.lang.contactUsShortcut),
                onTap: toggleShowFeedbackIcon,
                trailing: Switch(
                  value: !userService.currentUser.showFeedbackShortcut,
                  onChanged: (a) => toggleShowFeedbackIcon(),
                ),
              ),
              ListTile(
                title: Text(context.lang.startWithCameraOpen),
                onTap: toggleStartWithCameraOpen,
                trailing: Switch(
                  value: userService.currentUser.startWithCameraOpen,
                  onChanged: (a) => toggleStartWithCameraOpen(),
                ),
              ),
              ListTile(
                title: Text(context.lang.showImagePreviewWhenSending),
                onTap: toggleShowImagePreviewWhenSending,
                trailing: Switch(
                  value:
                      userService.currentUser.showShowImagePreviewWhenSending,
                  onChanged: (a) => toggleShowImagePreviewWhenSending(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
