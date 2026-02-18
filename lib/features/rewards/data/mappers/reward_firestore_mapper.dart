import 'package:barber/features/rewards/domain/entities/reward_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [RewardEntity].
class RewardFirestoreMapper {
  static RewardEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return fromMap(doc.data()!, doc.id);
  }

  static RewardEntity fromMap(Map<String, dynamic> data, String id) {
    return RewardEntity(
      rewardId: id,
      brandId: data['brand_id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      pointsCost: (data['points_cost'] as num?)?.toInt() ?? 0,
      sortOrder: (data['sort_order'] as num?)?.toInt() ?? 0,
      isActive: data['is_active'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> toFirestore(RewardEntity entity) => {
    'brand_id': entity.brandId,
    'name': entity.name,
    'description': entity.description,
    'points_cost': entity.pointsCost,
    'sort_order': entity.sortOrder,
    'is_active': entity.isActive,
  };
}
