import 'package:flutter/material.dart';

final ThemeData darkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color(0xFF57CC99),
    surface: const Color.fromARGB(255, 20, 18, 23),
    surfaceContainer: const Color.fromARGB(255, 45, 41, 54),
    surfaceContainerLow: const Color.fromARGB(255, 38, 34, 45),
    surfaceContainerHigh: const Color.fromARGB(255, 52, 48, 62),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
);
