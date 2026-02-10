import 'package:barber/gen/l10n/app_localizations.dart';
import 'package:barber/core/config/app_config_loader.dart';
import 'package:barber/core/config/app_environment.dart';
import 'package:barber/core/config/flavor_config.dart';
import 'package:barber/core/config/flavor_values.dart';
import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/firebase_app.dart';
import 'package:barber/features/onboarding/presentation/vendor_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('hr');
  await initializeDateFormatting('en');
  await initializeFirebase();

  final prefs = await SharedPreferences.getInstance();

  // For vendor onboarding, we might want a specific 'onboarding' flavor or just use default
  // and override specific configs. For now, we'll use 'default' but point to the onboarding page.
  const flavor = 'default';
  final brandConfig = await AppConfigLoader.load(flavor);

  FlavorConfig(
    environment:
        AppEnvironment
            .prod, // Or dev, depending on need. Using prod structure for now.
    values: FlavorValues(
      baseUrl: 'https://api.example.com', // Placeholder
      brandConfig: brandConfig,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const VendorOnboardingApp(),
    ),
  );
}

class VendorOnboardingApp extends StatelessWidget {
  const VendorOnboardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STYL Vendor Onboarding',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(
          0xFF0F172A,
        ), // Sapphire Indigo / Dark Mode base
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
        fontFamily: 'Instrument Sans', // Or project default
      ),
      home: const VendorOnboardingPage(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
