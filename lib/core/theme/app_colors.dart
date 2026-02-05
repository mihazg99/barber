import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_brand_config.dart';
import '../di.dart';

/// Theme colors. Sourced from [AppBrandConfig] (whitelabel).
class AppColors {
  const AppColors._(this._colors);

  final AppBrandColors _colors;

  Color get primaryColor => _colors.primary;
  Color get secondaryColor => _colors.secondary;
  Color get backgroundColor => _colors.background;
  Color get navigationBackgroundColor => _colors.navigationBackground;
  Color get primaryTextColor => _colors.primaryText;
  Color get secondaryTextColor => _colors.secondaryText;
  Color get captionTextColor => _colors.captionText;
  Color get primaryWhiteColor => _colors.primaryWhite;
  Color get hintTextColor => _colors.hintText;
  Color get menuBackgroundColor => _colors.menuBackground;
  Color get borderColor => _colors.border;
  Color get errorColor => _colors.error;

  /// Brand primary lightened for use on dark backgrounds (e.g. cards). Keeps brand hue, improves readability.
  Color get primaryColorOnDark =>
      Color.lerp(_colors.primary, _colors.primaryWhite, 0.6)!;

  static AppColors fromBrandConfig(AppBrandConfig config) =>
      AppColors._(config.colors);
}

/// Provider for theme colors (from flavor brand config).
final appColorsProvider = Provider<AppColors>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  return AppColors.fromBrandConfig(flavor.values.brandConfig);
});

extension AppColorsExtension on BuildContext {
  AppColors get appColors {
    return ProviderScope.containerOf(
      this,
      listen: false,
    ).read(appColorsProvider);
  }
}
