import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber/core/config/app_brand_config.dart';
import 'package:barber/core/di.dart';

/// Text styles from [AppBrandConfig]. Tame brand book: Serif for display/headings,
/// Sans for body/labels. Uses Google Fonts.
class AppTextStyles {
  const AppTextStyles._(
    this._bodyFontFamily,
    this._colors, {
    String? displayFontFamily,
  }) : _displayFontFamily = displayFontFamily ?? _bodyFontFamily;

  final String _bodyFontFamily;
  final String _displayFontFamily;
  final AppBrandColors _colors;

  TextStyle _body({double? fontSize, FontWeight? fontWeight, double? height}) =>
      GoogleFonts.getFont(_bodyFontFamily).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
      );

  TextStyle _display({double? fontSize, FontWeight? fontWeight, double? letterSpacing}) =>
      GoogleFonts.getFont(_displayFontFamily).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      );

  // --- Tame brand book ---

  /// Display Large: Serif 48px, -0.02em
  TextStyle get displayLarge =>
      _display(fontSize: 48, letterSpacing: -0.02 * 48).copyWith(color: _colors.primaryText);

  /// Heading Medium: Serif 24px, -0.01em
  TextStyle get headingMedium =>
      _display(fontSize: 24, letterSpacing: -0.01 * 24).copyWith(color: _colors.primaryText);

  /// Label Small: Sans 12px, 0.2em
  TextStyle get labelSmall =>
      _body(fontSize: 12).copyWith(
        letterSpacing: 0.2 * 12,
        color: _colors.primaryText,
      );

  /// Body Paragraph: Sans 14px, 1.5 line height
  TextStyle get bodyParagraph =>
      _body(fontSize: 14, height: 1.5).copyWith(color: _colors.primaryText);

  // --- Legacy / semantic ---

  /// h1: 24pt, bold (display font)
  TextStyle get h1 =>
      _display(fontSize: 24, fontWeight: FontWeight.bold)
          .copyWith(color: _colors.primaryText);

  /// h2: 14pt, medium (body font)
  TextStyle get h2 =>
      _body(fontSize: 14, fontWeight: FontWeight.w500)
          .copyWith(color: _colors.primaryText);

  /// h3: 12pt, regular (body font)
  TextStyle get h3 =>
      _body(fontSize: 12, fontWeight: FontWeight.w400)
          .copyWith(color: _colors.primaryText);

  /// h4: 10pt, regular (body font)
  TextStyle get h4 =>
      _body(fontSize: 10, fontWeight: FontWeight.w400)
          .copyWith(color: _colors.primaryText);

  TextStyle get bold => _body(fontWeight: FontWeight.bold);
  TextStyle get medium => _body(fontWeight: FontWeight.w500);

  TextStyle get headline => h1;
  TextStyle get body => _body(fontSize: 16).copyWith(color: _colors.primaryText);
  TextStyle get button =>
      _body(fontSize: 16, fontWeight: FontWeight.w500)
          .copyWith(color: _colors.primaryWhite);
  TextStyle get caption =>
      _body(fontSize: 14, fontWeight: FontWeight.w400)
          .copyWith(color: _colors.primaryText);
  TextStyle get fields =>
      _body(fontSize: 14, fontWeight: FontWeight.w400)
          .copyWith(color: _colors.primaryText);

  static AppTextStyles fromBrandConfig(AppBrandConfig config) =>
      AppTextStyles._(
        config.fontFamily,
        config.colors,
        displayFontFamily: config.displayFontFamily,
      );
}

/// Provider for text styles (from flavor brand config).
final appTextStylesProvider = Provider<AppTextStyles>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  return AppTextStyles.fromBrandConfig(flavor.values.brandConfig);
});

extension AppTextStylesExtension on BuildContext {
  AppTextStyles get appTextStyles =>
      ProviderScope.containerOf(this, listen: false).read(appTextStylesProvider);
}
