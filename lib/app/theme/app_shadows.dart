import 'package:flutter/material.dart';

/// KaoSure Design System V1
/// Shadow Tokens
///
/// ใช้ AppShadows เท่านั้น
/// ห้ามสร้าง BoxShadow ใหม่ใน Widget

class AppShadows {
  AppShadows._();

  // ==========================================================================
  // None
  // ==========================================================================

  static const List<BoxShadow> none = [];

  // ==========================================================================
  // Small
  // ใช้กับ Card ทั่วไป
  // ==========================================================================

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  // ==========================================================================
  // Medium
  // ใช้กับ Elevated Card
  // ==========================================================================

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  // ==========================================================================
  // Large
  // ใช้กับ Dialog / BottomSheet / Floating Widget
  // ==========================================================================

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  // ==========================================================================
  // Extra Large
  // ใช้กับ Modal ขนาดใหญ่
  // ==========================================================================

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 32,
      spreadRadius: 0,
      offset: Offset(0, 12),
    ),
  ];

  // ==========================================================================
  // Primary Button Shadow
  // ==========================================================================

  static const List<BoxShadow> primary = [
    BoxShadow(
      color: Color(0x3358C84D),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 6),
    ),
  ];

  // ==========================================================================
  // Success
  // ==========================================================================

  static const List<BoxShadow> success = [
    BoxShadow(
      color: Color(0x3316A34A),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 6),
    ),
  ];

  // ==========================================================================
  // Error
  // ==========================================================================

  static const List<BoxShadow> error = [
    BoxShadow(
      color: Color(0x33DC2626),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 6),
    ),
  ];
}