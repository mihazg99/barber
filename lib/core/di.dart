import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/core/config/flavor_config.dart';
import 'package:inventory/core/data/database/app_database.dart';




///DATA

final flavorConfigProvider = Provider<FlavorConfig>((ref) {
  return FlavorConfig.instance;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});