import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/themes/colors.dart';

const defaultPrimaryColor = Color(0xFF32BE80);

Color _onPrimary(Color primary) {
  return ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF082117);
}

/// Material colors for the light theme. Twonly-specific light/dark pairs live
/// together in `colors.dart`.
ColorScheme _lightColorScheme(Color primary) {
  return ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
  ).copyWith(
    onPrimary: _onPrimary(primary),
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF191C1A),
    onSurfaceVariant: const Color(0xFF414943),
    surfaceDim: const Color(0xFFD9DCD9),
    surfaceBright: const Color(0xFFFFFFFF),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF5F7F5),
    surfaceContainer: const Color(0xFFEFF2EF),
    surfaceContainerHigh: const Color(0xFFE9ECE9),
    surfaceContainerHighest: const Color(0xFFE3E7E3),
    outline: const Color(0xFF717971),
    outlineVariant: const Color(0xFFC1C9C1),
    inverseSurface: const Color(0xFF2E312F),
    onInverseSurface: const Color(0xFFF0F2F0),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    error: const Color(0xFFBA1A1A),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
  );
}

ThemeData getLightTheme([Color primary = defaultPrimaryColor]) {
  final colorScheme = _lightColorScheme(primary);
  final base = ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    extensions: const [AppColors.light()],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: Platform.isAndroid ? 'sans-serif' : null,
      fontFamilyFallback: Platform.isAndroid ? const ['NotoColorEmoji'] : null,
    ),
  );
}

final ThemeData lightTheme = getLightTheme();

final ButtonStyle primaryColorButtonStyle = FilledButton.styleFrom(
  backgroundColor: defaultPrimaryColor,
  foregroundColor: const Color(0xFF082117),
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

ButtonStyle secondaryGreyButtonStyle(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: colors.surfaceContainerHigh,
    foregroundColor: colors.onSurface,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}
