import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFFF4081);
  static const background = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
  static const textPrimary = Colors.black87;
  static const accentColor = Color(0xFF1E88E5);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardTheme(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
    ),
  );
}
