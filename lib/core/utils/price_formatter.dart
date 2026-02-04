import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';

/// Currency code to symbol. Extend as needed for more currencies.
const _currencySymbols = {
  'EUR': '€',
  'USD': '\$',
  'GBP': '£',
  'HRK': 'kn',
  'CHF': 'CHF',
};

/// Formats [price] using the configured currency from brand config.
String formatPrice(num price, String currencyCode) {
  final symbol = _currencySymbols[currencyCode] ?? currencyCode;
  if (price == price.toInt()) {
    return '$symbol${price.toInt()}';
  }
  return '$symbol${price.toStringAsFixed(2)}';
}

/// Extension to format prices using the app's configured currency.
extension PriceFormatterExtension on BuildContext {
  /// Formats [price] with the currency from flavor config (default EUR).
  String formatPriceWithCurrency(num price) {
    final config =
        ProviderScope.containerOf(
          this,
          listen: false,
        ).read(flavorConfigProvider).values.brandConfig;
    return formatPrice(price, config.currency);
  }
}
