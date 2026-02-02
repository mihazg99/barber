import 'package:flutter/material.dart';

/// Whitelabel branding config: logo, title, color scheme.
/// Loaded per flavor from assets/config/{flavor}.json.
@immutable
class AppBrandConfig {
  const AppBrandConfig({
    required this.appTitle,
    required this.logoPath,
    required this.defaultBrandId,
    required this.fontFamily,
    required this.colors,
  });

  final String appTitle;
  final String fontFamily;
  final String logoPath;
  final String defaultBrandId;
  final AppBrandColors colors;

  factory AppBrandConfig.fromJson(Map<String, dynamic> json) {
    final colorsJson = json['colors'] as Map<String, dynamic>? ?? {};
    return AppBrandConfig(
      appTitle: json['app_title'] as String? ?? 'Barber',
      logoPath: json['logo_path'] as String? ?? '',
      defaultBrandId: json['default_brand_id'] as String? ?? '',
      fontFamily: json['font_family'] as String? ?? 'Poppins',
      colors: AppBrandColors.fromJson(colorsJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'app_title': appTitle,
    'logo_path': logoPath,
    'default_brand_id': defaultBrandId,
    'font_family': fontFamily,
    'colors': colors.toJson(),
  };
}

@immutable
class AppBrandColors {
  const AppBrandColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.navigationBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.captionText,
    required this.primaryWhite,
    required this.hintText,
    required this.menuBackground,
    required this.border,
    required this.error,
  });

  final Color primary;
  final Color secondary;
  final Color background;
  final Color navigationBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color captionText;
  final Color primaryWhite;
  final Color hintText;
  final Color menuBackground;
  final Color border;
  final Color error;

  static Color _parseColor(dynamic value, Color fallback) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    if (s.isEmpty) return fallback;
    var hex = s.startsWith('#') ? s.substring(1) : s;
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return fallback;
  }

  factory AppBrandColors.fromJson(Map<String, dynamic> json) {
    return AppBrandColors(
      primary: _parseColor(json['primary'], _Defaults.primary),
      secondary: _parseColor(json['secondary'], _Defaults.secondary),
      background: _parseColor(json['background'], _Defaults.background),
      navigationBackground: _parseColor(
        json['navigation_background'],
        _Defaults.navigationBackground,
      ),
      primaryText: _parseColor(json['primary_text'], _Defaults.primaryText),
      secondaryText: _parseColor(
        json['secondary_text'],
        _Defaults.secondaryText,
      ),
      captionText: _parseColor(json['caption_text'], _Defaults.captionText),
      primaryWhite: _parseColor(json['primary_white'], _Defaults.primaryWhite),
      hintText: _parseColor(json['hint_text'], _Defaults.hintText),
      menuBackground: _parseColor(
        json['menu_background'],
        _Defaults.menuBackground,
      ),
      border: _parseColor(json['border'], _Defaults.border),
      error: _parseColor(json['error'], _Defaults.error),
    );
  }

  Map<String, dynamic> toJson() => {
    'primary':
        '#${primary.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'secondary':
        '#${secondary.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'background':
        '#${background.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'navigation_background':
        '#${navigationBackground.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'primary_text':
        '#${primaryText.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'secondary_text':
        '#${secondaryText.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'caption_text':
        '#${captionText.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'primary_white':
        '#${primaryWhite.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'hint_text':
        '#${hintText.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'menu_background':
        '#${menuBackground.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'border':
        '#${border.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'error':
        '#${error.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
  };
}

class _Defaults {
  static const primary = Color(0xFF6B63FF);
  static const secondary = Color(0xFF2A2F4A);
  static const background = Color(0xFF1E2235);
  static const navigationBackground = Color(0xFF1A1D2E);
  static const primaryText = Color(0xFFFFFFFF);
  static const secondaryText = Color(0xFFD1D5E0);
  static const captionText = Color(0xFF94A3B8);
  static const primaryWhite = Color(0xFFFFFFFF);
  static const hintText = Color(0xFFA6A9C8);
  static const menuBackground = Color(0xFF252A45);
  static const border = Color(0xFF393E5B);
  static const error = Color(0xFFB00020);
}
