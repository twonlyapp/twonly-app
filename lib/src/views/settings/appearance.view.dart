import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/radio_button.dart';

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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.lang.settingsAppearanceTheme),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioButton<ThemeMode>(
                value: ThemeMode.system,
                groupValue: selectedValue,
                label: 'System default',
                onChanged: (ThemeMode? value) {
                  selectedValue = value;
                  Navigator.of(context).pop();
                },
              ),
              RadioButton<ThemeMode>(
                value: ThemeMode.light,
                groupValue: selectedValue,
                label: 'Light',
                onChanged: (ThemeMode? value) {
                  selectedValue = value;
                  Navigator.of(context).pop();
                },
              ),
              RadioButton<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: selectedValue,
                label: 'Dark',
                onChanged: (ThemeMode? value) {
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
      await context
          .read<SettingsChangeProvider>()
          .updateThemeMode(selectedValue);
    }
  }

  Future<void> toggleShowFeedbackIcon() async {
    await updateUserdata((u) {
      u.showFeedbackShortcut = !u.showFeedbackShortcut;
      return u;
    });
    setState(() {
      // gUser
    });
  }

  Future<void> toggleStartWithCameraOpen() async {
    await updateUserdata((u) {
      u.startWithCameraOpen = !u.startWithCameraOpen;
      return u;
    });
    setState(() {
      // gUser
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = context.watch<SettingsChangeProvider>().themeMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsAppearance),
      ),
      body: ListView(
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
              value: !gUser.showFeedbackShortcut,
              onChanged: (a) => toggleShowFeedbackIcon(),
            ),
          ),
          ListTile(
            title: Text(context.lang.startWithCameraOpen),
            onTap: toggleStartWithCameraOpen,
            trailing: Switch(
              value: gUser.startWithCameraOpen,
              onChanged: (a) => toggleStartWithCameraOpen(),
            ),
          ),
        ],
      ),
    );
  }
}
