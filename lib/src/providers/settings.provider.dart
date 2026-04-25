import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';

class SettingsChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  void loadSettings() {
    if (userService.isUserCreated) {
      _themeMode = userService.currentUser.themeMode;
      notifyListeners();
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;

    notifyListeners();

    await UserService.update((u) => u.themeMode = newThemeMode);
  }
}
