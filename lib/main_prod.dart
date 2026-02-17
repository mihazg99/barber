import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barber/core/config/app_config_loader.dart';
import 'package:barber/core/config/flavor_config.dart';
import 'package:barber/core/config/flavor_values.dart';
import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/firebase_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/config/app_environment.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await initializeDateFormatting('hr');
  await initializeDateFormatting('en');
  await initializeFirebase();

  final prefs = await SharedPreferences.getInstance();

  const flavor = 'default';
  final brandConfig = await AppConfigLoader.load(flavor);
  FlavorConfig(
    environment: AppEnvironment.prod,
    values: FlavorValues(
      baseUrl: 'https://api.example.com',
      brandConfig: brandConfig,
    ),
  );
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}
