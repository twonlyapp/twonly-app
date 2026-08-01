import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/themes/light.dart';

class SettingsChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  late ThemeMode _themeMode;
  late Color _primaryColor;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  void loadSettings() {
    if (userService.isUserCreated) {
      _themeMode = userService.currentUser.themeMode;
      _primaryColor = userService.currentUser.primaryColor;
      notifyListeners();
    } else {
      _themeMode = ThemeMode.system;
      _primaryColor = defaultPrimaryColor;
    }
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;

    notifyListeners();

    await UserService.update((u) => u.themeMode = newThemeMode);
  }

  Future<void> updatePrimaryColor(Color newColor) async {
    if (newColor.toARGB32() == _primaryColor.toARGB32()) return;

    _primaryColor = newColor;

    notifyListeners();

    await UserService.update(
      (u) => u.primaryColorValue = newColor.toARGB32(),
    );
  }
}
