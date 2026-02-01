import 'package:flutter/material.dart';
import 'package:inventory/core/theme/app_sizes.dart';

extension SafePaddingExtensions on BuildContext {
  double get safeTopPadding {
    final isIOS = Theme.of(this).platform == TargetPlatform.iOS;
    if (isIOS) {
      return MediaQuery.of(this).padding.top + appSizes.paddingMedium;
    } else {
      return appSizes.paddingXxl;
    }
  }
}