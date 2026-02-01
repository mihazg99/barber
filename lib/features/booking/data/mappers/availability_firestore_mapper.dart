import 'package:barber/features/booking/domain/entities/availability_entity.dart';
import 'package:barber/features/booking/domain/entities/booked_slot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [AvailabilityEntity].
class AvailabilityFirestoreMapper {
  static AvailabilityEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final raw = data['booked_slots'] as List<dynamic>?;
    final slots = <BookedSlot>[];
    if (raw != null) {
      for (final e in raw) {
        final slot = BookedSlot.fromMap(
          (e as Map<String, dynamic>?)?.cast<String, dynamic>(),
        );
        if (slot != null) slots.add(slot);
      }
    }
    return AvailabilityEntity(
      docId: doc.id,
      barberId: data['barber_id'] as String? ?? '',
      locationId: data['location_id'] as String? ?? '',
      date: data['date'] as String? ?? '',
      bookedSlots: slots,
    );
  }

  static Map<String, dynamic> toFirestore(AvailabilityEntity entity) => {
        'barber_id': entity.barberId,
        'location_id': entity.locationId,
        'date': entity.date,
        'booked_slots': entity.bookedSlots.map((s) => s.toMap()).toList(),
      };
}
