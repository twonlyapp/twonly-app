import 'dart:io';

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/themes/colors.dart';
import 'package:twonly/src/visual/themes/light.dart';

Color _onPrimary(Color primary) {
  return ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF082117);
}

ColorScheme _darkColorScheme(Color primary) {
  return ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: primary,
    primary: primary,
  ).copyWith(
    onPrimary: _onPrimary(primary),
    surface: const Color(0xFF111412),
    onSurface: const Color(0xFFE2E4E1),
    onSurfaceVariant: const Color(0xFFBEC9C0),
    surfaceDim: const Color(0xFF111412),
    surfaceBright: const Color(0xFF373A37),
    surfaceContainerLowest: const Color(0xFF0B0E0C),
    surfaceContainerLow: const Color(0xFF171A18),
    surfaceContainer: const Color(0xFF1D211E),
    surfaceContainerHigh: const Color(0xFF282C29),
    surfaceContainerHighest: const Color(0xFF333734),
    outline: const Color(0xFF89938B),
    outlineVariant: const Color(0xFF404842),
    inverseSurface: const Color(0xFFE2E4E1),
    onInverseSurface: const Color(0xFF2E312F),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
  );
}

ThemeData getDarkTheme([Color primary = defaultPrimaryColor]) {
  final colorScheme = _darkColorScheme(primary);
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    extensions: const [AppColors.dark()],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: Platform.isAndroid ? 'sans-serif' : null,
      fontFamilyFallback: Platform.isAndroid ? const ['NotoColorEmoji'] : null,
    ),
  );
}

final ThemeData darkTheme = getDarkTheme();
