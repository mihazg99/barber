import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barber/core/config/flavor_config.dart';
import 'package:barber/core/data/database/app_database.dart';

/// Root ScaffoldMessenger key for showing snackbars from anywhere (e.g. dashboard tabs).
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Notify to re-run router redirect. Placed in core so auth/di can trigger it when sign-in user is cached (avoids profile-setup redirect for returning users).
class RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerRefreshNotifierProvider =
    ChangeNotifierProvider<RouterRefreshNotifier>((ref) {
      return RouterRefreshNotifier();
    });

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
