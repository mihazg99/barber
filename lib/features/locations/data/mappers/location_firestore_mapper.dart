import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [LocationEntity].
class LocationFirestoreMapper {
  /// Normalize weekday key to 3-letter lowercase (mon, tue, ...) for lookup.
  static String _normalizeWeekdayKey(String key) {
    final k = key.toLowerCase().trim();
    if (k.length >= 3) return k.substring(0, 3);
    return k;
  }

  static LocationEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final geo = data['geo_point'] as GeoPoint?;
    final hoursRaw = data['working_hours'] as Map<String, dynamic>?;
    WorkingHoursMap hours = {};
    if (hoursRaw != null) {
      for (final e in hoursRaw.entries) {
        final dayKey = _normalizeWeekdayKey(e.key);
        hours[dayKey] = DayWorkingHours.fromMap(
          (e.value as Map<String, dynamic>?)?.cast<String, dynamic>(),
        );
      }
    }
    return LocationEntity(
      locationId: doc.id,
      brandId: data['brand_id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      latitude: geo?.latitude ?? 0.0,
      longitude: geo?.longitude ?? 0.0,
      phone: data['phone'] as String? ?? '',
      workingHours: hours,
    );
  }

  static Map<String, dynamic> toFirestore(LocationEntity entity) {
    final hours = <String, dynamic>{};
    for (final e in entity.workingHours.entries) {
      hours[e.key] = e.value?.toMap();
    }
    return {
      'brand_id': entity.brandId,
      'name': entity.name,
      'address': entity.address,
      'geo_point': GeoPoint(entity.latitude, entity.longitude),
      'phone': entity.phone,
      'working_hours': hours,
    };
  }
}
