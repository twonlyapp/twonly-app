import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/core/user_config.dart' as rust_config;
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/visual/themes/light.dart';

/// Languages the app can be shown in. The first one is used when the device
/// language is none of them.
const supportedLocales = [
  Locale('en'),
  Locale('de'),
  Locale('ar'),
];

class SettingsChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  late ThemeMode _themeMode;
  late Color _primaryColor;
  Locale? _locale;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  /// The language picked in the settings, or null to follow the device.
  Locale? get locale => _locale;

  void loadSettings() {
    if (userService.isUserCreated) {
      _themeMode = switch (userService.currentUser.themeMode) {
        rust_config.ThemeMode.system => ThemeMode.system,
        rust_config.ThemeMode.light => ThemeMode.light,
        rust_config.ThemeMode.dark => ThemeMode.dark,
      };
      final primaryColorValue = userService.currentUser.primaryColorValue;
      _primaryColor = primaryColorValue == null
          ? defaultPrimaryColor
          : Color(primaryColorValue);
      final language = userService.currentUser.language;
      _locale = supportedLocales
          .where((locale) => locale.languageCode == language)
          .firstOrNull;
      notifyListeners();
    } else {
      _themeMode = ThemeMode.system;
      _primaryColor = defaultPrimaryColor;
      _locale = null;
    }
  }

  Future<void> updateThemeMode(ThemeMode? newThemeMode) async {
    if (newThemeMode == null) return;

    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;

    notifyListeners();

    await UserService.update(
      (u) => u.themeMode = switch (newThemeMode) {
        ThemeMode.system => rust_config.ThemeMode.system,
        ThemeMode.light => rust_config.ThemeMode.light,
        ThemeMode.dark => rust_config.ThemeMode.dark,
      },
    );
  }

  Future<void> updatePrimaryColor(Color newColor) async {
    if (newColor.toARGB32() == _primaryColor.toARGB32()) return;

    _primaryColor = newColor;

    notifyListeners();

    await UserService.update(
      (u) => u.primaryColorValue = newColor.toARGB32(),
    );
  }

  Future<void> updateLocale(Locale? newLocale) async {
    if (newLocale == _locale) return;

    _locale = newLocale;

    notifyListeners();

    await UserService.update(
      (u) => u.language = newLocale?.languageCode,
    );
  }
}
