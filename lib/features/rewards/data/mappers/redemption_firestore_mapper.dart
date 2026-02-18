import 'package:barber/features/rewards/domain/entities/redemption_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [RedemptionEntity].
class RedemptionFirestoreMapper {
  static RedemptionEntity fromMap(Map<String, dynamic> data, String id) {
    final created = data['created_at'];
    final redeemed = data['redeemed_at'];
    return RedemptionEntity(
      redemptionId: id,
      userId: data['user_id'] as String? ?? '',
      rewardId: data['reward_id'] as String? ?? '',
      brandId: data['brand_id'] as String? ?? '',
      rewardName: data['reward_name'] as String? ?? '',
      pointsSpent: (data['points_spent'] as num?)?.toInt() ?? 0,
      status: RedemptionStatus.fromString(data['status'] as String?),
      createdAt:
          (created is Timestamp)
              ? created.toDate()
              : (created is String
                  ? DateTime.tryParse(created) ?? DateTime.now()
                  : DateTime.now()),
      redeemedAt:
          (redeemed is Timestamp)
              ? redeemed.toDate()
              : (redeemed is String ? DateTime.tryParse(redeemed) : null),
      redeemedBy: data['redeemed_by'] as String?,
    );
  }

  static RedemptionEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return fromMap(doc.data()!, doc.id);
  }

  static Map<String, dynamic> toFirestore(RedemptionEntity entity) => {
    'user_id': entity.userId,
    'reward_id': entity.rewardId,
    'brand_id': entity.brandId,
    'reward_name': entity.rewardName,
    'points_spent': entity.pointsSpent,
    'status': entity.status.value,
    'created_at': entity.createdAt.toIso8601String(),
    if (entity.redeemedAt != null)
      'redeemed_at': entity.redeemedAt!.toIso8601String(),
    if (entity.redeemedBy != null) 'redeemed_by': entity.redeemedBy,
  };
}
