import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/custom_color_picker_dialog.comp.dart';
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
                label: context.lang.themeSystemDefault,
                onChanged: (value) {
                  selectedValue = value;
                  Navigator.of(context).pop();
                },
              ),
              RadioButton<ThemeMode>(
                value: ThemeMode.light,
                groupValue: selectedValue,
                label: context.lang.themeLight,
                onChanged: (value) {
                  selectedValue = value;
                  Navigator.of(context).pop();
                },
              ),
              RadioButton<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: selectedValue,
                label: context.lang.themeDark,
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

  Future<void> _showSelectPrimaryColor(BuildContext context) async {
    const presetColors = <Color>[
      Color(0xFF57CC99), // Original Twonly Green
      Color(0xFF3A76F0), // Signal Blue
      Color(0xFF9D4EDD), // Purple
      Color(0xFFFF5964), // Coral Red
      Color(0xFFFF9F1C), // Amber Orange
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final activeColor =
            context.watch<SettingsChangeProvider>().primaryColor;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.lang.settingsAppearancePrimaryColor,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: presetColors.map((color) {
                  final isSelected =
                      activeColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () async {
                      await context
                          .read<SettingsChangeProvider>()
                          .updatePrimaryColor(color);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color:
                              isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Colors.red,
                        Colors.yellow,
                        Colors.green,
                        Colors.cyan,
                        Colors.blue,
                        Color(0xFFFF00FF),
                        Colors.red,
                      ],
                    ),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                ),
                title: Text(context.lang.customColor),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final pickedValue = await showDialog<int>(
                    context: context,
                    builder: (context) => CustomColorPickerDialog(
                      initialColor: activeColor,
                    ),
                  );
                  if (pickedValue != null && context.mounted) {
                    final pickedColor = Color(pickedValue);
                    await context
                        .read<SettingsChangeProvider>()
                        .updatePrimaryColor(pickedColor);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> toggleShowNewsIcon() async {
    await UserService.update((u) {
      u.showNewsShortcut = !u.showNewsShortcut;
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

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return context.lang.themeSystemDefault;
      case ThemeMode.light:
        return context.lang.themeLight;
      case ThemeMode.dark:
        return context.lang.themeDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = context.watch<SettingsChangeProvider>().themeMode;
    final primaryColor = context.watch<SettingsChangeProvider>().primaryColor;

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
                  _themeModeLabel(context, selectedTheme),
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () async {
                  await _showSelectThemeMode(context);
                },
              ),
              ListTile(
                title: Text(context.lang.settingsAppearancePrimaryColor),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
                onTap: () async {
                  await _showSelectPrimaryColor(context);
                },
              ),
              ListTile(
                title: Text(context.lang.hideNewsIcon),
                onTap: toggleShowNewsIcon,
                trailing: Switch.adaptive(
                  value: !userService.currentUser.showNewsShortcut,
                  onChanged: (a) => toggleShowNewsIcon(),
                ),
              ),
              ListTile(
                title: Text(context.lang.startWithCameraOpen),
                onTap: toggleStartWithCameraOpen,
                trailing: Switch.adaptive(
                  value: userService.currentUser.startWithCameraOpen,
                  onChanged: (a) => toggleStartWithCameraOpen(),
                ),
              ),
              ListTile(
                title: Text(context.lang.showImagePreviewWhenSending),
                onTap: toggleShowImagePreviewWhenSending,
                trailing: Switch.adaptive(
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
