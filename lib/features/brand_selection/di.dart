import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand_selection/data/datasources/user_brands_remote_data_source.dart';
import 'package:barber/features/brand_selection/data/repositories/user_brands_repository_impl.dart';
import 'package:barber/features/brand_selection/domain/entities/user_brand_entity.dart';
import 'package:barber/features/brand_selection/domain/repositories/user_brands_repository.dart';

// ============================================================================
// Data Sources
// ============================================================================

final userBrandsRemoteDataSourceProvider = Provider<UserBrandsRemoteDataSource>(
  (ref) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    return UserBrandsRemoteDataSourceImpl(firestore);
  },
);

// ============================================================================
// Repositories
// ============================================================================

final userBrandsRepositoryProvider = Provider<UserBrandsRepository>((ref) {
  final remoteDataSource = ref.watch(userBrandsRemoteDataSourceProvider);
  return UserBrandsRepositoryImpl(remoteDataSource);
});

// ============================================================================
// Providers
// ============================================================================

/// Stream of user's joined brands.
final userBrandsProvider = StreamProvider.autoDispose<List<UserBrandEntity>>(
  (ref) {
    final userIdAsync = ref.watch(currentUserIdProvider);
    final userId = userIdAsync.valueOrNull;
    if (userId == null) {
      debugPrint('[UserBrandsProvider] Guest user, returning empty list');
      return Stream.value([]);
    }

    debugPrint('[UserBrandsProvider] Watching user brands for: $userId');
    final repository = ref.watch(userBrandsRepositoryProvider);
    return repository
        .watchUserBrands(userId)
        .map(
          (either) => either.fold(
            (_) => <UserBrandEntity>[],
            (brands) {
              debugPrint('[UserBrandsProvider] Loaded ${brands.length} brands');
              return brands;
            },
          ),
        );
  },
);

/// Guest brand IDs (from local storage). Returns empty list for authenticated users.
final guestBrandIdsProvider = Provider.autoDispose<List<String>>((ref) {
  final isGuest = ref.watch(isGuestProvider);
  if (!isGuest) return [];
  
  final guestStorage = ref.watch(guestStorageProvider);
  return guestStorage.getGuestBrands();
});

// Providers for brand selection UI/logic
