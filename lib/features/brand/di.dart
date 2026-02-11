import 'package:barber/core/di.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/brand/data/repositories/brand_repository_impl.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return BrandRepositoryImpl(firestore);
});

/// Fetch a brand by its ID.
final brandByIdProvider = FutureProvider.autoDispose
    .family<Either<Failure, BrandEntity?>, String>((ref, brandId) async {
      final result = await ref.watch(brandRepositoryProvider).getById(brandId);
      return result;
    });

/// Locked brand ID for the current container (persisted in SharedPreferences).
/// This is the single source of truth for which brand is active in the app.
final lockedBrandIdProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  // Primary key for new builds.
  final locked = prefs.getString('locked_brand_id');
  if (locked != null && locked.isNotEmpty && locked != 'default') {
    return locked;
  }

  // Backwards compatibility: fall back to the old key if present.
  final legacySelected = prefs.getString('selected_brand_id');
  if (legacySelected != null &&
      legacySelected.isNotEmpty &&
      legacySelected != 'default') {
    return legacySelected;
  }

  // Single-tenant flavors: treat configured default brand as an implicit lock.
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  if (configBrandId.isNotEmpty && configBrandId != 'default') {
    return configBrandId;
  }

  return null;
});

/// Last loaded brand for the locked brand id.
/// Used as an in-memory cache to avoid redundant Firestore reads.
final lastLockedBrandProvider = StateProvider<BrandEntity?>((ref) => null);

/// Auto-save locked brand to SharedPreferences when changed and keep theme in sync.
final _lockedBrandPersistenceProvider = Provider<void>((ref) {
  // Persistence
  ref.listen(lockedBrandIdProvider, (prev, next) {
    final prefs = ref.read(sharedPreferencesProvider);

    if (next != null && next.isNotEmpty && next != prev) {
      prefs
        ..setString('locked_brand_id', next)
        ..remove('selected_brand_id'); // migrate away from legacy key
    } else if (next == null || next.isEmpty) {
      prefs
        ..remove('locked_brand_id')
        ..remove('selected_brand_id');
    }

    // When the locked brand id changes, clear the in-memory brand cache so
    // the next read fetches the correct brand.
    if (next != prev) {
      ref.read(lastLockedBrandProvider.notifier).state = null;
    }
  });

  // Theme Sync
  ref.listen<AsyncValue<BrandEntity?>>(defaultBrandProvider, (prev, next) {
    next.whenData((brand) {
      if (brand != null && brand.themeColors.isNotEmpty) {
        ref.read(themeOverrideProvider.notifier).state = brand.themeColors;
      } else {
        ref.read(themeOverrideProvider.notifier).state = null;
      }
    });
  });
});

/// Initialize persistence listener.
void initSelectedBrandPersistence(Ref ref) {
  // Keep the old name for backwards compatibility; under the hood this
  // initialises the locked brand persistence + theme sync.
  ref.read(_lockedBrandPersistenceProvider);
}

/// Default brand document. Single read shared by header and other consumers. Not autoDispose so one fetch is reused after login/navigation (avoids duplicate reads).
/// Logic:
/// 1. If flavor config has specific brand (single-tenant), use it.
/// 2. Else (multi-tenant/platform), use lockedBrandIdProvider.
final defaultBrandProvider = FutureProvider<BrandEntity?>((ref) async {
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;

  String? targetBrandId;

  if (configBrandId.isNotEmpty && configBrandId != 'default') {
    targetBrandId = configBrandId;
  } else {
    targetBrandId = ref.watch(lockedBrandIdProvider);
  }

  if (targetBrandId == null) return null;

  // Fast path: if we already have a cached brand for this id, reuse it.
  final cached = ref.read(lastLockedBrandProvider);
  if (cached != null && cached.brandId == targetBrandId) {
    return cached;
  }

  final result = await ref
      .watch(brandRepositoryProvider)
      .getById(targetBrandId);
  final brand = result.fold<BrandEntity?>((_) => null, (b) => b);

  // Cache the brand in memory so subsequent reads for the same id avoid
  // another Firestore get().
  if (brand != null) {
    ref.read(lastLockedBrandProvider.notifier).state = brand;
  }

  return brand;
});

/// Single source of brand logo URL for the app header. Uses [defaultBrandProvider].
final headerBrandLogoUrlProvider = FutureProvider<String?>((ref) async {
  final brand = await ref.watch(defaultBrandProvider.future);
  return brand?.logoUrl;
});

/// Brand name for loyalty card back and other UI. Uses [defaultBrandProvider].
final headerBrandNameProvider = FutureProvider<String?>((ref) async {
  final brand = await ref.watch(defaultBrandProvider.future);
  return brand?.name;
});
