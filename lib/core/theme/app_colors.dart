import 'package:flutter/material.dart';

class AppColors {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color navigationBackgroundColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color captionTextColor;
  final Color primaryWhiteColor;
  final Color hintTextColor;
  final Color menuBackgroundColor;
  final Color borderColor;
  final Color errorColor;

  const AppColors({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.navigationBackgroundColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.captionTextColor,
    required this.primaryWhiteColor,
    required this.hintTextColor,
    required this.menuBackgroundColor,
    required this.borderColor,
    required this.errorColor,
  });

  static const AppColors main = AppColors(
    primaryColor: Color(0xFF6B63FF),
    secondaryColor: Color(0xFF2A2F4A),
    backgroundColor: Color(0xFF1E2235),
    navigationBackgroundColor: Color(0xFF1A1D2E),
    errorColor: Color(0xFFB00020),
    primaryTextColor: Color(0xFFFFFFFF),
    secondaryTextColor: Color(0xFFD1D5E0),
    captionTextColor: Color(0xFF94A3B8),
    menuBackgroundColor: Color(0xFF252A45),
    primaryWhiteColor: Color(0xFFFFFFFF),
    hintTextColor: Color(0xFFA6A9C8),
    borderColor: Color(0xFF393E5B),
  );
}

extension AppColorsExtension on BuildContext {
  AppColors get appColors => AppColors.main;
}
