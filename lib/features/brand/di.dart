import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/default_brand_id.dart';
import 'package:barber/features/brand/data/repositories/brand_repository_impl.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return BrandRepositoryImpl(firestore);
});

/// Default brand document. Single read shared by header and other consumers. Not autoDispose so one fetch is reused after login/navigation (avoids duplicate reads).
final defaultBrandProvider = FutureProvider<BrandEntity?>((ref) async {
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final brandId =
      configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
  final result = await ref.watch(brandRepositoryProvider).getById(brandId);
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
