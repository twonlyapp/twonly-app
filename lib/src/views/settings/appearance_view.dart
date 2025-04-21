import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/views/components/radio_button.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';
import 'package:twonly/src/utils/misc.dart';

class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key});

  void _showSelectThemeMode(BuildContext context) async {
    ThemeMode? selectedValue = context.read<SettingsChangeProvider>().themeMode;

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
      context.read<SettingsChangeProvider>().updateThemeMode(selectedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeMode? selectedTheme =
        context.watch<SettingsChangeProvider>().themeMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsAppearance),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.settingsAppearanceTheme),
            subtitle:
                Text(selectedTheme.name, style: TextStyle(color: Colors.grey)),
            onTap: () {
              _showSelectThemeMode(context);
            },
          ),
        ],
      ),
    );
  }
}
