import 'package:flutter/material.dart';

class AppTheme {
  // Questify brand colors
  static const Color forestGreen = Color(0xFF1F3D28);
  static const Color warmStone = Color(0xFFD7D2C8);
  static const Color cream = Color(0xFFF5F3EE);
  static const Color darkGreen = Color(0xFF14291A);
  static const Color mutedGreen = Color(0xFF627966);
  static const Color white = Colors.white;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: const ColorScheme.light(
      primary: forestGreen,
      secondary: mutedGreen,
      surface: cream,
      onPrimary: white,
      onSecondary: white,
      onSurface: darkGreen,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: forestGreen,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: forestGreen,
        foregroundColor: white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}