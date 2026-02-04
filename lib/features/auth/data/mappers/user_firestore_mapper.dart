import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [UserEntity].
class UserFirestoreMapper {
  static const String _fieldRole = 'role';

  static UserEntity fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserEntity(
      userId: doc.id,
      fullName: data['full_name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      fcmToken: data['fcm_token'] as String? ?? '',
      brandId: data['brand_id'] as String? ?? '',
      loyaltyPoints: (data['loyalty_points'] as num?)?.toInt() ?? 0,
      role: UserRole.fromString(data[_fieldRole] as String?),
    );
  }

  static Map<String, dynamic> toFirestore(UserEntity entity) => {
        'full_name': entity.fullName,
        'phone': entity.phone,
        'fcm_token': entity.fcmToken,
        'brand_id': entity.brandId,
        'loyalty_points': entity.loyaltyPoints,
        _fieldRole: entity.role.value,
      };
}
