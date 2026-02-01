import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/core/di.dart';
import 'package:barber/core/router/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorConfigProvider);
    final title = flavor.values.brandConfig.appTitle;
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: title,
      routerConfig: router,
    );
  }
}