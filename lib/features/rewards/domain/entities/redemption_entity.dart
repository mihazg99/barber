import 'package:equatable/equatable.dart';

/// Status of a reward redemption (user bought with points; barber can mark fulfilled).
enum RedemptionStatus {
  /// User has claimed the reward; not yet scanned at barber.
  pending('pending'),

  /// Barber scanned QR and fulfilled the reward.
  redeemed('redeemed');

  const RedemptionStatus(this.value);
  final String value;

  static RedemptionStatus fromString(String? v) =>
      v == 'redeemed' ? RedemptionStatus.redeemed : RedemptionStatus.pending;
}

/// A user's reward redemption: they spent points to get this reward; doc id is used in QR for barber to scan.
class RedemptionEntity extends Equatable {
  const RedemptionEntity({
    required this.redemptionId,
    required this.userId,
    required this.rewardId,
    required this.brandId,
    required this.rewardName,
    required this.pointsSpent,
    required this.status,
    required this.createdAt,
    this.redeemedAt,
    this.redeemedBy,
  });

  final String redemptionId;
  final String userId;
  final String rewardId;
  final String brandId;
  final String rewardName;
  final int pointsSpent;
  final RedemptionStatus status;
  final DateTime createdAt;
  final DateTime? redeemedAt;
  final String? redeemedBy;

  bool get isPending => status == RedemptionStatus.pending;

  @override
  List<Object?> get props => [
    redemptionId,
    userId,
    rewardId,
    brandId,
    rewardName,
    pointsSpent,
    status,
    createdAt,
    redeemedAt,
    redeemedBy,
  ];
}
