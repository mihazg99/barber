import 'package:barber/core/di.dart';
import 'package:barber/features/rewards/data/repositories/reward_repository_impl.dart';
import 'package:barber/features/rewards/data/repositories/redemption_repository_impl.dart';
import 'package:barber/features/rewards/data/services/spend_points_transaction.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';
import 'package:barber/features/rewards/domain/entities/redemption_entity.dart';
import 'package:barber/features/rewards/domain/repositories/reward_repository.dart';
import 'package:barber/features/rewards/domain/repositories/redemption_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/auth/di.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cacheService = ref.watch(versionedCacheServiceProvider);
  return RewardRepositoryImpl(firestore, cacheService);
});

final redemptionRepositoryProvider = Provider<RedemptionRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cacheService = ref.watch(versionedCacheServiceProvider);
  return RedemptionRepositoryImpl(firestore, cacheService);
});

final spendPointsTransactionProvider = Provider<SpendPointsTransaction>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return SpendPointsTransaction(firestore);
});

/// Rewards catalog for the given brand (active only, sorted by sortOrder).
final rewardsForBrandProvider =
    FutureProvider.family<List<RewardEntity>, String>((ref, brandId) async {
      if (brandId.isEmpty) return [];

      final brandRepo = ref.watch(brandRepositoryProvider);
      final brandResult = await brandRepo.getById(brandId);
      final version = brandResult.fold(
        (_) => null,
        (b) => b?.dataVersions['rewards'],
      );

      final repo = ref.watch(rewardRepositoryProvider);
      final result = await repo.getByBrandId(brandId, version: version);
      return result.fold((_) => <RewardEntity>[], (list) => list);
    });

/// Pending and redeemed redemptions for a user (for "my rewards" and QR).
final redemptionsForUserProvider =
    FutureProvider.family<List<RedemptionEntity>, String>((ref, userId) async {
      if (userId.isEmpty) return [];

      final userAsync = ref.watch(currentUserProvider);
      final user = userAsync.valueOrNull;
      final version = user?.dataVersions['reward_redemptions'];

      final repo = ref.watch(redemptionRepositoryProvider);
      final result = await repo.getByUserId(userId, version: version);
      return result.fold((_) => <RedemptionEntity>[], (list) => list);
    });
