import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barber/core/errors/failure.dart';

/// Service to handle "Sentinel" versioned caching.
/// Checks if local version matches remote version from Brand.
/// If match -> Load from Prefs.
/// If miss -> Fetch from Firestore, Save to Prefs, Update Version.
class VersionedCacheService {
  VersionedCacheService(this._prefs);

  final SharedPreferences _prefs;

  /// Fetches a list of items using versioned caching strategy.
  ///
  /// [brandId] - The brand ID (namespace).
  /// [key] - The data key (e.g. 'barbers', 'services').
  /// [remoteVersion] - The current version from the Brand document.
  /// [fromJson] - Function to convert Map<String, dynamic> to Entity.
  /// [toJson] - Function to convert Entity to Map<String, dynamic>.
  /// [onFetch] - Callback to fetch fresh data from Firestore.
  Future<Either<Failure, List<T>>> fetchVersionedList<T>({
    required String brandId,
    required String key,
    required int remoteVersion,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required Future<Either<Failure, List<T>>> Function() onFetch,
  }) async {
    final stopwatch = Stopwatch()..start();
    final versionKey = '${brandId}_${key}_version';
    final dataKey = '${brandId}_${key}_data';

    final localVersion = _prefs.getInt(versionKey);

    // 1. Check Cache
    if (localVersion == remoteVersion) {
      final jsonString = _prefs.getString(dataKey);
      if (jsonString != null) {
        try {
          // Offload JSON parsing to isolate if possible, but for simple lists main thread is usually fine.
          // For very large lists, compute would be better.
          final List<dynamic> jsonList = jsonDecode(jsonString);
          final items =
              jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();

          stopwatch.stop();
          debugPrint(
            '[Sentinel] 🚀 CACHE HIT for $key (v$remoteVersion) | ${items.length} items | ${stopwatch.elapsedMilliseconds}ms',
          );
          return Right(items);
        } catch (e) {
          debugPrint('[Sentinel] ⚠️ Cache CORRUPTED for $key: $e');
          // Fallthrough to fetch
        }
      } else {
        debugPrint('[Sentinel] ℹ️ Cache MISS (No data) for $key');
      }
    } else {
      debugPrint(
        '[Sentinel] ℹ️ Cache MISS (Local: v${localVersion ?? "None"} != Remote: v$remoteVersion) for $key',
      );
    }

    // 2. Fetch Fresh Data
    debugPrint('[Sentinel] 🌍 Fetching fresh data for $key...');
    final fetchStopwatch = Stopwatch()..start();
    final result = await onFetch();
    fetchStopwatch.stop();

    return result.fold(
      (failure) {
        debugPrint(
          '[Sentinel] ❌ Fetch FAILED for $key: ${failure.message} | ${fetchStopwatch.elapsedMilliseconds}ms',
        );
        return Left(failure);
      },
      (items) async {
        // 3. Save to Cache (Fire and Forget)
        try {
          final jsonList = items.map((e) => toJson(e)).toList();
          final jsonString = jsonEncode(jsonList);

          await _prefs.setString(dataKey, jsonString);
          await _prefs.setInt(versionKey, remoteVersion);
          debugPrint(
            '[Sentinel] 💾 Cache SAVED for $key (v$remoteVersion) | ${items.length} items | Fetch: ${fetchStopwatch.elapsedMilliseconds}ms',
          );
        } catch (e) {
          debugPrint('[Sentinel] ⚠️ Cache SAVE FAILED for $key: $e');
        }
        return Right(items);
      },
    );
  }
}
