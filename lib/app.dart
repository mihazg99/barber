import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/core/router/app_router.dart';

import 'core/di.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.read(flavorConfigProvider);

    return MaterialApp.router(
      title: 'MyApp ',
      routerConfig: appRouter,
    );
  }
}