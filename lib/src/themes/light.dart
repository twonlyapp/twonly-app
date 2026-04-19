import 'package:flutter/material.dart';

final primaryColor = const Color(0xFF57CC99);

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
  // Adjusting the border radius (default is usually 20+)
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8), // Lower number = sharper corners
  ),
);

final ButtonStyle secondaryGreyButtonStyle = FilledButton.styleFrom(
  backgroundColor: Colors.grey[200],
  foregroundColor: Colors.black87,
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  // Adjusting the border radius (default is usually 20+)
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8), // Lower number = sharper corners
  ),
);
