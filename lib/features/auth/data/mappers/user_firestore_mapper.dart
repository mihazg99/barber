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
      role: UserRole.fromString(data[_fieldRole] as String?),
      lastBookingDate: (data['last_booking_date'] as Timestamp?)?.toDate(),
      nextVisitDue: (data['next_visit_due'] as Timestamp?)?.toDate(),
      averageVisitInterval:
          (data['average_visit_interval'] as num?)?.toInt() ?? 30,
      lifetimeValue: (data['lifetime_value'] as num?)?.toDouble() ?? 0.0,
      remindedThisCycle: data['reminded_this_cycle'] as bool? ?? false,
      preferredBarberId: data['preferred_barber_id'] as String? ?? '',
      barberId: data['barber_id'] as String? ?? '',
      brandId: data['brand_id'] as String? ?? '',
    );
  }

  /// Client-writable fields only. Marketing fields (last_booking_date,
  /// next_visit_due, lifetime_value, etc.) are server-managed by Cloud Functions
  /// and must not be overwritten by the client.
  static Map<String, dynamic> toFirestore(UserEntity entity) => {
    'full_name': entity.fullName,
    'phone': entity.phone,
    'fcm_token': entity.fcmToken,
    'barber_id': entity.barberId,
    'brand_id': entity.brandId,
    _fieldRole: entity.role.value,
  };
}
