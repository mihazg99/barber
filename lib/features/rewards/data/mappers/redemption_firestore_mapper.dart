import 'package:barber/features/rewards/domain/entities/redemption_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [RedemptionEntity].
class RedemptionFirestoreMapper {
  static RedemptionEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final created = data['created_at'];
    final redeemed = data['redeemed_at'];
    return RedemptionEntity(
      redemptionId: doc.id,
      userId: data['user_id'] as String? ?? '',
      rewardId: data['reward_id'] as String? ?? '',
      brandId: data['brand_id'] as String? ?? '',
      rewardName: data['reward_name'] as String? ?? '',
      pointsSpent: (data['points_spent'] as num?)?.toInt() ?? 0,
      status: RedemptionStatus.fromString(data['status'] as String?),
      createdAt: (created is Timestamp) ? created.toDate() : DateTime.now(),
      redeemedAt: redeemed is Timestamp ? redeemed.toDate() : null,
      redeemedBy: data['redeemed_by'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(RedemptionEntity entity) => {
    'user_id': entity.userId,
    'reward_id': entity.rewardId,
    'brand_id': entity.brandId,
    'reward_name': entity.rewardName,
    'points_spent': entity.pointsSpent,
    'status': entity.status.value,
    'created_at': entity.createdAt,
    if (entity.redeemedAt != null) 'redeemed_at': entity.redeemedAt,
    if (entity.redeemedBy != null) 'redeemed_by': entity.redeemedBy,
  };
}
