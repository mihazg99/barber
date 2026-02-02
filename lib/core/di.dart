import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barber/core/config/flavor_config.dart';
import 'package:barber/core/data/database/app_database.dart';

/// DATA

final flavorConfigProvider = Provider<FlavorConfig>((ref) {
  return FlavorConfig.instance;
});

/// Override in main with [SharedPreferences.getInstance()].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences must be overridden in main');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});
