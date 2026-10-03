import 'package:flutter/material.dart';

/// Centralized color palette. No screen should hardcode a `Color(...)`
/// value directly — everything reads from here (via [AppTheme]/[Theme.of])
/// so light/dark mode and future rebranding stay consistent.
class AppColors {
  AppColors._();

  // Light theme
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightSecondary = Color(0xFF14B8A6);
  static const Color lightAccent = Color(0xFF38BDF8);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark theme
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSecondarySurface = Color(0xFF1E293B);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkAccent = Color(0xFF2DD4BF);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Shared semantic colors (same in both themes for consistent meaning)
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
