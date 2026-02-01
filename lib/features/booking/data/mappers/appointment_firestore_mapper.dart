import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [AppointmentEntity].
/// When creating, set created_at with [FieldValue.serverTimestamp].
class AppointmentFirestoreMapper {
  static AppointmentEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final servicesRaw = data['service_ids'];
    final serviceIds = servicesRaw is List
        ? (servicesRaw).map((e) => e.toString()).toList()
        : <String>[];
    final start = data['start_time'] as Timestamp?;
    final end = data['end_time'] as Timestamp?;
    final created = data['created_at'] as Timestamp?;
    return AppointmentEntity(
      appointmentId: doc.id,
      brandId: data['brand_id'] as String? ?? '',
      locationId: data['location_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      barberId: data['barber_id'] as String? ?? '',
      serviceIds: serviceIds,
      startTime: start?.toDate() ?? DateTime.now(),
      endTime: end?.toDate() ?? DateTime.now(),
      totalPrice: (data['total_price'] as num?) ?? 0,
      status: data['status'] as String? ?? AppointmentStatus.scheduled,
      createdAt: created?.toDate(),
    );
  }

  static Map<String, dynamic> toFirestore(AppointmentEntity entity) => {
        'brand_id': entity.brandId,
        'location_id': entity.locationId,
        'user_id': entity.userId,
        'barber_id': entity.barberId,
        'service_ids': entity.serviceIds,
        'start_time': Timestamp.fromDate(entity.startTime),
        'end_time': Timestamp.fromDate(entity.endTime),
        'total_price': entity.totalPrice,
        'status': entity.status,
      };
}
