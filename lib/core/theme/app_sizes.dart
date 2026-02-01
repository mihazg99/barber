import 'package:flutter/material.dart';

class AppSizes {
  final double buttonHeightSmall;
  final double buttonHeightBig;
  final double paddingSmall;
  final double paddingMedium;
  final double paddingLarge;
  final double paddingXl;
  final double paddingXxl;
  final double paddingXxxl;
  final double borderRadius;

  const AppSizes({
    required this.buttonHeightSmall,
    required this.buttonHeightBig,
    required this.paddingSmall,
    required this.paddingMedium,
    required this.paddingLarge,
    required this.paddingXl,
    required this.paddingXxl,
    required this.paddingXxxl,
    required this.borderRadius,
  });

  static const AppSizes main = AppSizes(
    buttonHeightSmall: 36,
    buttonHeightBig: 56,
    paddingSmall: 8,
    paddingMedium: 16,
    paddingLarge: 24,
    paddingXl: 32,
    paddingXxl: 48,
    paddingXxxl: 64,
    borderRadius: 16,
  );
}

extension AppSizesExtension on BuildContext {
  AppSizes get appSizes => AppSizes.main;

  double get platformAwareTopPadding {
    final isIOS = Theme.of(this).platform == TargetPlatform.iOS;
    if (isIOS) {
      return MediaQuery.of(this).padding.top + appSizes.paddingMedium;
    } else {
      return appSizes.paddingMedium;
    }
  }
}
