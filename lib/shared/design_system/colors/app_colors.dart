import 'package:flutter/material.dart';

/// KaoSure Design System V1
/// Centralized color palette
class AppColors {
  AppColors._();

  // ==========================================================================
  // Brand
  // ==========================================================================

  static const Color primary = Color(0xFF58C84D);
  static const Color primaryDark = Color(0xFF45B53A);
  static const Color primaryLight = Color(0xFF8BE27F);

  static const Color accent = Color(0xFFD62828);

  static const Color onPrimary = Colors.white;
  static const Color onAccent = Colors.white;

  // ==========================================================================
  // Status
  // ==========================================================================

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // ==========================================================================
  // Background
  // ==========================================================================

  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // ==========================================================================
  // Border / Divider
  // ==========================================================================

  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color outline = Color(0xFFCBD5E1);

  // ==========================================================================
  // Text
  // ==========================================================================

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textInverse = Colors.white;

  // ==========================================================================
  // States
  // ==========================================================================

  static const Color disabled = Color(0xFFE5E7EB);
  static const Color disabledForeground = Color(0xFF9CA3AF);

  // ==========================================================================
  // Common
  // ==========================================================================

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // ==========================================================================
  // Dark Theme (Reserved)
  // ==========================================================================

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);

  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);

  static const Color darkDivider = Color(0xFF374151);
}