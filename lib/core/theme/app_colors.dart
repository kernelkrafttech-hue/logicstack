import 'package:flutter/material.dart';

/// Brand palette for MaintenanceOS.
///
/// Navy is the primary surface for headers, key actions, and selected states.
/// Green is reserved for confirmation, success, and primary CTAs.
class AppColors {
  const AppColors._();

  // Brand
  static const Color navy = Color(0xFF0B2545);
  static const Color navyDark = Color(0xFF071834);
  static const Color navyMuted = Color(0xFF1B3A6B);

  // Accent
  static const Color green = Color(0xFF1FB57A);
  static const Color greenDark = Color(0xFF13935E);
  static const Color greenSoft = Color(0xFFE6F7EF);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFEEF1F5);
  static const Color border = Color(0xFFD9DFE7);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color bodyText = Color(0xFF1F2937);

  // Status
  static const Color error = Color(0xFFD64545);
  static const Color warning = Color(0xFFE5A100);
  static const Color info = Color(0xFF2D6CDF);
}
