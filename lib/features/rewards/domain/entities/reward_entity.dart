import 'package:equatable/equatable.dart';

/// A redeemable reward in the loyalty catalog (per brand).
/// doc_id: reward_id
class RewardEntity extends Equatable {
  const RewardEntity({
    required this.rewardId,
    required this.brandId,
    required this.name,
    required this.description,
    required this.pointsCost,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String rewardId;
  final String brandId;
  final String name;
  final String description;
  final int pointsCost;
  final int sortOrder;
  final bool isActive;

  @override
  List<Object?> get props => [
    rewardId,
    brandId,
    name,
    description,
    pointsCost,
    sortOrder,
    isActive,
  ];
}
