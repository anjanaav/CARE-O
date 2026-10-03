import 'package:flutter/material.dart';

/// Centralized text styles. Sizes lean larger than typical Material
/// defaults per the accessibility requirement (older-adult / low-vision
/// friendly), and every style accepts a color override so the same
/// TextTheme works for both light and dark surfaces.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 17, color: primary),
      bodyMedium: TextStyle(fontSize: 15, color: secondary),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }
}
