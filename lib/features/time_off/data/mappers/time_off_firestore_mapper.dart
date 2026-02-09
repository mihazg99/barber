import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barber/features/time_off/domain/entities/time_off_entity.dart';

/// Mapper for converting between Firestore documents and TimeOffEntity.
abstract final class TimeOffFirestoreMapper {
  static TimeOffEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return TimeOffEntity(
      timeOffId: doc.id,
      barberId: data['barber_id'] as String,
      brandId: data['brand_id'] as String,
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      reason: data['reason'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> toFirestore(TimeOffEntity entity) {
    return {
      'barber_id': entity.barberId,
      'brand_id': entity.brandId,
      'start_date': Timestamp.fromDate(entity.startDate),
      'end_date': Timestamp.fromDate(entity.endDate),
      'reason': entity.reason,
      'created_at': Timestamp.fromDate(entity.createdAt),
    };
  }
}
