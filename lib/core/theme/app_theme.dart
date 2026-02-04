import 'package:flutter/material.dart';

import 'package:barber/core/config/app_brand_config.dart';

/// Builds [ThemeData] from [AppBrandColors] so cursor, selection, and input
/// focus use config colors instead of default purple.
ThemeData appThemeFromBrandColors(AppBrandColors colors) {
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

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
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
    // Buttons and other interactive elements use primary for splash/overlay
    splashFactory: InkRipple.splashFactory,
    highlightColor: colors.primary.withValues(alpha: 0.12),
    splashColor: colors.primary.withValues(alpha: 0.12),
  );
}
