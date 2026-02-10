import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barber/features/brand_selection/domain/entities/user_brand_entity.dart';

class UserBrandModel extends UserBrandEntity {
  const UserBrandModel({
    required super.brandId,
    required super.loyaltyPoints,
    required super.joinedAt,
    required super.lastActive,
  });

  factory UserBrandModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBrandModel(
      brandId: data['brand_id'] as String? ?? '',
      loyaltyPoints: data['loyalty_points'] as int? ?? 0,
      joinedAt: (data['joined_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive:
          (data['last_active'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'brand_id': brandId,
    'loyalty_points': loyaltyPoints,
    'joined_at': Timestamp.fromDate(joinedAt),
    'last_active': Timestamp.fromDate(lastActive),
  };

  factory UserBrandModel.fromEntity(UserBrandEntity entity) => UserBrandModel(
    brandId: entity.brandId,
    loyaltyPoints: entity.loyaltyPoints,
    joinedAt: entity.joinedAt,
    lastActive: entity.lastActive,
  );
}
