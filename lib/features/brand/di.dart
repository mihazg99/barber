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

/// Currently selected brand ID (persisted in SharedPreferences).
final selectedBrandIdProvider = StateProvider<String?>((ref) {
  // Load from SharedPreferences on init
  final prefs = ref.watch(sharedPreferencesProvider);
  final val = prefs.getString('selected_brand_id');
  if (val == 'default') return null;
  return val;
});

/// Auto-save selected brand to SharedPreferences when changed.
final _selectedBrandPersistenceProvider = Provider<void>((ref) {
  // Persistence
  ref.listen(selectedBrandIdProvider, (prev, next) {
    if (next != null && next != prev) {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString('selected_brand_id', next);
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
  ref.read(_selectedBrandPersistenceProvider);
}

/// Default brand document. Single read shared by header and other consumers. Not autoDispose so one fetch is reused after login/navigation (avoids duplicate reads).
/// Logic:
/// 1. If flavor config has specific brand (single-tenant), use it.
/// 2. Else (multi-tenant/platform), use selectedBrandIdProvider.
final defaultBrandProvider = FutureProvider<BrandEntity?>((ref) async {
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;

  String? targetBrandId;

  if (configBrandId.isNotEmpty && configBrandId != 'default') {
    targetBrandId = configBrandId;
  } else {
    targetBrandId = ref.watch(selectedBrandIdProvider);
  }

  if (targetBrandId == null) return null;

  final result = await ref
      .watch(brandRepositoryProvider)
      .getById(targetBrandId);
  return result.fold((_) => null, (b) => b);
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
