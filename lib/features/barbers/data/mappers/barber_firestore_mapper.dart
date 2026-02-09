import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [BarberEntity].
class BarberFirestoreMapper {
  static String _normalizeWeekdayKey(String key) {
    final k = key.toLowerCase().trim();
    if (k.length >= 3) return k.substring(0, 3);
    return k;
  }

  static BarberEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final overrideRaw = data['working_hours_override'] as Map<String, dynamic>?;
    WorkingHoursMap? override;
    if (overrideRaw != null) {
      override = {};
      for (final e in overrideRaw.entries) {
        final dayKey = _normalizeWeekdayKey(e.key);
        override[dayKey] = DayWorkingHours.fromMap(
          (e.value as Map<String, dynamic>?)?.cast<String, dynamic>(),
        );
      }
    }
    return BarberEntity(
      barberId: doc.id,
      brandId: data['brand_id'] as String? ?? '',
      locationId: data['location_id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      photoUrl: data['photo_url'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      workingHoursOverride: override,
      userId: data['user_id'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(BarberEntity entity) {
    final map = <String, dynamic>{
      'brand_id': entity.brandId,
      'location_id': entity.locationId,
      'name': entity.name,
      'photo_url': entity.photoUrl,
      'active': entity.active,
    };
    if (entity.userId != null) {
      map['user_id'] = entity.userId;
    }

    if (entity.workingHoursOverride != null &&
        entity.workingHoursOverride!.isNotEmpty) {
      final hours = <String, dynamic>{};
      for (final e in entity.workingHoursOverride!.entries) {
        hours[e.key] = e.value?.toMap();
      }
      map['working_hours_override'] = hours;
    }

    return map;
  }
}
