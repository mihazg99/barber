import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';
import 'package:barber/features/rewards/data/services/spend_points_transaction.dart';

/// Handles redeem-reward flow: spend points and create redemption.
/// On success state is [BaseData] with redemption id; page listens and invalidates + snackbar.
class LoyaltyNotifier extends BaseNotifier<String?, Failure> {
  LoyaltyNotifier(this._transaction);

  final SpendPointsTransaction _transaction;

  /// Runs spend-points transaction. Caller should ref.listen for BaseData/BaseError.
  Future<void> redeem(RewardEntity reward, UserEntity user) async {
    if (user.loyaltyPoints < reward.pointsCost) return;
    setLoading();
    final result = await _transaction.run(
      userId: user.userId,
      rewardId: reward.rewardId,
      rewardName: reward.name,
      brandId: reward.brandId,
      pointsCost: reward.pointsCost,
    );
    result.fold(
      (f) => setError(f.message, f),
      (redemptionId) => setData(redemptionId),
    );
  }
}
