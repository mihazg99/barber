import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:barber/core/config/app_brand_config.dart';

/// Builds [ThemeData] from [AppBrandColors] (and optional [brandConfig] for
/// typography). Uses Tame brand book: Serif for display/headings, Sans for body/labels.
ThemeData appThemeFromBrandColors(
  AppBrandColors colors, {
  AppBrandConfig? brandConfig,
}) {
  final scheme = ColorScheme.dark(
    primary: colors.primary,
    onPrimary: colors.primaryWhite,
    secondary: colors.secondary,
    onSecondary: colors.primaryWhite,
    surface: colors.background,
    onSurface: colors.primaryText,
    error: colors.error,
    onError: colors.primaryWhite,
    outline: colors.border,
  );

  final bodyFont = brandConfig?.fontFamily ?? 'Source Sans 3';
  final displayFont = brandConfig?.displayFontFamily ?? brandConfig?.fontFamily ?? 'Source Serif 4';

  final textTheme = _buildTameTextTheme(
    displayFontFamily: displayFont,
    bodyFontFamily: bodyFont,
    color: colors.primaryText,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.primary,
      selectionColor: colors.primary.withValues(alpha: 0.3),
      selectionHandleColor: colors.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusColor: colors.primary,
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.border),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: colors.border),
      ),
    ),
    splashFactory: InkRipple.splashFactory,
    highlightColor: colors.primary.withValues(alpha: 0.12),
    splashColor: colors.primary.withValues(alpha: 0.12),
  );
}

/// Tame brand book typography: Serif for display/headings, Sans for body/labels.
/// - Display Large: Serif 48px, -0.02em
/// - Heading Medium: Serif 24px, -0.01em
/// - Label Small: Sans 12px, 0.2em
/// - Body: Sans 14px, 1.5 line height
TextTheme _buildTameTextTheme({
  required String displayFontFamily,
  required String bodyFontFamily,
  required Color color,
}) {
  final display = GoogleFonts.getFont(displayFontFamily);
  final body = GoogleFonts.getFont(bodyFontFamily);

  return TextTheme(
    displayLarge: display.copyWith(
      fontSize: 48,
      letterSpacing: -0.02 * 48,
      color: color,
    ),
    displayMedium: display.copyWith(
      fontSize: 36,
      letterSpacing: -0.02 * 36,
      color: color,
    ),
    displaySmall: display.copyWith(
      fontSize: 28,
      letterSpacing: -0.01 * 28,
      color: color,
    ),
    headlineLarge: display.copyWith(
      fontSize: 28,
      letterSpacing: -0.01 * 28,
      color: color,
    ),
    headlineMedium: display.copyWith(
      fontSize: 24,
      letterSpacing: -0.01 * 24,
      color: color,
    ),
    headlineSmall: display.copyWith(
      fontSize: 20,
      letterSpacing: -0.01 * 20,
      color: color,
    ),
    titleLarge: body.copyWith(fontSize: 16, color: color),
    titleMedium: body.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: color),
    titleSmall: body.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: color),
    bodyLarge: body.copyWith(
      fontSize: 16,
      height: 1.5,
      color: color,
    ),
    bodyMedium: body.copyWith(
      fontSize: 14,
      height: 1.5,
      color: color,
    ),
    bodySmall: body.copyWith(
      fontSize: 12,
      height: 1.5,
      color: color,
    ),
    labelLarge: body.copyWith(fontSize: 14, color: color),
    labelMedium: body.copyWith(fontSize: 12, color: color),
    labelSmall: body.copyWith(
      fontSize: 12,
      letterSpacing: 0.2 * 12,
      color: color,
    ),
  );
}
