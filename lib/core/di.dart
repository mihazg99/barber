import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barber/core/config/flavor_config.dart';
import 'package:barber/core/data/database/app_database.dart';
import 'package:barber/core/guest/guest_storage.dart';
import 'package:barber/core/services/video_preloader_service.dart';
import 'package:barber/core/data/services/versioned_cache_service.dart';

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

/// Guest ID and booking draft persistence. Uses [sharedPreferencesProvider].
final guestStorageProvider = Provider<GuestStorage>((ref) {
  return GuestStorage(ref.watch(sharedPreferencesProvider));
});

/// True when a guest saved a booking draft and should be sent to booking after sign-in.
final hasPendingBookingDraftProvider = Provider<bool>((ref) {
  final json = ref.watch(guestStorageProvider).getBookingDraftJson();
  return json != null && json.isNotEmpty;
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

/// Video preloader service for loading videos during splash screen.
/// Ensures seamless playback when navigating to video-based screens.
final videoPreloaderServiceProvider = Provider<VideoPreloaderService>((ref) {
  return VideoPreloaderService();
});

final versionedCacheServiceProvider = Provider<VersionedCacheService>((ref) {
  return VersionedCacheService(ref.watch(sharedPreferencesProvider));
});
