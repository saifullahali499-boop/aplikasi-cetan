import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Twitter Brand Colors
  static const Color primary = Color(0xFF1DA1F2);
  static const Color secondary = Color(0xFF14171A);
  
  // Light Theme Palette
  static const Color backgroundLight = Color(0xFFF7F9F9);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F1419);
  static const Color textSecondaryLight = Color(0xFF536471);
  static const Color borderLight = Color(0xFFEFF3F4);

  // Dark Theme Palette (Dim / Dark Blue)
  static const Color backgroundDark = Color(0xFF15202B);
  static const Color surfaceDark = Color(0xFF1E2732);
  static const Color textPrimaryDark = Color(0xFFF7F9F9);
  static const Color textSecondaryDark = Color(0xFF8E98A5);
  static const Color borderDark = Color(0xFF38444D);

  // General Status Colors
  static const Color error = Color(0xFFF4212E); // Twitter Red
  static const Color success = Color(0xFF00BA7C); // Twitter Green
  static const Color warning = Color(0xFFFFD400); // Twitter Yellow
  static const Color info = Color(0xFF1D9BF0);
}
