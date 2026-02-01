import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [ServiceEntity].
class ServiceFirestoreMapper {
  static ServiceEntity fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final list = data['available_at_locations'];
    final locations = list is List
        ? (list).map((e) => e.toString()).toList()
        : <String>[];
    return ServiceEntity(
      serviceId: doc.id,
      brandId: data['brand_id'] as String? ?? '',
      availableAtLocations: locations,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?) ?? 0,
      durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? 0,
      description: data['description'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toFirestore(ServiceEntity entity) => {
        'brand_id': entity.brandId,
        'available_at_locations': entity.availableAtLocations,
        'name': entity.name,
        'price': entity.price,
        'duration_minutes': entity.durationMinutes,
        'description': entity.description,
      };
}
