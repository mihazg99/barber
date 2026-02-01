import 'package:flutter/material.dart';
import 'package:inventory/core/config/flavor_values.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_environment.dart';
import 'core/config/flavor_config.dart';
import 'app.dart';

void main() {
  FlavorConfig(
    environment: AppEnvironment.prod,
    values: const FlavorValues(
      baseUrl: 'https://api.example.com',
    ),
  );
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

