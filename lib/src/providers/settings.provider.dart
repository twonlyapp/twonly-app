import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

class SettingsChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadSettings() async {
    try {
      _themeMode = (await getUser())?.themeMode ?? ThemeMode.system;
      notifyListeners();
    } catch (e) {
      _themeMode = ThemeMode.system;
      Log.error(e);
    }
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;

    notifyListeners();

    await updateUser((u) => u.themeMode = newThemeMode);
  }
}
