import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/default_brand_id.dart';
import 'package:barber/features/brand/data/repositories/brand_repository_impl.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return BrandRepositoryImpl(firestore);
});

/// Single source of brand logo URL for the app header. Used by user home, barber
/// dashboard, and superadmin dashboard so all roles share the same header brand state.
final headerBrandLogoUrlProvider = FutureProvider.autoDispose<String?>((ref) async {
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final brandId =
      configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
  final result = await ref.watch(brandRepositoryProvider).getById(brandId);
  return result.fold((_) => null, (brand) => brand?.logoUrl);
});

/// Brand name for loyalty card back and other UI. Shares same brand resolution as header.
final headerBrandNameProvider = FutureProvider.autoDispose<String?>((ref) async {
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final brandId =
      configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
  final result = await ref.watch(brandRepositoryProvider).getById(brandId);
  return result.fold((_) => null, (brand) => brand?.name);
});
