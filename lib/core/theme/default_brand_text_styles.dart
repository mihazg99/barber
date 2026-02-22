import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Default brand typography used on onboarding, notification request, and video portal screens.
/// Uses hardcoded fonts: Cormorant Garamond (serif) and Inter Tight (sans).
/// Once user locks a brand, the app switches to brand config fonts.
class DefaultBrandTextStyles {
  const DefaultBrandTextStyles._();

  static const String _serifFontFamily = 'Cormorant Garamond';
  static const String _sansFontFamily = 'Inter Tight';

  static TextStyle _serif({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) =>
      GoogleFonts.getFont(_serifFontFamily).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      );

  static TextStyle _sans({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.getFont(_sansFontFamily).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// Display Large: Serif 48px, -0.02em letter spacing
  static TextStyle get displayLarge =>
      _serif(fontSize: 48, letterSpacing: -0.02 * 48).copyWith(
        color: Colors.white,
      );

  /// Heading Medium: Serif 24px, -0.01em letter spacing
  static TextStyle get headingMedium =>
      _serif(fontSize: 24, letterSpacing: -0.01 * 24).copyWith(
        color: Colors.white,
      );

  /// Label Small: Sans 12px, 0.2em letter spacing
  static TextStyle get labelSmall =>
      _sans(fontSize: 12, letterSpacing: 0.2 * 12).copyWith(
        color: Colors.white,
      );

  /// Body Paragraph: Sans 14px, 1.5 line height
  static TextStyle get bodyParagraph =>
      _sans(fontSize: 14, height: 1.5).copyWith(
        color: Colors.white,
      );

  // --- Convenience methods for common use cases ---

  /// Body text: Sans 16px
  static TextStyle get body =>
      _sans(fontSize: 16).copyWith(color: Colors.white);

  /// Button text: Sans 16px, medium weight
  static TextStyle get button =>
      _sans(fontSize: 16, fontWeight: FontWeight.w500).copyWith(
        color: Colors.white,
      );

  /// Headline: Serif 24px, bold
  static TextStyle get headline =>
      _serif(fontSize: 24, fontWeight: FontWeight.bold).copyWith(
        color: Colors.white,
      );

  /// H2: Sans 14px, medium weight
  static TextStyle get h2 =>
      _sans(fontSize: 14, fontWeight: FontWeight.w500).copyWith(
        color: Colors.white,
      );
}
