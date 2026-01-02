import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF00C4B4);
  static const primaryDark = Color(0xFF009688);
  static const primaryLight = Color(0xFFE0F7FA);
  static const warningDark = Color(0xFFF57C00);
  static const accent = Color(0xFFFF6B6B);

  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFFB74D);

  static const backgroundLight = Color(0xFFF8F9FA);
  static const surfaceLight = Colors.white;

  static const textPrimaryLight = Color(0xFF1D1D1D);
  static const textSecondaryLight = Color(0xFF757575);
  static const dividerLight = Color(0xFFE0E0E0);

  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);

  static const textPrimaryDark = Color(0xFFE0E0E0);
  static const textSecondaryDark = Color(0xFFB0B0B0);
  static const dividerDark = Color(0xFF2C2C2C);

  static Color contentColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }
}