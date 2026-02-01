import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barber/core/config/app_brand_config.dart';
import 'package:barber/core/di.dart';

/// Text styles. Font family from [AppBrandConfig] (whitelabel).
/// Uses Google Fonts with configurable font.
class AppTextStyles {
  const AppTextStyles._(this._fontFamily, this._colors);

  final String _fontFamily;
  final AppBrandColors _colors;

  TextStyle _base({double? fontSize, FontWeight? fontWeight}) =>
      GoogleFonts.getFont(_fontFamily).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
      );

  /// h1: 24pt, bold
  TextStyle get h1 =>
      _base(fontSize: 24, fontWeight: FontWeight.bold)
          .copyWith(color: _colors.primaryText);

  /// h2: 14pt, medium
  TextStyle get h2 =>
      _base(fontSize: 14, fontWeight: FontWeight.w500)
          .copyWith(color: _colors.primaryText);

  /// h3: 12pt, regular
  TextStyle get h3 =>
      _base(fontSize: 12, fontWeight: FontWeight.w400)
          .copyWith(color: _colors.primaryText);

  /// h4: 10pt, regular
  TextStyle get h4 =>
      _base(fontSize: 10, fontWeight: FontWeight.w400)
          .copyWith(color: _colors.primaryText);

  /// Bold base style (use copyWith for size/color)
  TextStyle get bold => _base(fontWeight: FontWeight.bold);

  /// Medium base style (use copyWith for size/color)
  TextStyle get medium => _base(fontWeight: FontWeight.w500);

  // Backward compatibility
  TextStyle get headline => h1;
  TextStyle get body => _base(fontSize: 16).copyWith(color: _colors.primaryText);
  TextStyle get button =>
      _base(fontSize: 16, fontWeight: FontWeight.w500)
          .copyWith(color: _colors.primaryWhite);
  TextStyle get caption =>
      _base(fontSize: 14, fontWeight: FontWeight.w400)
          .copyWith(color: _colors.primaryText);
  TextStyle get fields =>
      _base(fontSize: 14, fontWeight: FontWeight.w400)
          .copyWith(color: _colors.primaryText);

  static AppTextStyles fromBrandConfig(AppBrandConfig config) =>
      AppTextStyles._(config.fontFamily, config.colors);
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
