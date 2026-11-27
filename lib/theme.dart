import 'package:flutter/material.dart';

/// Questify palette, taken from the wireframes.
class AppColors {
  AppColors._();

  static const forest = Color(0xFF1F3D28);
  static const stone = Color(0xFFD7D2C8);
  static const background = Color(0xFFF5F2EB);
  static const card = Color(0xFFFFFEFA);
  static const border = Color(0xFF9B9890);
  static const muted = Color(0xFF6F736C);
  static const text = Color(0xFF17241B);
  static const error = Color(0xFFB3261E);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.forest).copyWith(
    primary: AppColors.forest,
    onPrimary: Colors.white,
    secondary: AppColors.stone,
    onSecondary: AppColors.text,
    surface: AppColors.background,
    error: AppColors.error,
  );

  OutlineInputBorder field(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.stone,
        foregroundColor: AppColors.forest,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.forest, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w800, letterSpacing: 0.6, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: field(AppColors.border),
      enabledBorder: field(AppColors.border),
      focusedBorder: field(AppColors.forest, 2),
      errorBorder: field(AppColors.error),
      focusedErrorBorder: field(AppColors.error, 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.muted),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.stone,
      labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: AppColors.text)),
    ),
  );
}
