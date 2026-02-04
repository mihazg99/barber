import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';
import 'package:barber/features/rewards/domain/repositories/reward_repository.dart';

class DashboardRewardsNotifier
    extends BaseNotifier<List<RewardEntity>, Failure> {
  DashboardRewardsNotifier(
    this._rewardRepository,
    this._defaultBrandId,
  );

  final RewardRepository _rewardRepository;
  final String _defaultBrandId;

  Future<void> load() async {
    if (_defaultBrandId.isEmpty) {
      setData([]);
      return;
    }
    await execute(
      () => _rewardRepository.getByBrandId(
        _defaultBrandId,
        includeInactive: true,
      ),
      (f) => f.message,
    );
  }

  Future<void> save(RewardEntity entity) async {
    setLoading();
    final result = await _rewardRepository.set(entity);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }

  Future<void> delete(String rewardId) async {
    setLoading();
    final result = await _rewardRepository.delete(rewardId);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }
}
