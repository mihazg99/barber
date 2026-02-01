import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inventory/core/theme/app_colors.dart';

class AppTextStyles {
  final TextStyle headline;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle body;
  final TextStyle button;
  final TextStyle caption;
  final TextStyle fields;

  const AppTextStyles({
    required this.headline,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.body,
    required this.button,
    required this.caption,
    required this.fields,
  });

  static AppTextStyles main(BuildContext context) => AppTextStyles(
    headline: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onBackground,
    ),
    body: TextStyle(
      fontSize: 16,
      color: Theme.of(context).colorScheme.onBackground,
    ),
    button: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: context.appColors.primaryWhiteColor,
    ),
    h2: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: context.appColors.primaryWhiteColor,
    ),
    h3: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: context.appColors.primaryWhiteColor,
    ),
    h4: GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: context.appColors.primaryWhiteColor,
    ),
    caption: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: context.appColors.primaryWhiteColor,
    ),
    fields: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: context.appColors.primaryWhiteColor,
    ),
  );
}

extension AppTextStylesExtension on BuildContext {
  AppTextStyles get appTextStyles => AppTextStyles.main(this);
}
