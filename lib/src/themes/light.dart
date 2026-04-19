import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

const primaryColor = Color(0xFF57CC99);

final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
);

final ButtonStyle primaryColorButtonStyle = FilledButton.styleFrom(
  backgroundColor: primaryColor,
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
