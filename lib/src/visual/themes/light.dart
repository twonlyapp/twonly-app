import 'dart:io';
import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

const defaultPrimaryColor = Color(0xFF57CC99);

ThemeData getLightTheme([Color primary = defaultPrimaryColor]) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
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
  foregroundColor: Colors.black87,
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
);

ButtonStyle secondaryGreyButtonStyle(BuildContext context) {
  return FilledButton.styleFrom(
    backgroundColor: isDarkMode(context) ? Colors.grey[800] : Colors.grey[200],
    foregroundColor: isDarkMode(context) ? Colors.white : Colors.black87,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
