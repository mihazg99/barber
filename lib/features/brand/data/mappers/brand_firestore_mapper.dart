import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [BrandEntity]. Keeps Firestore in data layer.
class BrandFirestoreMapper {
  static BrandEntity fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BrandEntity(
      brandId: doc.id,
      name: data['name'] as String? ?? '',
      isMultiLocation: data['is_multi_location'] as bool? ?? false,
      primaryColor: data['primary_color'] as String? ?? '#000000',
      logoUrl: data['logo_url'] as String? ?? '',
      contactEmail: data['contact_email'] as String? ?? '',
      slotInterval: (data['slot_interval'] as num?)?.toInt() ?? 30,
      bufferTime: (data['buffer_time'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, dynamic> toFirestore(BrandEntity entity) => {
        'name': entity.name,
        'is_multi_location': entity.isMultiLocation,
        'primary_color': entity.primaryColor,
        'logo_url': entity.logoUrl,
        'contact_email': entity.contactEmail,
        'slot_interval': entity.slotInterval,
        'buffer_time': entity.bufferTime,
      };
}
