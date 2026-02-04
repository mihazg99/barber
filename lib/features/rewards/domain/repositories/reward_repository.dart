import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';

abstract class RewardRepository {
  /// Fetches rewards for a brand. When [includeInactive] is false (default),
  /// only active rewards are returned (e.g. for loyalty catalog).
  Future<Either<Failure, List<RewardEntity>>> getByBrandId(
    String brandId, {
    bool includeInactive = false,
  });

  /// Fetches a reward by id.
  Future<Either<Failure, RewardEntity?>> getById(String rewardId);

  /// Creates or overwrites a reward. doc_id = [entity.rewardId].
  Future<Either<Failure, void>> set(RewardEntity entity);

  /// Deletes a reward by id.
  Future<Either<Failure, void>> delete(String rewardId);
}
