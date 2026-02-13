import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color(0xFF57CC99),
    surface: const Color.fromARGB(255, 20, 18, 23),
    surfaceContainer: const Color.fromARGB(255, 33, 30, 39),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
);
