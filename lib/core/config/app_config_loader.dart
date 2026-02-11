import 'dart:convert';

import 'package:flutter/services.dart';

import 'app_brand_config.dart';

/// Loads whitelabel config from assets/config/{flavor}.json.
class AppConfigLoader {
  AppConfigLoader._();

  static const _configPathPrefix = 'assets/config/';
  static const _configPathSuffix = '.json';

  /// Loads brand config for the given flavor.
  /// Falls back to [default] config if flavor-specific file is missing.
  /// Loads brand config for the given flavor.
  /// Falls back to [default] config if flavor-specific file is missing.
  static Future<AppBrandConfig> load(String flavor) async {
    final path = '$_configPathPrefix$flavor$_configPathSuffix';
    try {
      print('AppConfigLoader: Loading config from $path');
      final json = await rootBundle.loadString(path);
      print('AppConfigLoader: Loaded JSON string length: ${json.length}');
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppBrandConfig.fromJson(map);
    } catch (e, stack) {
      print('AppConfigLoader: Failed to load config ($flavor): $e');
      if (flavor == 'default') {
        print(
          'AppConfigLoader: Critical error, failed to load default config. Rethrowing.',
        );
        rethrow;
      }
      print('AppConfigLoader: Falling back to default config');
      return load('default');
    }
  }
}
