import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/services/user.service.dart';

class SettingsChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadSettings() async {
    _themeMode = (await getUser())?.themeMode ?? ThemeMode.system;
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;

    notifyListeners();

    await updateUser((u) => u.themeMode = newThemeMode);
  }
}
