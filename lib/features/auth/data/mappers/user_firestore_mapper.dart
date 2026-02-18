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
      dataVersions:
          (data['data_versions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          const {},
    );
  }

  /// Client-writable fields only.
  ///
  /// CRITICAL: Server-managed fields are EXCLUDED from this mapper and are
  /// BLOCKED by Firestore security rules. These fields can ONLY be written
  /// by Cloud Functions or Admin SDK:
  /// - lifetime_value (calculated from completed bookings)
  /// - last_booking_date (set when appointment completes)
  /// - next_visit_due (calculated based on average_visit_interval)
  /// - average_visit_interval (calculated from booking history)
  /// - reminded_this_cycle (marketing automation flag)
  ///
  /// If you add new server-managed fields, update firestore.rules to block them.
  static Map<String, dynamic> toFirestore(UserEntity entity) => {
    'full_name': entity.fullName,
    'phone': entity.phone,
    'fcm_token': entity.fcmToken,
    'barber_id': entity.barberId,
    'brand_id': entity.brandId,
    'data_versions': entity.dataVersions,
    _fieldRole: entity.role.value,
  };
}
