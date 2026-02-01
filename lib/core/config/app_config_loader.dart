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
  static Future<AppBrandConfig> load(String flavor) async {
    final path = '$_configPathPrefix$flavor$_configPathSuffix';
    try {
      final json = await rootBundle.loadString(path);
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppBrandConfig.fromJson(map);
    } catch (_) {
      return load('default');
    }
  }
}
