import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/core/di.dart';
import 'package:barber/core/router/app_router.dart';
import 'package:barber/core/theme/app_theme.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/gen/l10n/app_localizations.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(upcomingAppointmentProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flavor = ref.watch(flavorConfigProvider);
    final brandConfig = flavor.values.brandConfig;
    final title = brandConfig.appTitle;
    final router = ref.watch(goRouterProvider);
    final theme = appThemeFromBrandColors(brandConfig.colors);

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: title,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      locale: const Locale('hr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
